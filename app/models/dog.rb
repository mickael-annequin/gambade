class Dog < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  has_many :walks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :breed, length: { maximum: 50 }
  validate :birth_date_not_in_future
  validate :photo_is_an_image

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

  def photo_is_an_image
    return unless photo.attached?

    if !photo.content_type.start_with?("image/")
      errors.add(:photo, :not_an_image)
    elsif photo.byte_size > 10.megabytes
      errors.add(:photo, :too_big)
    end
  end
end
