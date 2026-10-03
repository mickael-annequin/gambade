class Walk < ApplicationRecord
  belongs_to :dog

  validates :started_at, presence: true
  validates :duration_seconds, presence: true, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :distance_meters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :dogs_met_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :distance_km_is_a_number

  scope :most_recent_first, -> { order(started_at: :desc) }

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
