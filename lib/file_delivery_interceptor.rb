# frozen_string_literal: true

# Mail interceptor for Cypress E2E tests that writes emails to files
# so they can be retrieved by the CypressEmails endpoint.
#
# This interceptor writes each email to tmp/mails/<recipient_email>
# when an email is delivered in the cypress environment.

class FileDeliveryInterceptor
  def self.delivering_email(message)
    # Get the mail directory
    maildir = Rails.root.join("tmp", "mails")
    FileUtils.mkdir_p(maildir) unless maildir.directory?

    # Write email for each recipient
    message.to.each do |recipient|
      mailfile = maildir.join(recipient)
      File.write(mailfile, message.body.raw_source)
    end
  end
end
