require "test_helper"

class WalkTest < ActiveSupport::TestCase
  test "converts minutes and km from the form" do
    walk = Walk.new(duration_minutes: "35", distance_km: "2,3")
    assert_equal 2100, walk.duration_seconds
    assert_equal 2300, walk.distance_meters
  end

  test "accepts a distance written with a dot" do
    assert_equal 2300, Walk.new(distance_km: "2.3").distance_meters
  end

  test "is invalid without a duration" do
    walk = Walk.new(dog: dogs(:rex), started_at: Time.current)
    assert_not walk.valid?
    assert walk.errors[:duration_seconds].any?
  end

  test "is invalid with a negative number of dogs met" do
    walk = walks(:evening)
    walk.dogs_met_count = -1
    assert_not walk.valid?
  end
end
