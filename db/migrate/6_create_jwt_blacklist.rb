# frozen_string_literal: true

class CreateJWTBlacklist < ActiveRecord::Migration[6.0]
  def change
    create_table :jwt_blacklist do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
    end

    add_index :jwt_blacklist, :jti
  end
end
