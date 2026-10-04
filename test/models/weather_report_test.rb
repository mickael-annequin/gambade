require "test_helper"

class WeatherReportTest < ActiveSupport::TestCase
  # What Open-Meteo answers (shortened: 3 hours instead of 24).
  ANSWER = {
    hourly: {
      time: [ "2026-10-01T17:00", "2026-10-01T18:00", "2026-10-01T19:00" ],
      temperature_2m: [ 16.1, 15.4, 14.0 ],
      weather_code: [ 2, 61, 3 ],
      precipitation: [ 0.0, 0.4, 0.0 ],
      wind_speed_10m: [ 9.8, 12.3, 10.0 ]
    }
  }.to_json

  setup do
    @asked = []
    WeatherReport.download = ->(uri) { @asked << uri; ANSWER }
  end

  teardown do
    WeatherReport.download = ->(uri) { Net::HTTP.get(uri) }
  end

  test "gives the weather at the hour of the walk" do
    report = WeatherReport.for(latitude: 48.4206, longitude: 1.5012, time: Time.zone.parse("2026-10-01 18:22"))
    assert_equal({ weather_code: 61, temperature_celsius: 15.4, precipitation_mm: 0.4, wind_kmh: 12 }, report)
  end

  test "only sends a rounded position (~1 km), and asks the archive for old walks" do
    travel_to Time.zone.parse("2026-10-04 12:00") do
      WeatherReport.for(latitude: 48.4206, longitude: 1.5012, time: Time.zone.parse("2026-10-01 18:22"))
      WeatherReport.for(latitude: 48.4206, longitude: 1.5012, time: Time.zone.parse("2026-03-01 18:22"))
    end
    recent, old = @asked
    assert_equal "api.open-meteo.com", recent.host
    assert_equal "archive-api.open-meteo.com", old.host
    assert_includes recent.query, "latitude=48.42&longitude=1.5&"
    assert_includes recent.query, "start_date=2026-10-01"
  end

  test "no weather when Open-Meteo doesn't answer" do
    WeatherReport.download = ->(_uri) { raise SocketError, "no network" }
    assert_nil WeatherReport.for(latitude: 48.42, longitude: 1.5, time: Time.current)
  end

  test "a walk saves its weather, in the middle of the walk" do
    walk = walks(:evening) # 18h05 → 18h40: the 18h hour
    walk.fetch_weather!
    assert_equal [ 61, 15.4, 0.4, 12 ], walk.reload.values_at(:weather_code, :temperature_celsius, :precipitation_mm, :wind_kmh)
    assert_equal "🌧️ Pluie", walk.weather_label
  end
end
