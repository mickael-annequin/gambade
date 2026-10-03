class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :walk, null: false, foreign_key: true
      t.string :kind, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6

      t.timestamps
    end
  end
end
