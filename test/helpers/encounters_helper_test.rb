require "test_helper"

class EncountersHelperTest < ActionView::TestCase
  test "numbers encounters with circled digits" do
    assert_equal "①", encounter_number(1)
    assert_equal "⑳", encounter_number(20)
    assert_equal "(21)", encounter_number(21)
  end

  test "sums up the details of a dog met" do
    assert_equal "Filou, Beagle 😊", encounter_details(Encounter.new(dog_name: "Filou", breed: "Beagle", mood: "joyful"))
    assert_equal "😠", encounter_details(Encounter.new(mood: "tense"))
    assert_nil encounter_details(Encounter.new)
  end
end
