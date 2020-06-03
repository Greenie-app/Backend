# @abtract
#
# Abstract superclass for all Greenie.app mailers.

class ApplicationMailer < ActionMailer::Base
  default from: 'donotreply@greenie.app'
  layout 'mailer'
end
