# frozen_string_literal: true

# Rack application that an endpoint allowing the Cypress front-end to reset the
# database before each E2E test run. Only mounted in the `cypress` environment.

class ResetCypress

  # @private
  def call(_env)
    Rails.logger.info(ApplicationRecord.connection.inspect)
    reset
    return response
  end

  private

  def reset
    models.each { |model| truncate model }
    reset_emails
  end

  def response
    [200, {"Content-Type" => "text/plain"}, ["Cypress reset finished"]]
  end

  def models
    [ActiveStorage::Blob, ActiveStorage::Attachment, *ApplicationRecord.subclasses]
  end

  def truncate(model)
    model.connection.execute "TRUNCATE #{model.quoted_table_name} CASCADE"
  end

  def reset_emails
    Dir.glob(maildir.join("*").to_s).each { |f| FileUtils.rm f }
  end

  def maildir
    Rails.root.join("tmp", "mails")
  end
end
