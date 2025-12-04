# frozen_string_literal: true

class ErrorTracker
  class << self
    def type
      Settings.error_tracker.type.to_sym
    end

    def report_message(message)
      Sentry.capture_message(message) if sentry_like?
      Airbrake.notify(message) if airbrake_like?
    end

    def report_exception(error, payload)
      Sentry.capture_exception(error, extra: payload) if sentry_like?
      Airbrake.notify(error, payload) if airbrake_like?
    end

    def set_tags(**kwargs)
      Sentry.set_tags(**kwargs) if sentry_like?
      Airbrake.merge_context(tags: kwargs) if airbrake?
    end

    def set_extras(**kwargs)
      Sentry.set_extras(**kwargs) if sentry_like?
      Airbrake.merge_context(extra: kwargs) if airbrake?
    end

    def set_user(**kwargs)
      Sentry.set_user(**kwargs) if sentry_like?
      Airbrake.merge_context(user: kwargs) if airbrake?
    end

    def set_contexts(**)
      Sentry.set_contexts(**) if sentry_like?
      Airbrake.merge_context(**) if airbrake?
    end

    def airbrake_like?
      %i[airbrake errbit].include? type
    end

    def sentry_like?
      %i[sentry glitchtip].include? type
    end
  end
end
