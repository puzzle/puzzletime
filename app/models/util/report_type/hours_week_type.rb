# frozen_string_literal: true

class ReportType
  class HoursWeekType < ReportType
    INSTANCE = new 'week', 'Stunden/Woche', 4

    def time_string(worktime)
      "#{rounded_hours(worktime)} h in dieser Woche"
    end

    def date_string(date)
      I18n.l(date, format: 'W %V, %Y')
    end
  end
end
