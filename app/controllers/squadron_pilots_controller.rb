# frozen_string_literal: true

# Public API controller for viewing Pilot data. This is separate from PilotsController
# which handles authenticated actions.

class SquadronPilotsController < ApplicationController
  before_action :find_squadron
  before_action :find_pilot

  # Shows a pilot's passes and error statistics within a date range.
  #
  # Routes
  # ------
  #
  # * `GET /squadrons/:squadron_id/pilots/:id`
  #
  # Path Parameters
  # ---------------
  #
  # | `squadron_id` | The username of a {Squadron}. |
  # | `id` | The name of the {Pilot}. |
  #
  # Query Parameters
  # ----------------
  #
  # | `start_date` | The start date for filtering passes (required, ISO 8601 format). |
  # | `end_date` | The end date for filtering passes (required, ISO 8601 format). |

  def show
    unless params[:start_date].present? && params[:end_date].present?
      render json: {error: "start_date and end_date parameters are required"}, status: :bad_request
      return
    end

    return unless valid_date_params?

    start_date = Time.zone.parse(params[:start_date]).beginning_of_day
    end_date = Time.zone.parse(params[:end_date]).end_of_day

    @passes = @pilot.passes.where(time: start_date..end_date).order(time: :desc)
    @boarding_rate = calculate_boarding_rate(@passes)
    @error_statistics = calculate_error_statistics(@passes)
    @error_statistics_by_phase = calculate_error_statistics_by_phase(@passes)

    respond_with @pilot
  end

  private

  def find_squadron
    @squadron = Squadron.find_by!(username: params[:squadron_id])
  end

  def find_pilot
    @pilot = @squadron.pilots.find_by!(name: params[:id])
  end

  def calculate_boarding_rate(passes)
    return 0.0 if passes.empty?

    traps = passes.count(&:trap)
    traps.to_f / passes.size
  end

  def calculate_error_statistics(passes)
    all_errors = []

    passes.each do |pass|
      next if pass.notes.blank?

      parser = RemarksParser.new(pass.notes)
      all_errors.concat(parser.parse)
    end

    aggregator = ErrorCodeAggregator.new(all_errors)
    aggregator.top(3)
  end

  def calculate_error_statistics_by_phase(passes)
    all_errors = []

    passes.each do |pass|
      next if pass.notes.blank?

      parser = RemarksParser.new(pass.notes)
      all_errors.concat(parser.parse)
    end

    aggregator = ErrorCodeAggregator.new(all_errors)
    aggregator.by_phase(3)
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
