require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "serves the manifest that makes Gambade installable" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    manifest = response.parsed_body
    assert_equal "Gambade", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal [ "192x192", "512x512", "512x512" ], manifest["icons"].map { |icon| icon["sizes"] }
  end

  test "every page links the manifest" do
    get new_user_session_path
    assert_select "link[rel='manifest'][href='/manifest.json']"
  end

  test "the icons exist" do
    %w[icon.png icon-192.png icon-maskable.png apple-touch-icon.png].each do |icon|
      assert Rails.public_path.join(icon).exist?, "#{icon} is missing"
    end
  end
end
