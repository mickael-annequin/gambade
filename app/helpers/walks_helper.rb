module WalksHelper
  # Small picture of the walk's track (Mapbox Static Images API), or nil without a GPS track.
  # A picture is much lighter than an interactive map when the list shows many walks.
  def walk_map_image_url(walk, size: 120)
    track = walk.simplified_track
    return if track.size < 2

    path = "path-4+E08E45(#{ERB::Util.url_encode(Polyline.encode(track))})"
    "https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/#{path}/auto/#{size}x#{size}@2x" \
      "?padding=12&access_token=#{ENV['MAPBOX_API_KEY']}"
  end

  # Map markers for the photos placed on the track: a small round thumbnail; tapping it opens the photo viewer.
  def walk_photo_markers(walk)
    walk.photos.with_attached_image.where.not(latitude: nil).order(:taken_at).map do |photo|
      { id: photo.id,
        thumbnail: cl_image_path(photo.image.key, width: 96, height: 96, crop: :fill, gravity: :auto),
        coordinates: [ photo.longitude.to_f, photo.latitude.to_f ] }
    end
  end

  # The photos for the full-screen viewer (photo_viewer_controller.js), in the gallery order.
  def walk_photo_viewer_items(walk, photos)
    photos.map do |photo|
      { id: photo.id,
        image: cl_image_path(photo.image.key, width: 1600, height: 1600, crop: :limit, quality: :auto, fetch_format: :auto),
        time: photo.taken_at ? "📷 #{photo.taken_at.strftime('%Hh%M')}" : "📷 Heure inconnue",
        delete_url: walk_photo_path(walk, photo) }
    end
  end

  # The tracks for the global map (walks_map_controller.js), each with a label, a link to its walk, and cut
  # into pieces colored by how many walks went there: [{ passes: 3, track: [[lng, lat], ...] }, ...]
  def walks_map_items(walks)
    frequency = PathFrequency.new(walks)
    walks.filter_map do |walk|
      track = walk.simplified_track(max_points: 150)
      next if track.size < 2

      { url: walk_path(walk), label: "#{walk_day(walk.started_at)} · #{walk_distance(walk.distance_meters)}",
        pieces: frequency.pieces(track) }
    end
  end

  # "☀️ Ensoleillé · 18 °C · vent 12 km/h · 0,4 mm de pluie", or nil when the weather is not known.
  def walk_weather(walk)
    return if walk.weather_label.nil?

    parts = [ walk.weather_label, "#{number_with_precision(walk.temperature_celsius, precision: 0)} °C",
              "vent #{walk.wind_kmh} km/h" ]
    if walk.precipitation_mm.to_f.positive?
      parts << "#{number_with_precision(walk.precipitation_mm, precision: 1, separator: ',')} mm de pluie"
    end
    parts.join(" · ")
  end

  # "☀️ 18°" for the walk cards, or nil.
  def walk_weather_short(walk)
    return if walk.weather_label.nil?

    "#{walk.weather_label.split.first} #{number_with_precision(walk.temperature_celsius, precision: 0)}°"
  end

  # Short label of a day, a week or a month on the stats charts: "lun 6", "29 sept." (week of the 29th), "oct." (month).
  def stats_label(start, period)
    case period
    when "day" then l(start, format: "%a %-d")
    when "week" then l(start, format: "%-d %b")
    else l(start, format: "%b")
    end
  end

  # 2100 -> "35 min", 3900 -> "1 h 05", 20 -> "< 1 min"
  def walk_duration(seconds)
    return "< 1 min" if seconds.between?(1, 59)

    minutes = seconds / 60
    return "#{minutes} min" if minutes < 60

    format("%d h %02d", minutes / 60, minutes % 60)
  end

  # 2300 -> "2,3 km"
  def walk_distance(meters)
    "#{walk_km(meters)} km"
  end

  # 2300 -> "2,3"
  def walk_km(meters)
    number_with_precision(meters / 1000.0, precision: 1, separator: ",")
  end

  # "Aujourd'hui", "Hier" or "mardi 29 septembre"
  def walk_day(time)
    date = time.to_date
    return "Aujourd'hui" if date == Date.current
    return "Hier" if date == Date.yesterday

    l(date, format: "%A %-d %B")
  end

  # "🎾 12 min de jeu", or nil without play
  def walk_play_summary(walk)
    plays = walk.activities.select(&:play?)
    return if plays.empty?

    "🎾 #{walk_duration(plays.sum(&:duration_seconds))} de jeu"
  end

  # "💦 1 baignade (8 min)", or nil without swim
  def walk_swim_summary(walk)
    swims = walk.activities.select(&:swim?)
    return if swims.empty?

    "💦 #{pluralize(swims.size, 'baignade', plural: 'baignades')} (#{walk_duration(swims.sum(&:duration_seconds))})"
  end

  # ["⚡ Plein d'énergie", "😤 Chiant"]
  def walk_mood_labels(walk)
    walk.moods.filter_map { |mood| Walk::MOODS[mood] }
  end

  # "⚡😤" (just the emojis, for the walk cards)
  def walk_mood_emojis(walk)
    walk_mood_labels(walk).map { |label| label.split.first }.join
  end

  # "croisé 12 fois · dernière fois hier"
  def friend_meetings(count, last_met_at)
    return "pas encore croisé" if count.zero?

    "croisé #{count} fois · dernière fois #{walk_day(last_met_at).downcase_first}"
  end

  # "Octobre 2026"
  def walk_month(date)
    l(date, format: "%B %Y").capitalize
  end
end
