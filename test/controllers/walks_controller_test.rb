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
