class CreateLogfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :logfiles do |t|
      t.belongs_to :squadron, null: false, foreign_key: {on_delete: :cascade}
      t.integer :completed_files, null: false, default: 0
      t.integer :failed_files, null: false, default: 0
      t.integer :state, null: false, default: 0, size: 1

      t.timestamps
    end
  end
end
