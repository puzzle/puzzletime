class ApplicationMailer < ActionMailer::Base
  layout 'mailer'
  helper FormatHelper
  helper EmailHelper

  default from: Settings.mailer.from
end
