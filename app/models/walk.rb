class Walk < ApplicationRecord
  belongs_to :dog
  has_many :track_points, dependent: :delete_all
  has_many :encounters, dependent: :destroy
  has_many :activities, dependent: :delete_all
  has_many :photos, class_name: "WalkPhoto", dependent: :destroy # destroy: also deletes the images on Cloudinary

  validates :started_at, presence: true
  validates :duration_seconds, presence: true, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :distance_meters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :dogs_met_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :distance_km_is_a_number
  validate :moods_are_known
  validates :comment, length: { maximum: 2000 }

  # How the dog was during the walk: several can be chosen.
  MOODS = {
    "energetic" => "⚡ Plein d'énergie",
    "happy" => "😊 Joyeux",
    "calm" => "😌 Calme",
    "tired" => "😴 Fatigué",
    "obedient" => "👍 Obéissant",
    "annoying" => "😤 Chiant"
  }.freeze

  # WMO weather codes (used by Open-Meteo) → what we show.
  WEATHERS = {
    [ 0 ] => "☀️ Ensoleillé",
    [ 1 ] => "🌤️ Plutôt ensoleillé",
    [ 2 ] => "⛅ Quelques nuages",
    [ 3 ] => "☁️ Couvert",
    [ 45, 48 ] => "🌫️ Brouillard",
    [ 51, 53, 55, 56, 57 ] => "🌦️ Bruine",
    [ 61, 63, 65, 66, 67 ] => "🌧️ Pluie",
    [ 80, 81, 82 ] => "🌧️ Averses",
    [ 71, 73, 75, 77, 85, 86 ] => "🌨️ Neige",
    [ 95, 96, 99 ] => "⛈️ Orage"
  }.freeze

  scope :most_recent_first, -> { order(started_at: :desc) }

  EARTH_RADIUS_METERS = 6_371_000

  # Saves a walk recorded live on the phone, with its GPS points, dogs met and play/swim phases, in one go.
  def self.create_from_track!(dog:, started_at:, ended_at:, points:, encounters: [], activities: [], client_id: nil)
    transaction do
      walk = dog.walks.create!(
        client_id: client_id,
        started_at: started_at,
        duration_seconds: [ (ended_at - started_at).round, 1 ].max,
        distance_meters: distance_along(points).round,
        dogs_met_count: encounters.size,
        tracked: true
      )
      if points.any?
        now = Time.current
        walk.track_points.insert_all!(points.map { |point| point.merge(created_at: now, updated_at: now) })
      end
      # A name typed during the walk that matches a friend ("Sid") links the encounter to that friend.
      encounters.each { |encounter| walk.encounters.create!(encounter.merge(friend: dog.friends.named(encounter[:dog_name]))) }
      activities.each { |activity| walk.activities.create!(activity) }
      walk
    end
  end

  SMOOTHING_SECONDS = 20

  # Total length of the path, in meters. Each GPS position is a few meters off, left or right:
  # going through every point zigzags and added ~15 % on a real walk. So the points are grouped
  # by slices of 20 seconds, and the path goes through the average position of each slice.
  def self.distance_along(points)
    time_slices(points).map { |slice| average_position(slice) }
                       .each_cons(2).sum { |from, to| distance_between(from, to) }
  end

  # Points (in time order, with recorded_at) → groups of the points recorded within 20 seconds.
  def self.time_slices(points)
    slices = []
    points.each do |point|
      new_slice = slices.empty? || point[:recorded_at].to_time - slices.last.first[:recorded_at].to_time >= SMOOTHING_SECONDS
      slices << [] if new_slice
      slices.last << point
    end
    slices
  end

  DISPLAY_SMOOTHING_SECONDS = 10

  # For the maps: each point replaced by the average of the points recorded 10 seconds before and after it.
  # The line follows the path instead of the GPS zigzag, and keeps its curves (all the points stay).
  def self.smoothed_positions(points)
    times = points.map { |point| point[:recorded_at].to_time }
    first = last = 0
    points.each_index.map do |index|
      first += 1 while times[index] - times[first] > DISPLAY_SMOOTHING_SECONDS
      last += 1 while last + 1 < points.size && times[last + 1] - times[index] <= DISPLAY_SMOOTHING_SECONDS
      average_position(points[first..last])
    end
  end

  def self.average_position(points)
    { latitude: points.sum { |point| point[:latitude].to_f } / points.size,
      longitude: points.sum { |point| point[:longitude].to_f } / points.size }
  end

  # Distance "as the crow flies" between two GPS points (haversine formula).
  def self.distance_between(from, to)
    lat1, lat2 = from[:latitude].to_f * Math::PI / 180, to[:latitude].to_f * Math::PI / 180
    delta_lat = lat2 - lat1
    delta_lng = (to[:longitude].to_f - from[:longitude].to_f) * Math::PI / 180
    a = Math.sin(delta_lat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(delta_lng / 2)**2
    2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(a))
  end

  # The track with at most max_points points (one in every n, plus the last one): same shape,
  # short enough to fit in the address of a map image. Uses the points already loaded by `includes`.
  def simplified_track(max_points: 80)
    positions = self.class.smoothed_positions(track_points.sort_by(&:recorded_at))
    step = (positions.size / max_points.to_f).ceil.clamp(1..)
    kept = positions.each_slice(step).map(&:first)
    kept << positions.last if positions.any? && kept.last != positions.last
    kept.map { |position| [ position[:longitude], position[:latitude] ] }
  end

  # [[longitude, latitude], ...] in time order, the format Mapbox expects.
  # Where we were at this time (to place a photo): the last point recorded before it, because no point
  # is recorded while standing still (e.g. while taking photos). nil outside the walk or without a track.
  def position_at(time)
    return if time.nil? || time < started_at - 1.minute || time > started_at + duration_seconds + 1.minute

    point = track_points.where(recorded_at: ..time).order(:recorded_at).last || track_points.order(:recorded_at).first
    { latitude: point.latitude, longitude: point.longitude } if point
  end

  # "☀️ Ensoleillé", or nil when the weather is not known.
  def weather_label
    WEATHERS.find { |codes, _label| codes.include?(weather_code) }&.last
  end

  # Needs a GPS track (to know where). In the middle of the walk.
  def fetch_weather!
    start = track_points.order(:recorded_at).first
    return if start.nil?

    report = WeatherReport.for(latitude: start.latitude, longitude: start.longitude,
                               time: started_at + (duration_seconds / 2).seconds)
    update!(report) if report
  end

  def track_coordinates
    self.class.smoothed_positions(track_points.in_order.to_a).map { |position| [ position[:longitude], position[:latitude] ] }
  end

  # Each GPS point with its time and the distance walked so far, for the "cut the end" slider.
  # Measured like distance_along: what the walk will measure if it is cut at this point.
  def track_progress
    meters_before = 0 # along the average positions of the previous slices
    previous_average = nil
    self.class.time_slices(track_points.in_order.to_a).flat_map do |slice|
      progress = slice.each_index.map do |index|
        meters = 0
        if previous_average
          meters = meters_before + self.class.distance_between(previous_average, self.class.average_position(slice.first(index + 1)))
        end
        point = slice[index]
        { at: point.recorded_at.iso8601, time: point.recorded_at.strftime("%Hh%M"),
          meters: meters.round, coordinates: [ point.longitude.to_f, point.latitude.to_f ] }
      end
      average = self.class.average_position(slice)
      meters_before += self.class.distance_between(previous_average, average) if previous_average
      previous_average = average
      progress
    end
  end

  # Walks are usually loops: the real end is probably where the track came back near the start.
  LEFT_START_METERS = 300 # farther than this, the walk had really left
  ARRIVAL_ZONE_METERS = 200
  BACK_TO_START_METERS = 50

  # For the "cut the end" slider: the indexes (in track_progress) of the last return near the start,
  # from the point entering the zone to the last one before leaving it again, and the probable end:
  # the first point really back at the start. nil when the walk never came back.
  def arrival_zone
    points = track_points.in_order.to_a
    from_start = points.map { |point| self.class.distance_between(points.first, point) }
    left_at = from_start.index { |meters| meters > LEFT_START_METERS }
    return if left_at.nil?

    entered_at = (left_at...points.size).select { |i| from_start[i] < ARRIVAL_ZONE_METERS }
                                       .select { |i| from_start[i - 1] >= ARRIVAL_ZONE_METERS }.last
    return if entered_at.nil?

    left_again_at = (entered_at...points.size).find { |i| from_start[i] >= ARRIVAL_ZONE_METERS }
    last = left_again_at ? left_again_at - 1 : points.size - 1
    suggested = (entered_at..last).find { |i| from_start[i] < BACK_TO_START_METERS } ||
                (entered_at..last).min_by { |i| from_start[i] }
    { from: entered_at, to: last, suggested: suggested }
  end

  # Length of the saved GPS track in meters, measured the current way.
  def track_distance
    points = track_points.in_order.map { |point| point.slice(:latitude, :longitude, :recorded_at).symbolize_keys }
    self.class.distance_along(points).round
  end

  # Removes everything recorded after ended_at (e.g. the drive home when "Terminer" was forgotten),
  # then recomputes the duration, the distance and the number of dogs met.
  def trim_end!(ended_at)
    transaction do
      track_points.where("recorded_at > ?", ended_at).delete_all
      encounters.where("met_at > ?", ended_at).destroy_all
      activities.where("started_at > ?", ended_at).delete_all
      activities.where("ended_at > ?", ended_at).update_all(ended_at: ended_at)
      update!(
        duration_seconds: [ (ended_at - started_at).round, 1 ].max,
        distance_meters: track_distance,
        dogs_met_count: encounters.count
      )
    end
  end

  # Map markers for the play (🎾) and swim (💦) phases, at the place where they started.
  def activity_markers
    activities.in_order.filter_map do |activity|
      next if activity.latitude.nil?

      { icon: activity.play? ? "🎾" : "💦",
        times: "#{activity.started_at.strftime('%Hh%M')}–#{activity.ended_at.strftime('%Hh%M')}",
        coordinates: [ activity.longitude.to_f, activity.latitude.to_f ] }
    end
  end

  ENCOUNTER_GROUP_METERS = 15

  # Map markers for the dogs met, numbered in time order (1, 2, 3…). Encounters closer than
  # a few meters share one marker (e.g. "1–3"), otherwise they would hide each other.
  def encounter_markers
    groups = []
    encounters.in_order.each.with_index(1) do |encounter, number|
      next if encounter.latitude.nil?

      point = { latitude: encounter.latitude, longitude: encounter.longitude }
      group = groups.find { |g| self.class.distance_between(g[:point], point) < ENCOUNTER_GROUP_METERS }
      group ||= (groups << { point: point, numbers: [], times: [] }).last
      group[:numbers] << number
      group[:times] << encounter.met_at.strftime("%Hh%M")
    end

    groups.map do |group|
      { label: numbers_label(group[:numbers]), times: group[:times],
        coordinates: [ group[:point][:longitude].to_f, group[:point][:latitude].to_f ] }
    end
  end

  # The form works in minutes and km; the database stores seconds and meters.
  def duration_minutes
    duration_seconds && duration_seconds / 60
  end

  def duration_minutes=(minutes)
    self.duration_seconds = minutes.present? ? (minutes.to_f * 60).round : nil
  end

  def distance_km
    distance_meters && distance_meters / 1000.0
  end

  # Accepts "2,3" (French keyboard) as well as "2.3". Anything else is kept to show an error.
  def distance_km=(km)
    @distance_km_input = km.to_s.strip.tr(",", ".")
    self.distance_meters = (@distance_km_input.to_f * 1000).round if distance_km_input_valid?
  end

  private

  # [1] -> "1", [1, 2, 3] -> "1–3", [2, 5] -> "2, 5"
  def numbers_label(numbers)
    return numbers.first.to_s if numbers.one?
    return "#{numbers.first}–#{numbers.last}" if numbers.each_cons(2).all? { |a, b| b == a + 1 }

    numbers.join(", ")
  end

  # Empty, "2" or "2.3" (the comma was already replaced by a dot).
  def distance_km_input_valid?
    @distance_km_input.nil? || @distance_km_input.match?(/\A(\d+(\.\d+)?)?\z/)
  end

  def moods_are_known
    errors.add(:moods, :inclusion) unless (moods - MOODS.keys).empty?
  end

  def distance_km_is_a_number
    errors.add(:distance_meters, :not_a_number) unless distance_km_input_valid?
  end
end
