class TrackPoint < ApplicationRecord
  belongs_to :walk

  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :recorded_at, presence: true

  scope :in_order, -> { order(:recorded_at) }
end
