class CreateWalkPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :walk_photos do |t|
      t.references :walk, null: false, foreign_key: true
      t.datetime :taken_at
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6

      t.timestamps
    end
  end
end
