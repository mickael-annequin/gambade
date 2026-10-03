require "test_helper"

class WalksHelperTest < ActionView::TestCase
  test "formats durations" do
    assert_equal "35 min", walk_duration(2100)
    assert_equal "1 h 05", walk_duration(3900)
  end

  test "formats distances in km with a comma" do
    assert_equal "2,3 km", walk_distance(2300)
  end

  test "names today and yesterday" do
    assert_equal "Aujourd'hui", walk_day(Time.current)
    assert_equal "Hier", walk_day(1.day.ago)
  end
end
