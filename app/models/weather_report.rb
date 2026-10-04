require "net/http"

# The weather during a walk, from Open-Meteo (free, no account or API key: https://open-meteo.com).
# Only a rounded position (~1 km) is sent: enough for the weather, without telling exactly where we walk.
class WeatherReport
  FORECAST_URL = "https://api.open-meteo.com/v1/forecast"   # the last months
  ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive" # older walks
  RECENT_DAYS = 80
  HOURLY = "temperature_2m,weather_code,precipitation,wind_speed_10m"

  # How the weather is downloaded (replaced by a fake one in the tests, to stay offline).
  class_attribute :download, default: ->(uri) { Net::HTTP.get(uri) }

  # { weather_code: 3, temperature_celsius: 14.2, precipitation_mm: 0.0, wind_kmh: 12 }, or nil.
  def self.for(latitude:, longitude:, time:)
    time = time.in_time_zone("Europe/Paris")
    uri = URI(time.to_date >= RECENT_DAYS.days.ago.to_date ? FORECAST_URL : ARCHIVE_URL)
    uri.query = URI.encode_www_form(
      latitude: latitude.to_f.round(2), longitude: longitude.to_f.round(2), hourly: HOURLY,
      start_date: time.to_date.iso8601, end_date: time.to_date.iso8601, timezone: "Europe/Paris"
    )
    parse(download.call(uri), hour: time.hour)
  rescue StandardError => error # no network, service down…: the walk simply has no weather
    Rails.logger.warn("Weather not found: #{error.message}")
    nil
  end

  # Picks the hour of the walk in Open-Meteo's answer (one value per hour of the day).
  def self.parse(json, hour:)
    hourly = JSON.parse(json).fetch("hourly")
    index = hourly.fetch("time").index { |time| time.end_with?("T#{format('%02d', hour)}:00") }
    return if index.nil? || hourly.dig("weather_code", index).nil?

    { weather_code: hourly["weather_code"][index], temperature_celsius: hourly["temperature_2m"][index],
      precipitation_mm: hourly["precipitation"][index], wind_kmh: hourly["wind_speed_10m"][index]&.round }
  end
end
