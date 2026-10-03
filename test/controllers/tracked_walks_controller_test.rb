require "test_helper"

class TrackedWalksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "shows the live walk screen without the navigation bar" do
    get new_tracked_walk_path
    assert_response :success
    assert_select "[data-controller='tracking']"
    assert_select "nav", count: 0
  end

  test "saves a tracked walk with its GPS points" do
    points = [
      { latitude: 48.4206, longitude: 1.5012, accuracy: 8, recorded_at: "2026-10-03T16:00:00Z" },
      { latitude: 48.4296, longitude: 1.5012, accuracy: 6, recorded_at: "2026-10-03T16:10:00Z" }
    ]
    assert_difference "Walk.count", 1 do
      assert_difference "TrackPoint.count", 2 do
        post tracked_walks_path, as: :json, params: { walk: {
          started_at: "2026-10-03T16:00:00Z", ended_at: "2026-10-03T16:35:00Z", track_points: points
        } }
      end
    end
    assert_response :created
    walk = Walk.last
    assert walk.tracked
    assert_equal 2100, walk.duration_seconds
    assert_in_delta 1001, walk.distance_meters, 2
    assert_equal walk_path(walk), response.parsed_body["url"]
  end

  test "ignores GPS points with invalid coordinates" do
    points = [
      { latitude: 48.4206, longitude: 1.5012, recorded_at: "2026-10-03T16:00:00Z" },
      { latitude: 999, longitude: 1.5012, recorded_at: "2026-10-03T16:00:05Z" }
    ]
    assert_difference "TrackPoint.count", 1 do
      post tracked_walks_path, as: :json, params: { walk: {
        started_at: "2026-10-03T16:00:00Z", ended_at: "2026-10-03T16:05:00Z", track_points: points
      } }
    end
  end

  test "refuses a walk without times" do
    assert_no_difference "Walk.count" do
      post tracked_walks_path, as: :json, params: { walk: { started_at: "", ended_at: "" } }
    end
    assert_response :unprocessable_content
  end
end
