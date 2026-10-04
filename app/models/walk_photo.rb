# A photo taken during a walk, imported afterwards from the phone gallery.
# Its position on the track is found from the time it was taken (see step 2).
class WalkPhoto < ApplicationRecord
  belongs_to :walk
  has_one_attached :image

  validate :image_is_a_photo

  private

  def image_is_a_photo
    if !image.attached?
      errors.add(:image, :blank)
    elsif !image.content_type.start_with?("image/")
      errors.add(:image, :not_an_image)
    elsif image.byte_size > 20.megabytes
      errors.add(:image, :too_big)
    end
  end
end
