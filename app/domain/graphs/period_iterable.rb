module PeriodIterable

  def each_day
    @period.start_date.step(@period.end_date) do |day|
      yield day
    end
  end

  def each_week
    @period.start_date.step(@period.end_date, 7) do |week|
      yield week
    end
  end

  def enumerate_weeks
    Enumerator.new do |y|
      current = @period.start_date
      loop do
        raise StopIteration if current > @period.end_date
        y << current
        current += 7
      end
    end
  end

  def cache
    @cache ||= {}
  end

end