require "test_helper"

class WeighingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "the dog page shows the last weight, the change and the curve" do
    get dog_path
    assert_select ".weight-summary strong", "24,3 kg"
    assert_select ".weight-summary", /\+1,5 kg depuis le 1 juil\./
    points = JSON.parse(css_select("[data-controller='weight-chart']").first["data-weight-chart-points-value"])
    assert_equal [ { "x" => "2026-07-01", "y" => 22.8 }, { "x" => "2026-10-01", "y" => 24.3 } ], points
  end

  test "adds a weighing typed with a French comma" do
    assert_difference "Weighing.count", 1 do
      post weighings_path, params: { weighing: { measured_on: "2026-10-04", weight_kg: "24,6" } }
    end
    assert_redirected_to dog_path(anchor: "poids")
    assert_equal 24.6, Weighing.last.weight_kg
  end

  test "refuses a weight that is not a number" do
    assert_no_difference "Weighing.count" do
      post weighings_path, params: { weighing: { measured_on: "2026-10-04", weight_kg: "lourd" } }
    end
    assert_response :unprocessable_content
  end

  test "lists, updates and deletes my weighings only" do
    get weighings_path
    assert_select ".encounter-card", 2
    assert_select ".encounter-card", /24,3 kg.*\+1,5 kg/m
    patch weighing_path(weighings(:autumn)), params: { weighing: { weight_kg: "24,1" } }
    assert_equal 24.1, weighings(:autumn).reload.weight_kg
    assert_difference "Weighing.count", -1 do
      delete weighing_path(weighings(:autumn))
    end
    delete weighing_path(weighings(:strangers))
    assert_response :not_found
  end

  test "no curve with a single weighing" do
    weighings(:summer).destroy
    get dog_path
    assert_select "[data-controller='weight-chart']", 0
    assert_select ".weight-summary", /24,3 kg/
  end
end
