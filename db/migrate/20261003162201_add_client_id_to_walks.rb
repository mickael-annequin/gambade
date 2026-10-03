class AddClientIdToWalks < ActiveRecord::Migration[8.1]
  def change
    # Unique id given by the phone when a tracked walk starts: sending the same walk twice
    # (e.g. "Réessayer" after a lost answer) must not create a duplicate.
    add_column :walks, :client_id, :string
    add_index :walks, :client_id, unique: true
  end
end
