# RESTful API controller for working with {Pilot}s. Pilots are always queried by
# their `name`, not their database ID.

class PilotsController < ApplicationController
  before_action :authenticate_squadron!
  before_action :find_pilot

  # Merges two pilots. Transfers all {Pass}es from the "prey" to the "predator",
  # and then deletes the "prey".
  #
  # Routes
  # ------
  #
  # * POST `/squadron/pilots/:id/merge`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | The name of the "predator". |
  #
  # Query Parameters
  # ----------------
  #
  # | `other` | The name of the "prey". |

  def merge
    prey = current_squadron.pilots.find_by!(name: params[:other])
    prey.passes.update_all pilot_id: @pilot.id
    prey.destroy!

    respond_with @pilot
  end

  # Renames a pilot.
  #
  # Routes
  # ------
  #
  # * PATCH `/squadron/pilots/:id`
  # * PUT `/squadron/pilots/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | The name of the {Pilot}. |
  #
  # Body Parameters
  # ---------------
  #
  # | `pilot[name]` | The new name for the pilot. |

  def update
    @pilot.update pilot_params
    respond_with @pilot
  end

  # Deletes a pilot and all their Passes.
  #
  # Routes
  # ------
  #
  # * DELETE `/squadron/pilots/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `id` | The name of the {Pilot}. |

  def destroy
    @pilot.destroy
    respond_with @pilot
  end

  private

  def find_pilot
    @pilot = current_squadron.pilots.find_by!(name: params[:id])
  end

  def pilot_params
    params.require(:pilot).permit(:name)
  end
end
