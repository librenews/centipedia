class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.string :host, null: false
      t.decimal :reputation_modifier, precision: 5, scale: 2, default: 1.0, null: false

      t.timestamps
    end
    add_index :domains, :host, unique: true
  end
end
