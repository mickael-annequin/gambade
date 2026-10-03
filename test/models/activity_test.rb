require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "only accepts play or swim" do
    activity = activities(:play)
    activity.kind = "nap"
    assert_not activity.valid?
  end

  test "cannot end before it starts" do
    activity = activities(:play)
    activity.ended_at = activity.started_at - 1.minute
    assert_not activity.valid?
    assert_includes activity.errors[:ended_at], "ne peut pas être avant le début"
  end

  test "knows its duration" do
    assert_equal 720, activities(:play).duration_seconds
  end
end
