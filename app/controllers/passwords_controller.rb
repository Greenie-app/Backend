# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  private

  def sign_in(resource_or_scope, *args)
    options = args.extract_options!
    super resource_or_scope, *args, options.merge(store: false)
  end
end
