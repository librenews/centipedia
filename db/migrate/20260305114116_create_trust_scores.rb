class CreateTrustScores < ActiveRecord::Migration[8.1]
  def change
    create_table :trust_scores do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :citation_event, null: true, foreign_key: true
      t.decimal :score_change, precision: 5, scale: 2, null: false
      t.text :reason, null: false

      t.timestamps
    end
  end
end
