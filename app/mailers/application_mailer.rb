class ApplicationMailer < ActionMailer::Base
  layout 'mailer'
  add_template_helper FormatHelper
  add_template_helper EmailHelper

  default from: Settings.mailer.from
end
