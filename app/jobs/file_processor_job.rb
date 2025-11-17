# frozen_string_literal: true

# This job processes the individual dcs.log files of a {Logfile} using
# {LogfileProcessor}.

class FileProcessorJob < ApplicationJob
  queue_as :default

  # Retry if file isn't available yet (overrides ApplicationJob's discard_on)
  retry_on ActiveStorage::FileNotFoundError,
           wait:     :polynomially_longer,
           attempts: 5

  # Processes a dcs.log file.
  #
  # @param [ActiveStorage::Attachment] An attachment to a {Logfile}.

  def perform(file)
    # Check file availability before processing
    unless file.blob.service.exist?(file.blob.key)
      raise ActiveStorage::FileNotFoundError, "Blob not yet available: #{file.blob.key}"
    end

    LogfileProcessor.new(file.record, file).process!
    file.record.increment! :completed_files
    file.record.recalculate_state!(save: true)
  end

  # TODO: increment failed_files when job fails; decrement upon retry
end
