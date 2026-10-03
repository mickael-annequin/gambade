module EncountersHelper
  MOODS = { "joyful" => "😊 joueurs", "neutral" => "😐 neutre", "tense" => "😠 tendu" }.freeze

  # 1 -> "①" … 20 -> "⑳", then "(21)"
  def encounter_number(number)
    number <= 20 ? (0x2460 + number - 1).chr(Encoding::UTF_8) : "(#{number})"
  end

  # "Filou, Beagle 😊", or nil when no detail was filled in
  def encounter_details(encounter)
    text = [ encounter.dog_name, encounter.breed ].compact_blank.join(", ")
    mood = MOODS[encounter.mood]&.split&.first
    [ text.presence, mood ].compact.join(" ").presence
  end
end
