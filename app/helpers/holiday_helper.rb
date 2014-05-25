# encoding: utf-8

module HolidayHelper

  def regular_holiday_string
    dates = REGULAR_HOLIDAYS.collect do |day|
      "#{day[0]}. #{I18n.t(:'date.month_names')[day[1]]}"
    end
    dates.join(', ')
  end

end
