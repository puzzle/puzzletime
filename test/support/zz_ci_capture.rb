# frozen_string_literal: true

# TEMPORARY: dumps the page behind every CI failure, remove once the CI-only
# integration failures are diagnosed.
module CiFailureCapture
  def run
    result = super
    capture(result.failures.first) if ENV['CI'].present?
    result
  end

  private

  def capture(failure)
    return unless failure

    session = Capybara.current_session
    dir = Rails.root.join('tmp/capybara').tap(&:mkpath)
    dir.join("#{self.class}-#{name}.html")
       .write("<!-- #{session.current_url} | #{failure.error.message.lines.first} -->\n#{session.html}")
  rescue StandardError
    nil
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { prepend CiFailureCapture }
