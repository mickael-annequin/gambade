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

  test "groups dogs met at the same place into one map marker" do
    walk = walks(:morning)
    [ [ 48.42060, "08:31" ], [ 48.42061, "08:32" ], [ 48.42062, "08:33" ], [ 48.42240, "08:40" ] ].each do |lat, time|
      walk.encounters.create!(latitude: lat, longitude: 1.5012, met_at: Time.zone.parse("2026-10-01 #{time}"))
    end
    labels = walk.encounter_markers.map { |marker| marker[:label] }
    assert_equal [ "1–3", "4" ], labels
    assert_equal [ "08h31", "08h32", "08h33" ], walk.encounter_markers.first[:times]
  end

  test "cutting the end removes later points and dogs met, and updates the stats" do
    walk = walks(:evening)
    walk.trim_end!(Time.zone.parse("2026-10-01 18:15:00"))
    assert_equal [ track_points(:start) ], walk.track_points.to_a
    assert_equal [ encounters(:first) ], walk.encounters.to_a
    assert_equal 1, walk.dogs_met_count
    assert_equal 600, walk.duration_seconds
    assert_equal 0, walk.distance_meters
    assert_equal [ Time.zone.parse("2026-10-01 18:15:00") ], walk.activities.where(kind: "play").pluck(:ended_at)
    assert_empty walk.activities.where(kind: "swim")
  end

  test "track progress gives the time and the distance walked at each point" do
    progress = walks(:evening).track_progress
    assert_equal 0, progress.first[:meters]
    assert_operator progress.last[:meters], :>, 50
    assert_equal "18h05", progress.first[:time]
  end

  test "simplifies a long track but keeps its start and end" do
    walk = Walk.new(started_at: Time.current)
    1000.times { |i| walk.track_points.build(latitude: 48.42 + i * 0.0001, longitude: 1.5, recorded_at: Time.current + i * 5) }
    track = walk.simplified_track(max_points: 80)
    assert_operator track.size, :<=, 81
    assert_equal [ 1.5, 48.42 ], track.first
    assert_in_delta 48.42 + 999 * 0.0001, track.last.last, 1e-9
  end
end
