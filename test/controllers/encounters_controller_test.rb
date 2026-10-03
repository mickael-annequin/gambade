require "test_helper"

class EncountersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
    @walk = walks(:evening)
    @encounter = encounters(:first)
  end

  test "shows the optional details form" do
    get edit_walk_encounter_path(@walk, @encounter)
    assert_response :success
    assert_select "input[type='radio'][value='joyful']"
  end

  test "saves the details of a dog met" do
    patch walk_encounter_path(@walk, @encounter),
          params: { encounter: { dog_name: "Filou", breed: "Beagle", mood: "joyful", note: "Très joueur" } }
    assert_redirected_to walk_path(@walk)
    assert_equal [ "Filou", "Beagle", "joyful" ], @encounter.reload.values_at(:dog_name, :breed, :mood)
  end

  test "refuses an unknown mood" do
    patch walk_encounter_path(@walk, @encounter), params: { encounter: { mood: "grumpy" } }
    assert_response :unprocessable_content
  end

  test "deletes a dog met by mistake and updates the count" do
    assert_difference "Encounter.count", -1 do
      delete walk_encounter_path(@walk, @encounter)
    end
    assert_redirected_to walk_path(@walk)
    assert_equal 1, @walk.reload.dogs_met_count
  end

  test "cannot open a dog met during another account's walk" do
    other = walks(:strangers_walk).encounters.create!(met_at: Time.current)
    get edit_walk_encounter_path(walks(:strangers_walk), other)
    assert_response :not_found
  end
end
