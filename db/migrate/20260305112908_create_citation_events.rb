class CreateCitationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :citation_events do |t|
      t.references :source, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.decimal :url_base_score, precision: 5, scale: 2, null: false
      t.decimal :domain_multiplier, precision: 5, scale: 2, null: false
      t.decimal :corroboration_multiplier, precision: 5, scale: 2, null: false
      t.decimal :total_weight, precision: 8, scale: 2, null: false
      t.string :rubric_version, null: false

      t.timestamps
    end
  end
end
