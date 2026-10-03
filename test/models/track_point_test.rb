require "test_helper"

class TrackPointTest < ActiveSupport::TestCase
  test "keeps 6 decimals of latitude and longitude (about 10 cm)" do
    point = TrackPoint.create!(walk: walks(:evening), latitude: 48.4206123, longitude: 1.5012456, recorded_at: Time.current)
    assert_equal BigDecimal("48.420612"), point.reload.latitude
  end

  test "is invalid with a latitude out of range" do
    point = TrackPoint.new(walk: walks(:evening), latitude: 91, longitude: 1.5, recorded_at: Time.current)
    assert_not point.valid?
  end

  test "is invalid without a time" do
    point = TrackPoint.new(walk: walks(:evening), latitude: 48.42, longitude: 1.5)
    assert_not point.valid?
  end

  test "points are deleted with their walk" do
    assert_difference "TrackPoint.count", -2 do
      walks(:evening).destroy
    end
  end
end
