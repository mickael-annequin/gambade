require "test_helper"

class TrackedWalksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "shows the live walk screen without the navigation bar" do
    get new_tracked_walk_path
    assert_response :success
    assert_select "[data-controller~='tracking'][data-controller~='screen-lock']"
    assert_select "button[data-action='screen-lock#lock']", "🔒 Verrouiller"
    assert_select "[data-screen-lock-target='overlay'][hidden] [data-screen-lock-target='holdButton']"
    # A long press fires "contextmenu" on Android: it must not cancel the unlock.
    assert_select "[data-screen-lock-target='holdButton'][data-action*='contextmenu->screen-lock#preventMenu']"
    assert_select "nav", count: 0
    assert_select "[data-tracking-target='dogPanel'][hidden] [data-tracking-mood-param='joyful']"
    # The dog's name suggests the friends of the address book
    assert_select "input[data-tracking-target='dogName'][list='friend-names']"
    assert_equal %w[Filou Sid], css_select("datalist#friend-names option").map { |option| option["value"] }
    assert_select "[data-tracking-target='suggestion'][hidden] button[data-tracking-confirm-param='false']", "■ Terminer"
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
    assert_equal walk_path(walk, finished: true), response.parsed_body["url"]
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

  test "saves the dogs met during the walk" do
    encounters = [
      { latitude: 48.4210, longitude: 1.5015, met_at: "2026-10-03T16:05:00Z", dog_name: "Filou", mood: "joyful" },
      { met_at: "2026-10-03T16:07:00Z" },
      { latitude: 999, longitude: 1.5, met_at: "2026-10-03T16:09:00Z" }
    ]
    assert_difference "Encounter.count", 2 do
      post tracked_walks_path, as: :json, params: { walk: {
        started_at: "2026-10-03T16:00:00Z", ended_at: "2026-10-03T16:30:00Z", track_points: [], encounters: encounters
      } }
    end
    assert_equal 2, Walk.last.dogs_met_count
    assert_equal [ [ "Filou", "joyful" ], [ nil, nil ] ], Walk.last.encounters.in_order.pluck(:dog_name, :mood)
    # "Filou" typed during the walk is a friend: the encounter is linked to the address book.
    assert_equal [ friends(:filou), nil ], Walk.last.encounters.in_order.map(&:friend)
  end

  test "saves the play and swim phases, even at the same time" do
    activities = [
      { kind: "play", started_at: "2026-10-03T16:05:00Z", ended_at: "2026-10-03T16:15:00Z", latitude: 48.421, longitude: 1.501 },
      { kind: "swim", started_at: "2026-10-03T16:10:00Z", ended_at: "2026-10-03T16:12:00Z" },
      { kind: "nap", started_at: "2026-10-03T16:20:00Z", ended_at: "2026-10-03T16:25:00Z" }
    ]
    assert_difference "Activity.count", 2 do
      post tracked_walks_path, as: :json, params: { walk: {
        started_at: "2026-10-03T16:00:00Z", ended_at: "2026-10-03T16:30:00Z", track_points: [], activities: activities
      } }
    end
  end

  test "the same walk sent twice is saved only once" do
    walk_params = { client_id: "6f1c2c4e-1111-4b8a-9a55-0d1e2f3a4b5c",
                    started_at: "2026-10-03T16:00:00Z", ended_at: "2026-10-03T16:30:00Z",
                    track_points: [ { latitude: 48.42, longitude: 1.5, recorded_at: "2026-10-03T16:00:00Z" } ] }
    assert_difference "Walk.count", 1 do
      post tracked_walks_path, as: :json, params: { walk: walk_params }
      post tracked_walks_path, as: :json, params: { walk: walk_params }
    end
    assert_response :success
    assert_equal walk_path(Walk.find_by(client_id: walk_params[:client_id]), finished: true), response.parsed_body["url"]
    assert_equal 1, Walk.find_by(client_id: walk_params[:client_id]).track_points.count
  end
end
