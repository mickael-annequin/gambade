require "test_helper"

class WalksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "lists my walks" do
    get walks_path
    assert_response :success
    assert_select "h2", "Octobre 2026"
  end

  test "shows a walk with its GPS track on the map" do
    get walk_path(walks(:evening))
    assert_response :success
    assert_select "[data-controller='map'][data-map-track-value='[[1.5012,48.4206],[1.502,48.4211]]']"
  end

  test "shows the dogs met on the map, numbered in time order" do
    get walk_path(walks(:evening))
    markers = JSON.parse(css_select("[data-controller='map']").first["data-map-encounters-value"])
    assert_equal [ { "label" => "1", "times" => [ "18h12" ], "coordinates" => [ 1.5015, 48.4208 ] } ], markers
  end

  test "shows the play and swim phases of a walk" do
    get walk_path(walks(:evening))
    assert_select "p", "🎾 12 min de jeu"
    assert_select "p", "💦 1 baignade (8 min)"
    markers = JSON.parse(css_select("[data-controller='map']").first["data-map-activities-value"])
    assert_equal [ { "icon" => "🎾", "times" => "18h10–18h22", "coordinates" => [ 1.5016, 48.4209 ] } ], markers
  end

  test "shows a walk entered by hand without a map nor cut link" do
    get walk_path(walks(:morning))
    assert_response :success
    assert_select "[data-controller='map']", count: 0
    assert_select "a", text: "✂️ Couper la fin", count: 0
  end

  test "offers to cut the end of a tracked walk" do
    get walk_path(walks(:evening))
    assert_select "a[href='#{edit_walk_trim_path(walks(:evening))}']", "✂️ Couper la fin"
  end

  test "creates a walk entered by hand" do
    assert_difference "Walk.count", 1 do
      post walks_path, params: { walk: { started_at: "2026-10-02T18:05", duration_minutes: "35",
                                         distance_km: "2,3", dogs_met_count: "4" } }
    end
    walk = Walk.last
    assert_redirected_to walk_path(walk)
    assert_equal 2300, walk.distance_meters
    assert_not walk.tracked
  end

  test "does not create a walk without a duration" do
    assert_no_difference "Walk.count" do
      post walks_path, params: { walk: { started_at: "2026-10-02T18:05", duration_minutes: "" } }
    end
    assert_response :unprocessable_content
    assert_select "li", "Durée doit être rempli(e)"
  end

  test "updates a walk" do
    patch walk_path(walks(:evening)), params: { walk: { dogs_met_count: "5" } }
    assert_redirected_to walk_path(walks(:evening))
    assert_equal 5, walks(:evening).reload.dogs_met_count
  end

  test "deletes a walk" do
    assert_difference "Walk.count", -1 do
      delete walk_path(walks(:evening))
    end
    assert_redirected_to walks_path
  end

  test "cannot open the walk of another account" do
    get walk_path(walks(:strangers_walk))
    assert_response :not_found
  end
end
