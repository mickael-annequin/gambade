# The weight of my dog on a given day.
class Weighing < ApplicationRecord
  belongs_to :dog

  validates :measured_on, presence: true
  validates :weight_kg, presence: true, numericality: { greater_than: 0, less_than: 150 }

  scope :in_order, -> { order(:measured_on, :created_at) }

  # "24,3" typed with a French comma is read as 24.3.
  def weight_kg=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end
end
