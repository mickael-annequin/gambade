require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is invalid without an email" do
    user = User.new(password: "password")
    assert_not user.valid?
  end
end
