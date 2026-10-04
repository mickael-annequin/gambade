require "test_helper"

class FriendTest < ActiveSupport::TestCase
  test "ranks friends from the most met, with the last meeting" do
    walks(:morning).encounters.create!(met_at: Time.zone.parse("2026-10-01 08:40"), friend: friends(:filou))
    walks(:morning).encounters.create!(met_at: Time.zone.parse("2026-10-01 08:45"), friend: friends(:filou))
    ranking = dogs(:rex).friends.ranked.to_a
    assert_equal [ "Filou", "Sid" ], ranking.map(&:name)
    assert_equal [ 2, 1 ], ranking.map(&:encounters_count)
    assert_equal Time.zone.parse("2026-10-01 08:45"), ranking.first.last_met_at
  end

  test "finds a friend by name, ignoring case and spaces" do
    assert_equal friends(:sid), dogs(:rex).friends.named(" sid ")
    assert_nil dogs(:rex).friends.named("Rantanplan") # another dog's friend
  end

  test "finds a friend saved with a space after its name (added by the phone keyboard)" do
    friends(:sid).update_column(:name, "Sid ")
    assert_equal friends(:sid), dogs(:rex).friends.named("Sid")
  end

  test "removes the spaces around a name when saving" do
    assert_equal "Rocky", dogs(:rex).friends.create!(name: " Rocky ").name
  end

  test "deleting a friend keeps the encounters" do
    encounter = encounters(:first)
    friends(:sid).destroy
    assert_nil encounter.reload.friend
  end
end
