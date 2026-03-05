class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :topic, null: false, foreign_key: true
      t.jsonb :content, null: false, default: []
      t.string :rubric_version, null: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
  end
end
