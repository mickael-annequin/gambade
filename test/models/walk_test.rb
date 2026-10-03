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

  test "refuses a distance that is not a number" do
    walk = walks(:evening)
    walk.distance_km = "abc"
    assert_not walk.valid?
    assert_includes walk.errors[:distance_meters], "doit être un nombre"
    assert_equal 2300, walk.distance_meters
  end

  test "an empty distance means 0 km" do
    assert_equal 0, Walk.new(distance_km: "").distance_meters
  end

  test "measures the distance along GPS points" do
    points = [ { latitude: 48.4206, longitude: 1.5012 }, { latitude: 48.4296, longitude: 1.5012 },
               { latitude: 48.4206, longitude: 1.5012 } ]
    assert_in_delta 2002, Walk.distance_along(points), 2
  end
end
