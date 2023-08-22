class ReportType::HoursDayType < ReportType
  INSTANCE = new 'absolute_day', 'Stunden/Tag', 6

  def time_string(worktime)
    "#{rounded_hours(worktime)} h"
  end
end
