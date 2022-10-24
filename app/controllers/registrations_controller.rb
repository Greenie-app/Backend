# frozen_string_literal: true

# @private
class RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def create
    super { |squadron| @squadron = squadron } # render the JSON view
  end

  private

  def sign_up(resource_name, resource)
    sign_in(resource_name, resource, store: false)
  end

  def bypass_sign_in(resource, scope: nil)
    # do nothing, no sessions
  end
end
