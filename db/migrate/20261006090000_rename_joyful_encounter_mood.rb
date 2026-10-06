# The encounter moods become "joueur / cordial / neutre / tendu": the old "joyful" becomes "playful".
class RenameJoyfulEncounterMood < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE encounters SET mood = 'playful' WHERE mood = 'joyful'"
  end

  def down
    execute "UPDATE encounters SET mood = 'joyful' WHERE mood IN ('playful', 'friendly')"
  end
end
