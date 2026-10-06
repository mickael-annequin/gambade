require "test_helper"

class EncountersHelperTest < ActionView::TestCase
  test "sums up the details of a dog met" do
    assert_equal "Filou, Beagle 😄", encounter_details(Encounter.new(dog_name: "Filou", breed: "Beagle", mood: "playful"))
    assert_equal "😠", encounter_details(Encounter.new(mood: "tense"))
    assert_nil encounter_details(Encounter.new)
  end
end
