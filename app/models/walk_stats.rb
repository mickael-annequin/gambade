# Walks added up per week or per month, for the stats page (the last 12 weeks or 12 months, oldest first).
# Periods without walks are kept (at 0), so the charts show the gaps too.
class WalkStats
  PERIODS = %w[week month].freeze
  COUNT = 12

  attr_reader :period, :buckets

  def initialize(walks, period:)
    @period = PERIODS.include?(period) ? period : "week"
    starts = (0...COUNT).map { |ago| start_of(Date.current - ago.public_send(@period)) }.reverse
    by_start = walks.where(started_at: starts.first.beginning_of_day..).group_by { |walk| start_of(walk.started_at.to_date) }
    @buckets = starts.map { |start| bucket(start, by_start.fetch(start, [])) }
  end

  # Totals of the 12 weeks or months.
  def total(key)
    buckets.sum { |bucket| bucket[key] }
  end

  private

  def start_of(date)
    period == "week" ? date.beginning_of_week : date.beginning_of_month
  end

  def bucket(start, walks)
    { start: start, walks: walks.size, km: (walks.sum(&:distance_meters) / 1000.0).round(1),
      minutes: walks.sum(&:duration_seconds) / 60, dogs: walks.sum(&:dogs_met_count) }
  end
end
