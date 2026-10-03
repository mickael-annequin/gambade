require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home page redirects to the sign in page when signed out" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "home page shows the app name when signed in" do
    sign_in users(:mika)
    get root_path
    assert_response :success
    assert_select "h1", /Gambade/
  end

  test "home page sums up this week's walks and shows the last one" do
    sign_in users(:mika)
    travel_to Time.zone.parse("2026-10-03 12:00") do
      get root_path
    end
    numbers = css_select(".stat-card-number").map { |node| node.text.strip }
    assert_equal [ "3,4", "53 min", "5" ], numbers
    assert_select ".walk-card[href='#{walk_path(walks(:evening))}']"
  end

  test "home page stats ignore walks from previous weeks" do
    sign_in users(:mika)
    travel_to Time.zone.parse("2026-10-20 12:00") do
      get root_path
    end
    assert_equal [ "0,0", "0 min", "0" ], css_select(".stat-card-number").map { |node| node.text.strip }
  end

  test "home page can offer to resume a walk saved in the phone" do
    sign_in users(:mika)
    get root_path
    assert_select "[data-controller='ongoing-walk'] [data-ongoing-walk-target='banner'][hidden]"
    assert_select "a[href='#{new_tracked_walk_path}']", "▶ Démarrer une balade"
  end

  test "home page asks to create the dog profile on first visit" do
    sign_in users(:newcomer)
    get root_path
    assert_redirected_to new_dog_path
  end

  test "the sign in page shows the logo" do
    get new_user_session_path
    assert_response :success
    assert_select ".login img[src*='logo']"
  end

  test "there is no public sign up page" do
    get "/users/sign_up"
    assert_response :not_found
  end
end
