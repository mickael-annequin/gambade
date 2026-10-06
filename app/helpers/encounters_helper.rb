module EncountersHelper
  MOODS = { "playful" => "😄 joueur", "friendly" => "🙂 cordial", "neutral" => "😐 neutre", "tense" => "😠 tendu" }.freeze

  # "Filou, Beagle 😊", or nil when no detail was filled in
  def encounter_details(encounter)
    text = [ encounter.display_name, encounter.display_breed ].compact_blank.join(", ")
    mood = MOODS[encounter.mood]&.split&.first
    [ text.presence, mood ].compact.join(" ").presence
  end
end
