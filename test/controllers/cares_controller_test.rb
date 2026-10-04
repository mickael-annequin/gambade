require "test_helper"

class CaresControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "the dog page shows the health follow-up" do
    travel_to Date.new(2026, 10, 4)
    get dog_path
    assert_select "#sante"
    assert_select ".care-status", /Prochain le 1 nov\. 2026/
    assert_select "a[href='#{new_care_path(kind: 'vaccine')}']" # no vaccine yet: a link to add one
  end

  test "adds a care, with the next one computed" do
    get new_care_path(kind: "flea")
    assert_select "input[type=radio][value=flea][checked]"
    assert_difference "Care.count", 1 do
      post cares_path, params: { care: { kind: "flea", given_on: "2026-10-04", next_due_on: "", product: "Bravecto" } }
    end
    assert_redirected_to dog_path(anchor: "sante")
    assert_equal Date.new(2027, 1, 4), Care.last.next_due_on
  end

  test "shows the errors of a wrong care" do
    post cares_path, params: { care: { kind: "", given_on: "" } }
    assert_response :unprocessable_content
  end

  test "lists, updates and deletes my cares only" do
    get cares_path
    assert_select ".encounter-card", 2 # not the other dog's vaccine
    patch care_path(cares(:dewormer)), params: { care: { product: "Drontal" } }
    assert_equal "Drontal", cares(:dewormer).reload.product
    assert_difference "Care.count", -1 do
      delete care_path(cares(:dewormer))
    end
    delete care_path(cares(:strangers_vaccine))
    assert_response :not_found
  end

  test "the home page reminds the cares to do soon or late, not the others" do
    travel_to Date.new(2026, 10, 29) do # dewormer due on 1 Nov
      dogs(:rex).cares.create!(kind: "flea", given_on: Date.new(2026, 7, 1)) # due 1 Oct: late
      dogs(:rex).cares.create!(kind: "vaccine", given_on: Date.new(2026, 5, 1)) # next year: fine
      get root_path
      assert_select ".care-reminder div", 2
      assert_select ".care-reminder div.care-status-late", /Anti-puces.*en retard de 28 jours/
      assert_select ".care-reminder div.care-status-soon", /Vermifuge.*à faire dans 3 jours/
    end
  end

  test "no reminder when nothing is due" do
    travel_to Date.new(2026, 10, 4) do # dewormer due in 28 days
      get root_path
      assert_select ".care-reminder", 0
    end
  end
end
