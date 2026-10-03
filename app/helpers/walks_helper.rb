module WalksHelper
  # 2100 -> "35 min", 3900 -> "1 h 05"
  def walk_duration(seconds)
    minutes = seconds / 60
    return "#{minutes} min" if minutes < 60

    format("%d h %02d", minutes / 60, minutes % 60)
  end

  # 2300 -> "2,3 km"
  def walk_distance(meters)
    "#{number_with_precision(meters / 1000.0, precision: 1, separator: ',')} km"
  end

  # "Aujourd'hui", "Hier" or "mardi 29 septembre"
  def walk_day(time)
    date = time.to_date
    return "Aujourd'hui" if date == Date.current
    return "Hier" if date == Date.yesterday

    l(date, format: "%A %-d %B")
  end

  # "Octobre 2026"
  def walk_month(date)
    l(date, format: "%B %Y").capitalize
  end
end
