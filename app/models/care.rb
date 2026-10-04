# A care given to my dog (vaccine, dewormer, flea treatment, vet visit), with the date of the next one.
class Care < ApplicationRecord
  belongs_to :dog

  # Label and how often it is given (nil: no next one, e.g. a vet visit).
  KINDS = {
    "vaccine" => { label: "💉 Vaccin", every: 1.year },
    "dewormer" => { label: "💊 Vermifuge", every: 3.months },
    "flea" => { label: "🐜 Anti-puces/tiques", every: 3.months },
    "vet" => { label: "🩺 Visite véto", every: nil }
  }.freeze

  validates :kind, inclusion: { in: KINDS.keys }
  validates :given_on, presence: true
  validates :product, length: { maximum: 100 }
  validates :note, length: { maximum: 2000 }
  validate :next_after_given

  # Left empty in the form: computed from the usual rhythm (in 3 months for a dewormer).
  before_validation :set_next_due_on

  scope :latest_first, -> { order(given_on: :desc, created_at: :desc) }

  def label
    KINDS.dig(kind, :label)
  end

  # Days until the next one (negative when late), or nil without a next one.
  def days_left
    (next_due_on - Date.current).to_i if next_due_on
  end

  private

  def set_next_due_on
    every = KINDS.dig(kind, :every)
    self.next_due_on ||= given_on + every if every && given_on
  end

  def next_after_given
    errors.add(:next_due_on, :before_given) if next_due_on && given_on && next_due_on <= given_on
  end
end
