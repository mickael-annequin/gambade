# Walks added up per day, week or month, for the stats page (the last 14 days, 12 weeks or 12 months, oldest first).
# Periods without walks are kept (at 0), so the charts show the gaps too.
class WalkStats
  COUNTS = { "day" => 14, "week" => 12, "month" => 12 }.freeze

  attr_reader :period, :buckets

  def initialize(walks, period:)
    @period = COUNTS.key?(period) ? period : "week"
    starts = (0...count).map { |ago| start_of(Date.current - ago.public_send(@period)) }.reverse
    by_start = walks.where(started_at: starts.first.beginning_of_day..).group_by { |walk| start_of(walk.started_at.to_date) }
    @buckets = starts.map { |start| bucket(start, by_start.fetch(start, [])) }
  end

  # How many days, weeks or months are shown.
  def count
    COUNTS[period]
  end

  # Totals of the shown days, weeks or months.
  def total(key)
    buckets.sum { |bucket| bucket[key] }
  end

  private

  def start_of(date)
    case period
    when "day" then date
    when "week" then date.beginning_of_week
    else date.beginning_of_month
    end
  end

  def bucket(start, walks)
    { start: start, walks: walks.size, km: (walks.sum(&:distance_meters) / 1000.0).round(1),
      minutes: walks.sum(&:duration_seconds) / 60, dogs: walks.sum(&:dogs_met_count) }
  end
end
