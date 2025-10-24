# frozen_string_literal: true

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
  rescue ActionDispatch::Http::Parameters::ParseError => e
    # Handle oversized upload errors gracefully
    if e.message.include?('exceeded') || e.message.include?('limit')
      render json: { errors: { files: ['File size exceeds maximum limit of 10MB'] } }, status: :unprocessable_entity
    else
      raise
    end
  end

  private

  def logfile_params = params.expect(logfile: [files: []])
end
