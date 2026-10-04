module CaresHelper
  SOON_DAYS = 7

  # "✅ Prochain le 12 janv. (dans 23 jours)", "⚠️ … (dans 3 jours)", "🔴 En retard de 5 jours", or nil.
  def care_status(care)
    days = care.days_left
    return if days.nil?
    return "🔴 En retard de #{pluralize(-days, 'jour')}" if days.negative?
    return "⚠️ À faire aujourd'hui" if days.zero?

    icon = days <= SOON_DAYS ? "⚠️" : "✅"
    "#{icon} Prochain le #{l(care.next_due_on, format: '%-d %b %Y')} (dans #{pluralize(days, 'jour')})"
  end

  # Soon or late: shown in ochre/red (and on the home page, see step 2).
  def care_status_class(care)
    days = care.days_left
    return "" if days.nil? || days > SOON_DAYS

    days.negative? ? "care-status-late" : "care-status-soon"
  end
end
