class CreatePilots < ActiveRecord::Migration[6.0]
  def change
    create_table :pilots do |t|
      t.belongs_to :squadron, null: false, foreign_key: {on_delete: :cascade}
      t.string :name, null: false
    end

    add_index :pilots, %i[squadron_id name], unique: true
  end
end
