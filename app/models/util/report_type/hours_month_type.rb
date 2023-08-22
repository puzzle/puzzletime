class ReportType::HoursMonthType < ReportType
  INSTANCE = new 'month', 'Stunden/Monat', 2

  def time_string(worktime)
    "#{rounded_hours(worktime)} h in diesem Monat"
  end

  def date_string(date)
    I18n.l(date, format: '%m.%Y')
  end
end
