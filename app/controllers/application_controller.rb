# @abstract
#
# Abstract superclass for Greenie controllers. All responses are JSON. Typical
# responses:
#
# ## Record not found
#
# The response will be a 404 Not Found.
#
# ## Unauthorized
#
# The response will be a 401 Unauthorized.
#
# ## Record failed validation
#
# The response will be a 422 Unprocessable Entity. The response body will be
# a dictionary mapping fields to an array of errors.

class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  # Default per-page value for {#paginate}.
  DEFAULT_PER_PAGE = 10

  # Max per-page value for {#paginate}.
  MAX_PER_PAGE = 200

  before_bugsnag_notify :add_user_info_to_bugsnag
  before_action :configure_permitted_parameters, if: :devise_controller?

  respond_to :json

  rescue_from(ActiveRecord::RecordNotFound) do |err|
    respond_to do |format|
      format.json { render json: {error: err.to_s}, status: :not_found }
      format.any { head :not_found }
    end
  end

  protected

  # Paginates records for use with the Bootstrap-Vue `b-pagination` component.
  # Constrains the response cardinality according to the query parameters:
  #
  # | `page` | The page to load records for (1-based, defaults to 1). |
  # | `per_page` | The number of records per page (defaults to 50, max 100). |
  #
  # Adds the following headers to the response:
  #
  # | `X-Page` | The actual page loaded. |
  # | `X-Per-Page` | The actual number of records per page. |
  # | `X-Count` | The total number of records. |
  #
  # @param [ActiveRecord::Relation] scope The Active Record scope to paginate.
  # @param [ActiveRecord::Relation] count_scope The Active Record scope to use
  #   when getting the total count of records.

  def paginate(scope, count_scope=scope)
    @page = params[:page].presence&.to_i || 1
    @page = 1 if @page < 1

    @per_page = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
    @per_page = MAX_PER_PAGE if @per_page > MAX_PER_PAGE
    @per_page = 1 if @per_page < 1

    @count    = count_scope.count

    response.headers['X-Page']      = @page.to_s
    response.headers['X-Per-Page']  = @per_page.to_s
    response.headers['X-Count']     = @count.to_s

    return scope.offset(@per_page * (@page - 1)).limit(@per_page)
  end

  private

  def add_user_info_to_bugsnag(report)
    report.user = {
        id:   current_squadron.id,
        name: current_squadron.username
    } if squadron_signed_in?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name image email])
  end
end
