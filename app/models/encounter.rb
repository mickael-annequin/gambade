class Encounter < ApplicationRecord
  belongs_to :walk
  belongs_to :friend, optional: true

  # How the meeting went (optional details, filled in after the walk).
  enum :mood, { playful: "playful", friendly: "friendly", neutral: "neutral", tense: "tense" }, validate: { allow_nil: true }

  validates :met_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :dog_name, :breed, length: { maximum: 50 }
  validate :friend_of_the_same_dog

  scope :in_order, -> { order(:met_at) }

  # The friend's name when the encounter is linked to the address book, else the name typed.
  def display_name
    friend&.name || dog_name
  end

  def display_breed
    friend&.breed.presence || breed
  end

  private

  # Protects against linking a friend of another account (e.g. a forged friend_id).
  def friend_of_the_same_dog
    errors.add(:friend, :invalid) if friend && friend.dog_id != walk&.dog_id
  end
end
