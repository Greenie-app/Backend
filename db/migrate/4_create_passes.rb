class CreatePasses < ActiveRecord::Migration[6.0]
  def change
    create_table :passes do |t|
      t.belongs_to :squadron, null: false, foreign_key: {on_delete: :cascade}
      t.belongs_to :pilot, null: true, foreign_key: {on_delete: :cascade}
      t.datetime :time, null: false

      t.string :ship_name
      t.string :aircraft_type

      t.integer :grade, null: false, size: 1
      t.decimal :score, precision: 2, scale: 1
      t.boolean :trap
      t.integer :wire, size: 1

      t.string :notes
    end
  end
end
