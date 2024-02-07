# frozen_string_literal: true

# Include in `test_helper.rb` like this:
#
# class ActiveSupport::TestCase
#   prepend RetryOnFlakyTests[FlakyError, AnotherFlakyError, max_tries: 3]
# end

module RetryOnFlakyTests
  def self.[](*error_classes, max_tries: 3)
    Module.new do
      define_method :max_tries do
        tries = ENV.fetch('RAILS_FLAKY_TRIES', max_tries).to_i

        return 1 if max_tries < 1

        tries
      end

      define_method :error_classes do
        error_classes
      end

      def run_one_method(klass, method_name, reporter)
        report_result = nil
        max_tries.times do
          result = Minitest.run_one_method(klass, method_name)
          report_result ||= result
          (report_result = result) and break if result.passed?

          break unless retryable_failure?(result)
        end
        reporter.record(report_result)
      end

      def retryable_failure?(result)
        result.failures.map do |failure|
          failure.error.to_s
        end.any? do |failure_msg|
          error_classes.first { |error_class| failure_msg =~ error_class.name }
        end
      end
    end
  end
end
