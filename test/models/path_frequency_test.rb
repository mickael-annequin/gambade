require "test_helper"

class PathFrequencyTest < ActiveSupport::TestCase
  # A walk going east along the same street, with GPS points a few meters apart.
  def walk_along(latitude, from_longitude:, to_longitude:)
    walk = dogs(:rex).walks.create!(started_at: Time.current, duration_seconds: 600, distance_meters: 500, tracked: true)
    from_longitude.step(to_longitude, 0.0001).each_with_index do |longitude, index|
      walk.track_points.create!(latitude: latitude, longitude: longitude, recorded_at: Time.current + index.seconds)
    end
    walk
  end

  test "counts how many walks went through a place, despite a few meters of GPS imprecision" do
    once = walk_along(48.4300, from_longitude: 1.5000, to_longitude: 1.5050)
    again = walk_along(48.43005, from_longitude: 1.5000, to_longitude: 1.5020) # 5 m away: same street
    elsewhere = walk_along(48.4400, from_longitude: 1.5000, to_longitude: 1.5020) # 1 km away
    frequency = PathFrequency.new([ once, again, elsewhere ])

    assert_equal 2, frequency.passes_at([ 1.5010, 48.4300 ]) # both walks on the street
    assert_equal 1, frequency.passes_at([ 1.5045, 48.4300 ]) # only the longer walk went that far
    assert_equal 1, frequency.passes_at([ 1.5010, 48.4400 ])
  end

  test "cuts a track into pieces of the same number of passes" do
    long = walk_along(48.4300, from_longitude: 1.5000, to_longitude: 1.5050)
    short = walk_along(48.4300, from_longitude: 1.5000, to_longitude: 1.5020)
    frequency = PathFrequency.new([ long, short ])

    pieces = frequency.pieces([ [ 1.5000, 48.43 ], [ 1.5010, 48.43 ], [ 1.5040, 48.43 ], [ 1.5050, 48.43 ] ])
    assert_equal [ 2, 1 ], pieces.map { |piece| piece[:passes] }
    assert_equal [ [ 1.5000, 48.43 ], [ 1.5010, 48.43 ] ], pieces.first[:track]
    assert_equal [ [ 1.5010, 48.43 ], [ 1.5040, 48.43 ], [ 1.5050, 48.43 ] ], pieces.last[:track]
  end
end
