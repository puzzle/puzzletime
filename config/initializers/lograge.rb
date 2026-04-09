# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.ignore_actions = ['StatusController#health', 'StatusController#readiness']

  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:headers]['action_dispatch.request_id'],
      login_shortname: event.payload[:login_shortname],
      user_id: event.payload[:user_id]
    }.compact
  end
end
