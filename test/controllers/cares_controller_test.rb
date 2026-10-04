require "test_helper"

class CaresControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "the dog page shows the health follow-up" do
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
end
