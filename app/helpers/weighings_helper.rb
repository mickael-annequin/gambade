module WeighingsHelper
  # 24.3 -> "24,3 kg"
  def weight(kg)
    "#{number_with_precision(kg, precision: 1, separator: ',')} kg"
  end

  # Change since the previous weighing: "+0,4 kg", "−1,2 kg", "=" (same weight), or nil for the first one.
  def weight_change(weighing, previous)
    return if previous.nil?

    change = weighing.weight_kg - previous.weight_kg
    return "=" if change.zero?

    "#{change.positive? ? '+' : '−'}#{weight(change.abs)}"
  end
end
