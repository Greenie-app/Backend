# @private
class RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def create
    super { |squadron| @squadron = squadron } # render the JSON view
  end
end
