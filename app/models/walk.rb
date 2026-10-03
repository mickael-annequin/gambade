class Walk < ApplicationRecord
  belongs_to :dog

  validates :started_at, presence: true
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0 }
  validates :distance_meters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :dogs_met_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

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

  # Accepts "2,3" (French keyboard) as well as "2.3".
  def distance_km=(km)
    self.distance_meters = km.present? ? (km.to_s.tr(",", ".").to_f * 1000).round : 0
  end
end
