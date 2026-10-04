require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "the back button is a round arrow drawing, labelled for screen readers" do
    html = back_button("/walks", label: "Annuler")
    link = Nokogiri::HTML.fragment(html).at_css("a.back-button")
    assert_equal [ "/walks", "Annuler", "Annuler" ], %w[href title aria-label].map { |name| link[name] }
    assert link.at_css("svg[aria-hidden='true'] path")
  end
end
