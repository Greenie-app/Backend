# RESTful API controller for working with {Pass}es.

class PassesController < ApplicationController
  before_action :authenticate_squadron!, except: %w[index show]
  before_action :find_squadron, except: %i[create update destroy unknown]
  before_action :set_squadron, only: %i[create update destroy unknown]
  before_action :find_pass, except: %i[index create unknown]

  # Lists a Squadron's passes.
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

  def index
    @passes = @squadron.passes.includes(:pilot).order(time: :desc)
    @passes = paginate(@passes)

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

  def show
    respond_with @pass
  end

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
                                                               boarding_rate:      @squadron.boarding_rate,
                                                               unknown_pass_count: @squadron.unknown_pass_count)
      end
    end

    render json: {ok: true}
  end

  private

  def find_squadron
    @squadron = Squadron.find_by_username!(params[:squadron_id])
  end

  def set_squadron
    @squadron = current_squadron
  end

  def find_pass
    @pass = @squadron.passes.find(params[:id])
  end

  def pass_params
    pass_params = params.require(:pass).permit(:time, :ship_name,
                                               :aircraft_type, :grade, :score,
                                               :trap, :wire, :notes, :pilot)

    if (name = pass_params[:pilot]).present?
      pass_params[:pilot_id] = @squadron.pilots.find_or_create_by!(name: name).id
    end
    pass_params.delete 'pilot'

    return pass_params
  end
end
