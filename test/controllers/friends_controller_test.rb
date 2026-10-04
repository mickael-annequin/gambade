require "test_helper"

class FriendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "lists the friends from the most met" do
    get friends_path
    assert_response :success
    names = css_select(".encounter-card strong").map { |node| node.text.strip }
    assert_equal [ "Sid · Malinois", "Filou · Beagle" ], names
    assert_select ".encounter-card", /croisé 1 fois · dernière fois jeudi 1 octobre/
    assert_select ".navbar-bottom a.active", /Mon chien/
  end

  test "shows a friend with your encounters" do
    get friend_path(friends(:sid))
    assert_select "h1", "Sid"
    assert_select ".encounter-card[href='#{walk_path(walks(:evening))}']"
  end

  test "adds, renames and removes a friend" do
    assert_difference "Friend.count", 1 do
      post friends_path, params: { friend: { name: "Rocky", breed: "Boxer" } }
    end
    rocky = Friend.find_by(name: "Rocky")
    patch friend_path(rocky), params: { friend: { name: "Rocky Balboa" } }
    assert_equal "Rocky Balboa", rocky.reload.name
    assert_difference "Friend.count", -1 do
      delete friend_path(rocky)
    end
  end

  test "refuses a friend without a name" do
    assert_no_difference "Friend.count" do
      post friends_path, params: { friend: { name: "" } }
    end
    assert_response :unprocessable_content
  end

  test "cannot open another account's friend" do
    get friend_path(friends(:strangers_friend))
    assert_response :not_found
  end
end
