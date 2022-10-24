# frozen_string_literal: true

class DeviseCreateSquadrons < ActiveRecord::Migration[6.0]
  def change
    create_table :squadrons do |t|
      t.string :name, null: false
      t.string :username, null: false

      ## Database authenticatable
      t.string :email, null: false
      t.string :encrypted_password, null: false

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :squadrons, :email, unique: true
    add_index :squadrons, :reset_password_token, unique: true
  end
end
