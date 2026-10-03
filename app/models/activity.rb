# A play (🎾) or swim (💦) phase during a walk. Phases are independent: both can happen at the same time.
class Activity < ApplicationRecord
  belongs_to :walk

  enum :kind, { play: "play", swim: "swim" }, validate: true

  validates :started_at, :ended_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :ends_after_start

  scope :in_order, -> { order(:started_at) }

  def duration_seconds
    (ended_at - started_at).round
  end

  private

  def ends_after_start
    errors.add(:ended_at, :before_start) if started_at && ended_at && ended_at < started_at
  end
end
