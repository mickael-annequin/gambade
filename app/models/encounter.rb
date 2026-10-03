class Encounter < ApplicationRecord
  belongs_to :walk

  # How the meeting went (optional details, filled in after the walk).
  enum :mood, { joyful: "joyful", neutral: "neutral", tense: "tense" }, validate: { allow_nil: true }

  validates :met_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :dog_name, :breed, length: { maximum: 50 }

  scope :in_order, -> { order(:met_at) }
end
