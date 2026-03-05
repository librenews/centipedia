class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.text :description
      t.string :slug, null: false

      t.timestamps
    end
    add_index :topics, :slug, unique: true
  end
end
