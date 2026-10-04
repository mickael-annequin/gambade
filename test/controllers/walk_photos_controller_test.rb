require "test_helper"

class WalkPhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "adds several photos at once to a walk" do
    images = [ fixture_file_upload("dog.png", "image/png"), fixture_file_upload("dog.png", "image/png") ]
    assert_difference "walks(:evening).photos.count", 2 do
      post walk_photos_path(walks(:evening)), params: { walk_photos: { images: images } }
    end
    assert_redirected_to walk_path(walks(:evening), anchor: "photos")
    assert walks(:evening).photos.first.image.attached?
  end

  test "places each photo on the track from the time it was taken" do
    images = [ fixture_file_upload("dog.png", "image/png"), fixture_file_upload("dog.png", "image/png") ]
    # 18h30 in Paris, during the walk; the second photo doesn't say when it was taken (e.g. a screenshot)
    post walk_photos_path(walks(:evening)),
         params: { walk_photos: { images: images, taken_ats: [ "2026-10-01T16:30:00.000Z", "" ] } }
    placed, unknown = walks(:evening).photos.order(:id)
    assert_equal Time.zone.parse("2026-10-01 18:30"), placed.taken_at
    assert_equal [ 48.4211, 1.502 ], [ placed.latitude, placed.longitude ]
    assert_equal [ nil, nil, nil ], [ unknown.taken_at, unknown.latitude, unknown.longitude ]
  end

  test "refuses a file that is not an image" do
    assert_no_difference "WalkPhoto.count" do
      post walk_photos_path(walks(:evening)),
           params: { walk_photos: { images: [ fixture_file_upload("notes.txt", "text/plain") ] } }
    end
    assert_equal "La photo doit être une image", flash[:alert]
  end

  test "asks to choose a photo when none is sent" do
    assert_no_difference "WalkPhoto.count" do
      post walk_photos_path(walks(:evening)), params: {}
    end
    assert_equal "Choisis au moins une photo.", flash[:alert]
  end

  test "cannot add photos to another account's walk" do
    assert_no_difference "WalkPhoto.count" do
      post walk_photos_path(walks(:strangers_walk)),
           params: { walk_photos: { images: [ fixture_file_upload("dog.png", "image/png") ] } }
    end
    assert_response :not_found
  end

  test "the walk page shows its photos, the button to add some and the full-screen viewer" do
    photo = walks(:evening).photos.create!(image: fixture_file_upload("dog.png", "image/png"))
    get walk_path(walks(:evening))
    assert_select ".walk-photo-button[data-photo-viewer-id-param='#{photo.id}'] .walk-photo", 1
    assert_select "input[type=file][multiple][accept='image/*']"
    assert_select "dialog.photo-viewer"
    viewer = JSON.parse(css_select("[data-controller='photo-viewer']").first["data-photo-viewer-photos-value"])
    assert_equal [ [ photo.id, "📷 Heure inconnue", walk_photo_path(walks(:evening), photo) ] ],
                 viewer.map { |item| item.values_at("id", "time", "delete_url") }
  end

  test "deletes a photo" do
    photo = walks(:evening).photos.create!(image: fixture_file_upload("dog.png", "image/png"))
    assert_difference "WalkPhoto.count", -1 do
      delete walk_photo_path(walks(:evening), photo)
    end
    assert_redirected_to walk_path(walks(:evening), anchor: "photos")
  end

  test "cannot delete a photo of another account's walk" do
    photo = walks(:strangers_walk).photos.create!(image: fixture_file_upload("dog.png", "image/png"))
    assert_no_difference "WalkPhoto.count" do
      delete walk_photo_path(walks(:strangers_walk), photo)
    end
    assert_response :not_found
  end
end
