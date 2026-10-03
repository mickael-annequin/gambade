class Walk < ApplicationRecord
  belongs_to :dog
  has_many :track_points, dependent: :delete_all

  validates :started_at, presence: true
  validates :duration_seconds, presence: true, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :distance_meters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :dogs_met_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :distance_km_is_a_number

  scope :most_recent_first, -> { order(started_at: :desc) }

  EARTH_RADIUS_METERS = 6_371_000

  # Saves a walk recorded live on the phone, with all its GPS points, in one go.
  def self.create_from_track!(dog:, started_at:, ended_at:, points:)
    transaction do
      walk = dog.walks.create!(
        started_at: started_at,
        duration_seconds: [ (ended_at - started_at).round, 1 ].max,
        distance_meters: distance_along(points).round,
        tracked: true
      )
      if points.any?
        now = Time.current
        walk.track_points.insert_all!(points.map { |point| point.merge(created_at: now, updated_at: now) })
      end
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

  # [[longitude, latitude], ...] in time order, the format Mapbox expects.
  def track_coordinates
    track_points.in_order.pluck(:longitude, :latitude).map { |lng, lat| [ lng.to_f, lat.to_f ] }
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

  # Empty, "2" or "2.3" (the comma was already replaced by a dot).
  def distance_km_input_valid?
    @distance_km_input.nil? || @distance_km_input.match?(/\A(\d+(\.\d+)?)?\z/)
  end

  def distance_km_is_a_number
    errors.add(:distance_meters, :not_a_number) unless distance_km_input_valid?
  end
end
