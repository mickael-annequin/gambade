module EncountersHelper
  MOODS = { "joyful" => "😊 joueurs", "neutral" => "😐 neutre", "tense" => "😠 tendu" }.freeze

  # "Filou, Beagle 😊", or nil when no detail was filled in
  def encounter_details(encounter)
    text = [ encounter.dog_name, encounter.breed ].compact_blank.join(", ")
    mood = MOODS[encounter.mood]&.split&.first
    [ text.presence, mood ].compact.join(" ").presence
  end
end
