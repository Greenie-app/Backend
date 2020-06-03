# RESTful API controller for working with {Logfile}s.

class LogfilesController < ApplicationController
  before_action :authenticate_squadron!

  # Loads the un-finished logfile uploads for the current {Squadron}.
  #
  # Routes
  # ------
  #
  # * `GET /squadron/logfiles`

  def index
    @logfiles = current_squadron.logfiles.order(created_at: :desc)
    @logfiles = paginate(@logfiles)

    respond_with @logfiles
  end

  # Uploads a new dcs.log and creates a Logfile.
  #
  # Routes
  # ------
  #
  # * `POST /squadron/logfiles`
  #
  # Body Parameters
  # ---------------
  #
  # | `logfile[files][]` | One or more multipart logfiles to upload. |

  def create
    @logfile = current_squadron.logfiles.create(logfile_params)
    respond_with @logfile
  end

  private

  def logfile_params
    params.require(:logfile).permit(files: [])
  end
end
