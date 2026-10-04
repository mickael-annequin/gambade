class CreateFriends < ActiveRecord::Migration[8.1]
  def change
    create_table :friends do |t|
      t.references :dog, null: false, foreign_key: true
      t.string :name, null: false
      t.string :breed
      t.text :note

      t.timestamps
    end
  end
end
