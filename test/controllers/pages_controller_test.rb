require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home page shows the app name" do
    get root_path
    assert_response :success
    assert_select "h1", /Gambade/
  end
end
