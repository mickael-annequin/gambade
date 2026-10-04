class AddNotesToWalks < ActiveRecord::Migration[8.1]
  def change
    # How the dog was during the walk (several choices, see Walk::MOODS) and a free comment.
    add_column :walks, :moods, :string, array: true, default: [], null: false
    add_column :walks, :comment, :text
  end
end
