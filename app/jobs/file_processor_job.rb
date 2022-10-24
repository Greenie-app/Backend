# frozen_string_literal: true

# This job processes the individual dcs.log files of a {Logfile} using
# {LogfileProcessor}.

class FileProcessorJob < ApplicationJob
  queue_as :default

  # Processes a dcs.log file.
  #
  # @param [ActiveStorage::Attachment] An attachment to a {Logfile}.

  def perform(file)
    LogfileProcessor.new(file.record, file).process!
    file.record.increment! :completed_files
    file.record.recalculate_state!(save: true)
  end
  #TODO: increment failed_files when job fails; decrement upon retry
end
