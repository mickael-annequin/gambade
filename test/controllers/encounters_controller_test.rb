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
    assert_select "input[type='radio'][value='joyful'].btn-check"
    assert_select "label.mood-button", 3
    assert_select "button.danger-button", /Supprimer cette rencontre/
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

  test "links a dog met to a friend of the address book" do
    encounter = encounters(:without_position)
    patch walk_encounter_path(@walk, encounter), params: { encounter: { friend_id: friends(:filou).id } }
    assert_equal friends(:filou), encounter.reload.friend
  end

  test "adds the dog met to the address book" do
    encounter = encounters(:without_position)
    assert_difference "Friend.count", 1 do
      patch walk_encounter_path(@walk, encounter),
            params: { encounter: { dog_name: "Rocky", breed: "Boxer", add_to_friends: "1" } }
    end
    assert_equal [ "Rocky", "Boxer" ], [ encounter.reload.friend.name, encounter.friend.breed ]
  end

  test "adding a name already in the address book links to that friend" do
    encounter = encounters(:without_position)
    assert_no_difference "Friend.count" do
      patch walk_encounter_path(@walk, encounter), params: { encounter: { dog_name: "filou", add_to_friends: "1" } }
    end
    assert_equal friends(:filou), encounter.reload.friend
  end

  test "cannot link a friend of another account" do
    encounter = encounters(:without_position)
    patch walk_encounter_path(@walk, encounter), params: { encounter: { friend_id: friends(:strangers_friend).id } }
    assert_response :unprocessable_content
    assert_nil encounter.reload.friend
  end
end
