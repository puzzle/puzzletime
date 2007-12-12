module BenchmarkForRails
  class << self
    # Prints the benchmarks for the request into the log, with some
    # basic ASCII formatting (yay).
    def report(request)
      request_action = "#{request.method.to_s.upcase} #{request.path}"
      request_time   = results.delete(:request)
      logger.info "- [#{'%.4f' % request_time}] #{request_action} ".ljust(50, '-')

      results.to_a.sort_by{|(name, seconds)| seconds}.reverse.each do |(name, seconds)|
        logger.info "   #{'%.4f' % seconds} #{name}"
      end

      logger.info " BenchmarkForRails -".rjust(50, '-')

      results.clear
    end
  end
end

class ::Dispatcher
  # print reports at the end
  def dispatch_with_benchmark_for_rails_reporting(*args, &block) #:nodoc:
    returning dispatch_without_benchmark_for_rails_reporting(*args, &block) do
      BenchmarkForRails.report(@request)
      RAILS_DEFAULT_LOGGER.flush if RAILS_DEFAULT_LOGGER.respond_to? :flush
    end
  end
  alias_method_chain :dispatch, :benchmark_for_rails_reporting
end
