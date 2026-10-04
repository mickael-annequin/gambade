class AddWeatherToWalks < ActiveRecord::Migration[8.1]
  def change
    add_column :walks, :weather_code, :integer
    add_column :walks, :temperature_celsius, :decimal, precision: 4, scale: 1
    add_column :walks, :precipitation_mm, :decimal, precision: 5, scale: 1
    add_column :walks, :wind_kmh, :integer
  end
end
