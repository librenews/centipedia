class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :canonical_url, null: false
      t.references :domain, null: false, foreign_key: true
      t.decimal :url_base_score, precision: 5, scale: 2
      t.string :content_hash
      t.string :status, default: "pending", null: false

      t.timestamps
    end
    add_index :sources, :canonical_url, unique: true
  end
end
