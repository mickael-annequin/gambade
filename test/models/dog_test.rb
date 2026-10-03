require "test_helper"

class DogTest < ActiveSupport::TestCase
  test "is invalid without a name" do
    dog = Dog.new(user: users(:mika))
    assert_not dog.valid?
    assert_includes dog.errors[:name], "doit être rempli(e)"
  end

  test "is invalid with a birth date in the future" do
    dog = Dog.new(user: users(:mika), name: "Rex", birth_date: Date.current + 1)
    assert_not dog.valid?
  end

  test "computes the age in full years" do
    travel_to Date.new(2026, 3, 14) do
      assert_equal 3, dogs(:rex).age
    end
    travel_to Date.new(2026, 3, 15) do
      assert_equal 4, dogs(:rex).age
    end
  end

  test "has no age without a birth date" do
    assert_nil Dog.new(name: "Rex").age
  end

  test "accepts an image as photo" do
    dog = dogs(:rex)
    dog.photo.attach(io: file_fixture("dog.png").open, filename: "dog.png", content_type: "image/png")
    assert dog.valid?
  end

  test "refuses a photo that is not an image" do
    dog = dogs(:rex)
    dog.photo.attach(io: file_fixture("notes.txt").open, filename: "notes.txt", content_type: "text/plain")
    assert_not dog.valid?
    assert_includes dog.errors[:photo], "doit être une image"
  end
end
