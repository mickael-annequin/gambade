class CreateCares < ActiveRecord::Migration[8.1]
  def change
    create_table :cares do |t|
      t.references :dog, null: false, foreign_key: true
      t.string :kind, null: false
      t.date :given_on, null: false
      t.date :next_due_on
      t.string :product
      t.text :note

      t.timestamps
    end
    add_index :cares, %i[dog_id kind given_on]
  end
end
