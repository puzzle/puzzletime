# frozen_string_literal: true

# Include in `test_helper.rb` like this:
#
# class ActiveSupport::TestCase
#   require RetryOnFlakyTests[FlakyError, AnotherFlakyError, max_tries: 3]
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

      def run(klass, method_name, reporter)
        report_result = nil
        max_tries.times do
          result = klass.new(method_name).run
          report_result ||= result
          (report_result = result) and break if result.passed?

          break unless retryable_failure?(result)
        end
        reporter.record(report_result)
      end

      # Only the named classes are retried. `failure.error` is the real
      # exception for an error and the Minitest::Assertion for a failed
      # assertion, so an assertion failure matches nothing and reports on the
      # first attempt. Marshalling a test result across parallel workers
      # replaces unmarshallable exceptions with a RuntimeError whose message
      # is "Neutered Exception <OriginalClass>: ...", which is why the class
      # name is also matched against the message.
      def retryable_failure?(result)
        result.failures.any? do |failure|
          error = failure.error
          error_classes.any? do |error_class|
            error.is_a?(error_class) || error.to_s.include?(error_class.name)
          end
        end
      end
    end
  end
end
