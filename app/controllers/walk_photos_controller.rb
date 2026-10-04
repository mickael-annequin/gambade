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

    # Time each photo was taken (read on the phone, same order as the photos) → its place on the track.
    taken_ats = Array(params.dig(:walk_photos, :taken_ats))
    photos = images.each_with_index.map do |image, index|
      taken_at = parse_time(taken_ats[index])
      walk.photos.new(image: image, taken_at: taken_at, **walk.position_at(taken_at).to_h)
    end
    if photos.all?(&:valid?)
      photos.each(&:save!)
      redirect_to walk_path(walk, anchor: "photos"), notice: photos.size > 1 ? "#{photos.size} photos ajoutées." : "Photo ajoutée."
    else
      redirect_to walk_path(walk), alert: photos.flat_map { |photo| photo.errors.full_messages }.uniq.to_sentence
    end
  end

  private

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
