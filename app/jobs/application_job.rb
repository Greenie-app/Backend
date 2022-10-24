# frozen_string_literal: true

# @abstract
#
# Abstract superclass for all Active Job workers.

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError, ActiveStorage::FileNotFoundError
end
