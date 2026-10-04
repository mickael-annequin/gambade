# Photos of a walk, imported afterwards from the phone gallery (several at once).
class WalkPhotosController < ApplicationController
  before_action :require_dog

  MAX_PHOTOS_PER_SENDING = 10

  def create
    walk = current_dog.walks.find(params[:walk_id])
    images = Array(params.dig(:walk_photos, :images)).compact_blank
    return redirect_to walk_path(walk), alert: "Choisis au moins une photo." if images.empty?
    if images.size > MAX_PHOTOS_PER_SENDING
      return redirect_to walk_path(walk), alert: "#{MAX_PHOTOS_PER_SENDING} photos maximum à la fois."
    end

    photos = images.map { |image| walk.photos.new(image: image) }
    if photos.all?(&:valid?)
      photos.each(&:save!)
      redirect_to walk_path(walk, anchor: "photos"), notice: photos.size > 1 ? "#{photos.size} photos ajoutées." : "Photo ajoutée."
    else
      redirect_to walk_path(walk), alert: photos.flat_map { |photo| photo.errors.full_messages }.uniq.to_sentence
    end
  end
end
