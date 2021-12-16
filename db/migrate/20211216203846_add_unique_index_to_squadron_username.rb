class AddUniqueIndexToSquadronUsername < ActiveRecord::Migration[6.1]
  def change
    add_index :squadrons, :username, unique: true
  end
end
