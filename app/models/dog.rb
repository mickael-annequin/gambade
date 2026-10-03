class Dog < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :breed, length: { maximum: 50 }
  validate :birth_date_not_in_future

  # Age in full years, computed from the birth date so it stays up to date.
  def age
    return if birth_date.nil?

    today = Date.current
    years = today.year - birth_date.year
    years -= 1 if today < birth_date + years.years
    years
  end

  private

  def birth_date_not_in_future
    if birth_date.present? && birth_date > Date.current
      errors.add(:birth_date, :in_future)
    end
  end
end
