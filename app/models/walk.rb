class Walk < ApplicationRecord
  belongs_to :dog
  has_many :track_points, dependent: :delete_all
  has_many :encounters, dependent: :destroy
  has_many :activities, dependent: :delete_all

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

  # Total length of the path going through the points, in meters.
  def self.distance_along(points)
    points.each_cons(2).sum { |from, to| distance_between(from, to) }
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
    points = track_points.sort_by(&:recorded_at)
    step = (points.size / max_points.to_f).ceil.clamp(1..)
    kept = points.each_slice(step).map(&:first)
    kept << points.last if points.any? && kept.last != points.last
    kept.map { |point| [ point.longitude.to_f, point.latitude.to_f ] }
  end

  # [[longitude, latitude], ...] in time order, the format Mapbox expects.
  def track_coordinates
    track_points.in_order.pluck(:longitude, :latitude).map { |lng, lat| [ lng.to_f, lat.to_f ] }
  end

  # Each GPS point with its time and the distance walked so far, for the "cut the end" slider.
  def track_progress
    meters = 0
    previous = nil
    track_points.in_order.map do |point|
      meters += self.class.distance_between(previous, point) if previous
      previous = point
      { at: point.recorded_at.iso8601, time: point.recorded_at.strftime("%Hh%M"),
        meters: meters.round, coordinates: [ point.longitude.to_f, point.latitude.to_f ] }
    end
  end

  # Removes everything recorded after ended_at (e.g. the drive home when "Terminer" was forgotten),
  # then recomputes the duration, the distance and the number of dogs met.
  def trim_end!(ended_at)
    transaction do
      track_points.where("recorded_at > ?", ended_at).delete_all
      encounters.where("met_at > ?", ended_at).destroy_all
      activities.where("started_at > ?", ended_at).delete_all
      activities.where("ended_at > ?", ended_at).update_all(ended_at: ended_at)
      points = track_points.in_order.map { |point| { latitude: point.latitude, longitude: point.longitude } }
      update!(
        duration_seconds: [ (ended_at - started_at).round, 1 ].max,
        distance_meters: self.class.distance_along(points).round,
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
