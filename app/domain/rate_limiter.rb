class RateLimiter

  attr_reader :rate_per_second

  def initialize(rate_per_second)
    @rate_per_second = rate_per_second
    @last_run_at = Time.at(0)
    @interval = (1.0 / rate_per_second).seconds
  end

  def run
    sleep(sleep_time)
    self.last_run_at = Time.now
    yield
  end

  private

  attr_reader :interval
  attr_accessor :last_run_at

  def sleep_time
    [0, next_run_at - Time.now].max
  end

  def next_run_at
    last_run_at + interval
  end

end