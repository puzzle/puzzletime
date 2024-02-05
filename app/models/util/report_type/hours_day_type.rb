# frozen_string_literal: true

class ReportType
  class HoursDayType < ReportType
    INSTANCE = new 'absolute_day', 'Stunden/Tag', 6

    def time_string(worktime)
      "#{rounded_hours(worktime)} h"
    end
  end
end
