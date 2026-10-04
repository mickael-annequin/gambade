# Fetches the weather of a walk in the background, so the page doesn't wait for Open-Meteo.
class WalkWeatherJob < ApplicationJob
  def perform(walk)
    walk.fetch_weather!
  end
end
