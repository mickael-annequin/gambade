require "test_helper"

class WalksHelperTest < ActionView::TestCase
  include CloudinaryHelper # cl_image_path, available in the real pages
  test "formats durations" do
    assert_equal "35 min", walk_duration(2100)
    assert_equal "1 h 05", walk_duration(3900)
    assert_equal "< 1 min", walk_duration(20)
    assert_equal "0 min", walk_duration(0)
  end

  test "formats distances in km with a comma" do
    assert_equal "2,3 km", walk_distance(2300)
  end

  test "names today and yesterday" do
    assert_equal "Aujourd'hui", walk_day(Time.current)
    assert_equal "Hier", walk_day(1.day.ago)
  end

  test "sums up play and swim phases" do
    assert_equal "🎾 12 min de jeu", walk_play_summary(walks(:evening))
    assert_equal "💦 1 baignade (8 min)", walk_swim_summary(walks(:evening))
    assert_nil walk_play_summary(walks(:morning))
  end

  test "builds a small map picture of the track, only when there is one" do
    url = walk_map_image_url(walks(:evening))
    assert_match %r{\Ahttps://api\.mapbox\.com/styles/v1/mapbox/outdoors-v12/static/path-4\+E08E45\(}, url
    assert_nil walk_map_image_url(walks(:morning))
  end

  test "shows the mood emojis of a walk" do
    assert_equal "⚡😴", walk_mood_emojis(Walk.new(moods: %w[energetic tired]))
  end

  test "map markers only for the photos placed on the track" do
    walk = walks(:evening)
    image = -> { { io: file_fixture("dog.png").open, filename: "dog.png" } }
    walk.photos.create!(image: image.call, taken_at: Time.zone.parse("2026-10-01 18:30"), latitude: 48.4211, longitude: 1.502)
    walk.photos.create!(image: image.call) # no time: in the gallery only
    markers = walk_photo_markers(walk)
    assert_equal 1, markers.size
    assert_equal "18h30", markers.first[:time]
    assert_equal [ 1.502, 48.4211 ], markers.first[:coordinates]
    assert_includes markers.first[:thumbnail], "res.cloudinary.com/gambade-test"
  end
end
