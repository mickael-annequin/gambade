class CreateWalks < ActiveRecord::Migration[8.1]
  def change
    create_table :walks do |t|
      t.references :dog, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.integer :duration_seconds, null: false
      t.integer :distance_meters, null: false, default: 0
      t.integer :dogs_met_count, null: false, default: 0
      t.boolean :tracked, null: false, default: false

      t.timestamps
    end
    add_index :walks, [ :dog_id, :started_at ]
  end
end
