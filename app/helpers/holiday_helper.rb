# encoding: utf-8

module HolidayHelper
  def regular_holiday_string
    dates = Settings.regular_holidays.collect do |day|
      "#{day[0]}. #{I18n.t(:'date.month_names')[day[1]]}"
    end
    dates.join(', ')
  end
end
