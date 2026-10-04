require "test_helper"

class CareTest < ActiveSupport::TestCase
  test "computes the next one from the usual rhythm when it is left empty" do
    given_on = Date.new(2026, 10, 4)
    next_dates = %w[vaccine dewormer flea vet].map do |kind|
      dogs(:rex).cares.create!(kind: kind, given_on: given_on).next_due_on
    end
    assert_equal [ Date.new(2027, 10, 4), Date.new(2027, 1, 4), Date.new(2027, 1, 4), nil ], next_dates
  end

  test "keeps a next date chosen by hand, but not one before the care" do
    care = dogs(:rex).cares.create!(kind: "vaccine", given_on: Date.new(2026, 10, 4), next_due_on: Date.new(2027, 4, 4))
    assert_equal Date.new(2027, 4, 4), care.next_due_on
    care.next_due_on = Date.new(2026, 9, 1)
    assert_not care.valid?
    assert_includes care.errors.full_messages, "La date du prochain doit être après la date du soin"
  end

  test "refuses an unknown kind" do
    assert_not dogs(:rex).cares.new(kind: "massage", given_on: Date.current).valid?
  end

  test "the dog's latest care of each kind to watch" do
    assert_equal [ cares(:dewormer) ], dogs(:rex).latest_cares # not the old one, no vaccine/flea yet
  end
end
