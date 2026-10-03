require "test_helper"

class PolylineTest < ActiveSupport::TestCase
  test "encodes like Google's official example" do
    coordinates = [ [ -120.2, 38.5 ], [ -120.95, 40.7 ], [ -126.453, 43.252 ] ]
    assert_equal "_p~iF~ps|U_ulLnnqC_mqNvxq`@", Polyline.encode(coordinates)
  end
end
