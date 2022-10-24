# frozen_string_literal: true

# Rack application that exposes emails generated during Cypress E2E tests to the
# E2E front-end. Only mounted in the `cypress` environment.

class CypressEmails

  # @private
  def call(env)
    if (email = email_param(env).presence) # rubocop:disable Style/GuardClause
      return response(emails_for(email))
    else
      return bad_request
    end
  end

  private

  def email_param(env)
    request = ActionDispatch::Request.new(env)
    return request.query_parameters["email"]
  end

  def maildir
    Rails.root.join("tmp", "mails")
  end

  def mailfile(email)
    maildir.join(email)
  end

  def emails_for(email)
    file = mailfile(email)
    file.file? ? file.read : ""
  end

  def response(body)
    [200, {"Content-Type" => "text/plain"}, [body]]
  end

  def bad_request
    [400, {"Content-Type" => "text/plain"}, ["No email given"]]
  end
end
