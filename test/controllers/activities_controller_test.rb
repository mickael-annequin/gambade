require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "deletes a play or swim phase started by mistake" do
    assert_difference "Activity.count", -1 do
      delete walk_activity_path(walks(:evening), activities(:swim))
    end
    assert_redirected_to walk_path(walks(:evening))
  end

  test "cannot delete a phase of another account's walk" do
    other = walks(:strangers_walk).activities.create!(kind: "play", started_at: 1.hour.ago, ended_at: 50.minutes.ago)
    assert_no_difference "Activity.count" do
      delete walk_activity_path(walks(:strangers_walk), other)
    end
    assert_response :not_found
  end
end
