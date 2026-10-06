require "test_helper"

class WalkStatsTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.parse("2026-10-04 12:00") # a Sunday
    walks = dogs(:rex).walks
    walks.destroy_all # start from no walk (the fixtures have some)
    walks.create!(started_at: Time.zone.parse("2026-10-01 18:00"), duration_seconds: 1800, distance_meters: 2300, dogs_met_count: 2)
    walks.create!(started_at: Time.zone.parse("2026-10-03 09:00"), duration_seconds: 3600, distance_meters: 4000, dogs_met_count: 1)
    walks.create!(started_at: Time.zone.parse("2026-09-10 09:00"), duration_seconds: 600, distance_meters: 1000, dogs_met_count: 0)
  end

  test "adds up the walks per week, the last 12 weeks with the empty ones" do
    stats = WalkStats.new(dogs(:rex).walks, period: "week")
    assert_equal 12, stats.buckets.size
    this_week = stats.buckets.last
    assert_equal [ Date.new(2026, 9, 28), 2, 6.3, 90, 3 ], this_week.values_at(:start, :walks, :km, :minutes, :dogs)
    assert_equal 0, stats.buckets[-2][:walks] # week of 21 Sept: no walk
    assert_equal 7.3, stats.total(:km)
  end

  test "adds up the walks per day, the last 14 days" do
    stats = WalkStats.new(dogs(:rex).walks, period: "day")
    assert_equal 14, stats.buckets.size
    assert_equal [ Date.new(2026, 9, 21), Date.new(2026, 10, 4) ], [ stats.buckets.first[:start], stats.buckets.last[:start] ]
    assert_equal [ 1, 0, 1, 0 ], stats.buckets.last(4).map { |bucket| bucket[:walks] } # 1, 2, 3 and 4 Oct.
    assert_equal 6.3, stats.total(:km) # the walk of 10 Sept. is too old
  end

  test "adds up the walks per month" do
    stats = WalkStats.new(dogs(:rex).walks, period: "month")
    assert_equal [ Date.new(2026, 9, 1), Date.new(2026, 10, 1) ], stats.buckets.last(2).map { |bucket| bucket[:start] }
    assert_equal [ 1, 2 ], stats.buckets.last(2).map { |bucket| bucket[:walks] }
  end

  test "an unknown period means per week" do
    assert_equal "week", WalkStats.new(dogs(:rex).walks, period: "year").period
  end
end
