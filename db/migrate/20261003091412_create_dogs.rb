class CreateDogs < ActiveRecord::Migration[8.1]
  def change
    create_table :dogs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :breed
      t.date :birth_date

      t.timestamps
    end
  end
end
