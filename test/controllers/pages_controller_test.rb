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

  test "home page asks to create the dog profile on first visit" do
    sign_in users(:newcomer)
    get root_path
    assert_redirected_to new_dog_path
  end

  test "there is no public sign up page" do
    get "/users/sign_up"
    assert_response :not_found
  end
end
