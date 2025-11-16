# frozen_string_literal: true

# RESTful API controller for working with {Pass}es.

class PassesController < ApplicationController
  before_action :authenticate_squadron!, except: %w[index show]
  before_action :find_squadron, except: %i[create update destroy unknown]
  before_action :set_squadron, only: %i[create update destroy unknown]
  before_action :find_pass, except: %i[index create unknown]

  # Lists a Squadron's passes within a date range.
  #
  # Routes
  # ------
  #
  # * `GET /squadrons/:squadron_id/passes`
  #
  # Path Parameters
  # ---------------
  #
  # | `squadron_id` | The username of a {Squadron}. |
  #
  # Query Parameters
  # ----------------
  #
  # | `start_date` | The start date for filtering passes (optional, ISO 8601 format). |
  # | `end_date` | The end date for filtering passes (optional, ISO 8601 format). |

  def index
    @passes = @squadron.passes.includes(:pilot)

    # Date filtering is required
    unless params[:start_date].present? && params[:end_date].present?
      render json: {error: "start_date and end_date parameters are required"}, status: :bad_request
      return
    end

    return unless valid_date_params?

    start_date = Time.zone.parse(params[:start_date]).beginning_of_day
    end_date = Time.zone.parse(params[:end_date]).end_of_day
    @passes = @passes.where(time: start_date..end_date)
    @boarding_rate = @squadron.boarding_rate(start_date: start_date, end_date: end_date)

    @passes = @passes.order(time: :desc)
    respond_with @passes
  end

  # Renders a single Pass.
  #
  # Routes
  # ------
  #
  # * `GET /squadrons/:squadron_id/passes/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `squadron_id` | The username of a {Squadron}. |
  # | `id` | The ID of a {Pass}. |

  def show = respond_with @pass

  # Creates a new Pass for the Squadron associated with the request JWT.
  #
  # Routes
  # ------
  #
  # * `POST /squadron/passes`
  #
  # Body Parameters
  # ---------------
  #
  # | `pass` | A parameterized hash of Pass attributes. |

  def create
    Pilot.transaction do
      @pass = @squadron.passes.create(pass_params)
    end

    respond_with @pass
  end

  # Updates a Pass belonging to the Squadron associated with the request JWT.
  #
  # Routes
  # ------
  #
  # * `PUT /squadron/passes/:id`
  # * `PATCH /squadron/passes/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | The ID of a {Pass}. |
  #
  # Body Parameters
  # ---------------
  #
  # | `pass` | A parameterized hash of Pass attributes. |

  def update
    Pilot.transaction do
      @pass.update pass_params
    end

    respond_with @pass
  end

  # Deletes a Pass belonging to the Squadron associated with the request JWT.
  #
  # Routes
  # ------
  #
  # * `DELETE /squadron/passes/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | The ID of a {Pass}. |

  def destroy
    @pass.destroy
    respond_with @pass
  end

  # Deletes all Passes belonging to the Squadron associated with the request JWT
  # that have no associated pilot.
  #
  # Routes
  # ------
  #
  # * `DELETE /squadron/passes/unknown`

  def unknown
    @squadron.passes.where(pilot_id: nil).find_in_batches do |batch|
      ids = batch.map(&:id)
      @squadron.passes.
          where(pilot_id: nil, id: ids.min..ids.max).
          delete_all

      batch.each do |pass|
        pass.instance_variable_set :@destroyed, true
        PassesChannel.broadcast_to @squadron,
                                   PassesChannel::Coder.encode(pass,
                                                               unknown_pass_count: @squadron.unknown_pass_count)
      end
    end

    render json: {ok: true}
  end

  private

  def find_squadron
    @squadron = Squadron.find_by!(username: params[:squadron_id])
  end

  def set_squadron
    @squadron = current_squadron
  end

  def find_pass
    @pass = @squadron.passes.find(params[:id])
  end

  def pass_params
    pass_params = params.expect(pass: %i[time ship_name
                                         aircraft_type grade score
                                         trap wire notes pilot])

    if (name = pass_params[:pilot]).present?
      pass_params[:pilot_id] = @squadron.pilots.find_or_create_by!(name:).id
    end
    pass_params.delete "pilot"

    return pass_params
  end

  def valid_date_params?
    begin
      parsed_start = Time.zone.parse(params[:start_date])
      parsed_end = Time.zone.parse(params[:end_date])

      if parsed_start.nil? || parsed_end.nil?
        render json: {error: "Invalid date format"}, status: :bad_request
        return false
      end
    rescue ArgumentError => e
      render json: {error: "Invalid date format: #{e.message}"}, status: :bad_request
      return false
    end

    true
  end
end
