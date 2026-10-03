require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "the back button is a round arrow, labelled for screen readers" do
    html = back_button("/walks", label: "Annuler")
    assert_dom_equal '<a class="back-button" title="Annuler" aria-label="Annuler" href="/walks">←</a>', html
  end
end
