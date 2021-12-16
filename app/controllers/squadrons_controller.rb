# RESTful API controller for working with {Squadron}s, either the current user's
# squadron or a squadron referenced by username.

class SquadronsController < ApplicationController
  before_action :authenticate_squadron!, except: :show
  before_action :find_squadron, except: :update
  before_action :set_squadron, only: :update

  # Renders information about a squadron.
  #
  # Routes
  # ------
  #
  # * `GET /squadrons/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | A Squadron username. |

  def show
    respond_with @squadron
  end

  # Updates the current user's squadron data.
  #
  # Routes
  # ------
  #
  # * `PATCH /squadron`
  # * `PUT /squadron`
  #
  # Body Parameters
  # ---------------
  #
  # | squadron | Parameterized hash of Squadron attributes. |

  def update
    @squadron.update(squadron_params)
    respond_with @squadron
  end

  private

  def find_squadron
    @squadron = Squadron.find_by!(username: params[:id])
  end

  def set_squadron
    @squadron = current_squadron
  end

  def squadron_params
    params.require(:squadron).permit :name, :username, :email, :image
  end
end
