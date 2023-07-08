# frozen_string_literal: true

# Rack application that an endpoint allowing the Cypress front-end to reset the
# database before each E2E test run. Only mounted in the `cypress` environment.

class ResetCypress

  # @private
  def call(env)
    request = Rack::Request.new(env)

    reset
    create_fixtures upload: request.params["no_upload"].blank?
    return response
  end

  private

  def reset
    models.each { truncate _1 }
    reset_emails
  end

  def response = [200, {"Content-Type" => "text/plain"}, ["Cypress reset finished"]]

  def models = [ActiveStorage::Blob, ActiveStorage::Attachment, *ApplicationRecord.subclasses]

  def truncate(model)
    model.connection.execute "TRUNCATE #{model.quoted_table_name} CASCADE"
  end

  def create_fixtures(upload: true)
    squadron = Squadron.create!(name:                  "Squadron 1",
                                username:              "squadron-1",
                                email:                 "cypress@example.com",
                                password:              "password123",
                                password_confirmation: "password123")

    return unless upload

    logfile = squadron.logfiles.new
    logfile.files.attach io:       Rails.root.join("spec", "fixtures", "files", "dcs.log").open,
                         filename: "dcs.log"
    logfile.save!
    logfile.process_now!
  end

  def reset_emails
    Dir.glob(maildir.join("*").to_s).each { FileUtils.rm _1 }
  end

  def maildir = Rails.root.join("tmp", "mails")
end
