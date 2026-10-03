class CreateTrackPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :track_points do |t|
      t.references :walk, null: false, foreign_key: true
      t.decimal :latitude, precision: 9, scale: 6, null: false
      t.decimal :longitude, precision: 9, scale: 6, null: false
      t.float :accuracy
      t.datetime :recorded_at, null: false

      t.timestamps
    end
    add_index :track_points, [ :walk_id, :recorded_at ]
  end
end
