# @private
class SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts={})
    @squadron = resource
    render 'squadrons/show'
  end

  def respond_to_on_destroy
    head :no_content
  end
end
