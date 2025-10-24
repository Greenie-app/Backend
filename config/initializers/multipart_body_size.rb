# frozen_string_literal: true

# Increase the multipart body size limit for file uploads
# Default is 128KB, we're increasing to 10MB to support larger image uploads
Rails.application.config.action_dispatch.default_body_size_limit = 10.megabytes
