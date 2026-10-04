class CreateWeighings < ActiveRecord::Migration[8.1]
  def change
    create_table :weighings do |t|
      t.references :dog, null: false, foreign_key: true
      t.date :measured_on, null: false
      t.decimal :weight_kg, precision: 4, scale: 1, null: false

      t.timestamps
    end
    add_index :weighings, %i[dog_id measured_on]
  end
end
