require "test_helper"

class WalkTrimsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
    @walk = walks(:evening)
  end

  test "shows the slider to cut the end of a tracked walk" do
    get edit_walk_trim_path(@walk)
    assert_response :success
    assert_select "input[type='range'][data-trim-target='slider']"
    assert_select "button[data-action='trim#step'][data-trim-by-param='-1']", "◀"
    assert_select "button[data-action='trim#step'][data-trim-by-param='1']", "▶"
    assert_select "[data-trim-target='toggle']", 0 # this walk never left the start: no arrival zone
  end

  test "cuts everything recorded after the chosen time and recomputes the walk" do
    ended_at = Time.zone.parse("2026-10-01 18:15:00")
    assert_difference "TrackPoint.count", -1 do
      patch walk_trim_path(@walk), params: { ended_at: ended_at.iso8601 }
    end
    assert_redirected_to walk_path(@walk)
    @walk.reload
    assert_equal 0, @walk.distance_meters
    assert_equal 600, @walk.duration_seconds
  end

  test "refuses a time before the start of the walk" do
    assert_no_difference "TrackPoint.count" do
      patch walk_trim_path(@walk), params: { ended_at: (@walk.started_at - 1.hour).iso8601 }
    end
    assert_redirected_to edit_walk_trim_path(@walk)
  end

  test "a walk entered by hand has nothing to cut" do
    get edit_walk_trim_path(walks(:morning))
    assert_redirected_to walk_path(walks(:morning))
  end

  test "cannot cut the walk of another account" do
    get edit_walk_trim_path(walks(:strangers_walk))
    assert_response :not_found
  end
end
