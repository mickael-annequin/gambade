require "test_helper"

class EncounterTest < ActiveSupport::TestCase
  test "can be saved without a position" do
    encounter = Encounter.new(walk: walks(:evening), met_at: Time.current)
    assert encounter.valid?
  end

  test "is invalid without a time" do
    assert_not Encounter.new(walk: walks(:evening)).valid?
  end

  test "only accepts the planned moods" do
    encounter = encounters(:first)
    encounter.mood = "playful"
    assert encounter.valid?
    encounter.mood = "grumpy"
    assert_not encounter.valid?
  end
end
