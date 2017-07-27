#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class RateLimiter

  attr_reader :rate_per_second

  def initialize(rate_per_second)
    @rate_per_second = rate_per_second
    @last_run_at = Time.zone.at(0)
    @interval = (1.0 / rate_per_second).seconds
  end

  def run
    sleep(sleep_time)
    self.last_run_at = Time.zone.now
    yield
  end

  private

  attr_reader :interval
  attr_accessor :last_run_at

  def sleep_time
    [0, next_run_at - Time.zone.now].max
  end

  def next_run_at
    last_run_at + interval
  end

end
