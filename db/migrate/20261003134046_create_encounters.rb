class CreateEncounters < ActiveRecord::Migration[8.1]
  def change
    create_table :encounters do |t|
      t.references :walk, null: false, foreign_key: true
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.datetime :met_at, null: false
      t.string :dog_name
      t.string :breed
      t.string :mood
      t.text :note

      t.timestamps
    end
    add_index :encounters, [ :walk_id, :met_at ]
  end
end
