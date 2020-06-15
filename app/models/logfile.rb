require 'logfile_processor'

# The Logfile model links to one or more dcs.log files uploaded for a Squadron.
# The Logfile class has a one-to-many relationship to the `files` association
# (which are represented as Active Storage attachments), but the front-end
# currently only allows one dcs.log file to be uploaded at a time.
#
# Logfiles move through different states (pending, in progress, complete,
# failed). These states are recalculated automatically by after-save hooks.
#
# Associations
# ------------
#
# | `squadron` | The {Squadron} these files are uploaded for. |
# | `files` | The `ActiveStorage::Attachment`s for the attached dcs.log files. |
#
# Properties
# ----------
#
# | `state` | The current state of the processing operation for all dcs.log files. |
# | `completed_files` | The number of associated files that have finished processing. |
# | `failed_files` | The number of associated files that have failed processing. |

class Logfile < ApplicationRecord
  enum state: %i[pending in_progress complete failed]

  belongs_to :squadron

  has_many_attached :files

  before_save :recalculate_state!
  after_create_commit :enqueue_process_job
  after_commit { LogfilesChannel.broadcast_to squadron, LogfilesChannel::Coder.encode(self) }

  validates :files,
            attached:     true,
            size:         {less_than: 100.megabytes},
            content_type: {in: %w[text/plain text/x-log]}

  # Creates {FileProcessorJob}s for each file attached to this record.

  def process!
    files.each do |attachment|
      FileProcessorJob.perform_later attachment
    end
  end

  # @return [Float] The number of completed files, as a fraction of the total
  #   file count.

  def progress
    completed_files.to_f/files.count
  end

  # Recalculates the value of the `state` property.
  #
  # @param [boolean] save If `true`, saves the recalculated value to the
  #   database.

  def recalculate_state!(save: false)
    self.state = calculated_state
    save! if save
  end

  private

  def calculated_state
    return :failed if failed_files.positive?
    return :complete if completed_files == files.count
    return :pending if completed_files.zero? && failed_files.zero?

    return :in_progress
  end

  def enqueue_process_job
    LogfileProcessorJob.set(wait: 10.seconds).perform_later self
  end
end
