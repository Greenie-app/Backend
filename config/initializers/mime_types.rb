# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register "application/sql", :sql
Mime::Type.register "application/x-sqlite3", :sql
Mime::Type.register "application/vnd.sqlite3", :sql
