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
