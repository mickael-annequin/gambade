require "test_helper"

class CaresHelperTest < ActionView::TestCase
  setup { travel_to Date.new(2026, 10, 4) }

  test "says when the next care is due" do
    care = ->(next_due_on) { Care.new(next_due_on: next_due_on) }
    assert_equal "✅ Prochain le 27 oct. 2026 (dans 23 jours)", care_status(care.call(Date.new(2026, 10, 27)))
    assert_equal "⚠️ Prochain le 7 oct. 2026 (dans 3 jours)", care_status(care.call(Date.new(2026, 10, 7)))
    assert_equal "⚠️ À faire aujourd'hui", care_status(care.call(Date.new(2026, 10, 4)))
    assert_equal "🔴 En retard de 5 jours", care_status(care.call(Date.new(2026, 9, 29)))
    assert_nil care_status(care.call(nil))
    assert_equal "care-status-late", care_status_class(care.call(Date.new(2026, 9, 29)))
  end
end
