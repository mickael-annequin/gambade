require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "shows the stats per week with 3 charts and the table of numbers" do
    get stats_path
    assert_response :success
    assert_select "[data-controller='stats-chart']", 3
    assert_select ".stats-periods .is-active", "Par semaine"
    assert_select ".stats-table tbody tr", 12
  end

  test "shows the stats per month" do
    get stats_path(period: "month")
    assert_select ".stats-periods .is-active", "Par mois"
    labels = JSON.parse(css_select("[data-controller='stats-chart']").first["data-stats-chart-labels-value"])
    assert_equal 12, labels.size
  end

  test "the home page and the walks list link to the stats" do
    get root_path
    assert_select "a[href='#{stats_path}']"
    get walks_path
    assert_select ".walk-actions a[href='#{stats_path}']"
    assert_select ".walk-actions a[href='#{map_walks_path}']"
  end
end
