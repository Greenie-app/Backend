# frozen_string_literal: true

server "app.greenie.app",
       user:  "deploy",
       roles: %w[app db web]
