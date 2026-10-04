require "test_helper"

class DogsControllerTest < ActionDispatch::IntegrationTest
  test "shows my dog profile" do
    sign_in users(:mika)
    get dog_path
    assert_response :success
    assert_select "h2", "Rex"
    assert_equal [ "3,4", "2", "5" ], css_select(".stat-card-number").map { |node| node.text.strip }
    assert_select ".encounter-list .encounter-card", 2 # best friends
    assert_select "a.small-action[href='#{friends_path}']", "Voir le carnet"
  end

  test "creates the dog profile on first visit" do
    sign_in users(:newcomer)
    assert_difference "Dog.count", 1 do
      post dog_path, params: { dog: { name: "Pixel", breed: "Beagle", birth_date: "2024-05-01" } }
    end
    assert_redirected_to root_path
  end

  test "does not create a dog without a name" do
    sign_in users(:newcomer)
    assert_no_difference "Dog.count" do
      post dog_path, params: { dog: { name: "" } }
    end
    assert_response :unprocessable_content
  end

  test "does not create a second dog" do
    sign_in users(:mika)
    assert_no_difference "Dog.count" do
      post dog_path, params: { dog: { name: "Second" } }
    end
    assert_redirected_to dog_path
  end

  test "updates my dog profile" do
    sign_in users(:mika)
    patch dog_path, params: { dog: { name: "Rex le grand" } }
    assert_redirected_to dog_path
    assert_equal "Rex le grand", dogs(:rex).reload.name
  end
end
