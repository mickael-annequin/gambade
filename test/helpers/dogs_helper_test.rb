require "test_helper"

class DogsHelperTest < ActionView::TestCase
  setup { travel_to Date.new(2026, 10, 4) }

  test "gives the age in years and months" do
    age = ->(birth_date) { dog_details(Dog.new(birth_date: birth_date)) }
    assert_equal "1 an et 8 mois", age.call(Date.new(2025, 2, 1))
    assert_equal "1 an et 7 mois", age.call(Date.new(2025, 2, 10)) # 8 months on 10 October
    assert_equal "4 ans", age.call(Date.new(2022, 10, 4))
    assert_equal "2 ans et 1 mois", age.call(Date.new(2024, 9, 1))
    assert_equal "8 mois", age.call(Date.new(2026, 2, 1))
    assert_equal "0 mois", age.call(Date.new(2026, 9, 20))
  end

  test "with the breed" do
    assert_equal "Border Collie · 4 ans et 6 mois", dog_details(Dog.new(breed: "Border Collie", birth_date: Date.new(2022, 3, 15)))
    assert_equal "Border Collie", dog_details(Dog.new(breed: "Border Collie"))
  end
end
