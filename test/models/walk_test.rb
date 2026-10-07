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
    points = [ { latitude: 48.4206, longitude: 1.5012, recorded_at: "2026-10-01T08:00:00Z" },
               { latitude: 48.4296, longitude: 1.5012, recorded_at: "2026-10-01T08:10:00Z" },
               { latitude: 48.4206, longitude: 1.5012, recorded_at: "2026-10-01T08:20:00Z" } ]
    assert_in_delta 2002, Walk.distance_along(points), 2
  end

  # Walking 111 m north in 1 min 40 s, one point every 5 s, each one 7 m left or right of the path.
  test "does not count the GPS zigzag as walked distance" do
    start = Time.zone.parse("2026-10-01 08:00")
    points = (0..20).map do |i|
      { latitude: 48.42 + i * 0.00005, longitude: 1.5 + (i.even? ? 0.0001 : -0.0001), recorded_at: start + (i * 5).seconds }
    end
    assert_operator Walk.distance_along(points), :<, 125
    assert_operator points.each_cons(2).sum { |from, to| Walk.distance_between(from, to) }, :>, 300
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

  test "track progress ends at the distance of the whole walk" do
    walk = walk_with_track(0, 1, 2, 3)
    walk.track_points.each_with_index { |point, index| point.update!(recorded_at: walk.started_at + (index * 5).seconds) }
    assert_equal [ 0, 0, 0, 0 ], walk.track_progress.map { |step| step[:meters] }

    walk.track_points.each_with_index { |point, index| point.update!(recorded_at: walk.started_at + (index * 15).seconds) }
    assert_equal [ 0, 0, 167, 222 ], walk.track_progress.map { |step| step[:meters] }
    assert_equal walk.track_distance, walk.track_progress.last[:meters]
  end

  # A walk going north of the start: 0.001° of latitude ≈ 111 m.
  def walk_with_track(*thousandths_north)
    walk = dogs(:rex).walks.create!(started_at: Time.zone.parse("2026-10-01 18:00"), duration_seconds: 3600, tracked: true)
    thousandths_north.each_with_index do |north, index|
      walk.track_points.create!(latitude: 48.42 + north / 1000.0, longitude: 1.5, recorded_at: walk.started_at + index.minutes)
    end
    walk
  end

  test "the arrival zone is the return near the start, until leaving it again" do
    # start, leaves (444 m), comes back: 167 m (enters the zone), 33 m (back at the start), 11 m, then drives away
    walk = walk_with_track(0, 2, 4, 6, 4, 1.5, 0.3, 0.1, 5, 9)
    assert_equal({ from: 5, to: 7, suggested: 6 }, walk.arrival_zone)
  end

  test "the arrival zone is the last return near the start (figure-8 walks)" do
    walk = walk_with_track(0, 4, 1, 0.2, 4, 1, 0.2)
    assert_equal({ from: 5, to: 6, suggested: 6 }, walk.arrival_zone)
  end

  test "no arrival zone when the walk never really left or never came back" do
    assert_nil walk_with_track(0, 1, 2, 1, 0).arrival_zone
    assert_nil walk_with_track(0, 3, 6, 9).arrival_zone
  end

  test "finds where we were at a given time, to place a photo" do
    walk = walks(:evening) # 18h05 → 18h40, points at 18h05 and 18h25
    at = ->(time) { walk.position_at(Time.zone.parse("2026-10-01 #{time}"))&.fetch(:latitude) }
    assert_equal 48.4206, at.call("18:10")  # last point before: the start
    assert_equal 48.4211, at.call("18:30")  # standing still since 18h25: no new point, still there
    assert_equal 48.4206, at.call("18:04:30") # just before the first point: the start
    assert_nil at.call("19:30") # after the walk
    assert_nil walk.position_at(nil) # photo without a time
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
