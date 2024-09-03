# frozen_string_literal: true

class AddAdminToSquadrons < ActiveRecord::Migration[7.2]
  def change
    add_column :squadrons, :admin, :boolean, default: false
  end
end
