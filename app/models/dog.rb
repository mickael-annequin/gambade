class Dog < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  has_many :walks, dependent: :destroy
  has_many :friends, dependent: :destroy
  has_many :cares, dependent: :delete_all

  # The last care of each kind that has a next one (vaccine, dewormer, flea): what to watch.
  def latest_cares
    Care::KINDS.filter_map { |kind, info| cares.where(kind: kind).latest_first.first if info[:every] }
  end

  validates :name, presence: true, length: { maximum: 50 }
  validates :breed, length: { maximum: 50 }
  validate :birth_date_not_in_future
  validate :photo_is_an_image

  # Age in full months (20 for 1 year and 8 months), computed from the birth date so it stays up to date.
  def age_in_months
    return if birth_date.nil?

    today = Date.current
    months = (today.year * 12 + today.month) - (birth_date.year * 12 + birth_date.month)
    months -= 1 if today < birth_date + months.months
    months
  end

  # Age in full years.
  def age
    age_in_months && age_in_months / 12
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
