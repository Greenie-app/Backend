# frozen_string_literal: true

# This job spawns {FileProcessorJob}s for each dcs.log file attached to a
# {Logfile} record.

class LogfileProcessorJob < ApplicationJob
  queue_as :default

  # Processes a {Logfile}.
  #
  # @param [Logfile] logfile The logfile.

  def perform(logfile) = logfile.process!
end
