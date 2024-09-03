# frozen_string_literal: true

class FixAdminColumn < ActiveRecord::Migration[7.2]
  def change
    change_column_null :squadrons, :admin, false
  end
end
