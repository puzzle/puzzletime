module PeriodIteratable

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

  def cache
    @cache ||= {}
  end

end