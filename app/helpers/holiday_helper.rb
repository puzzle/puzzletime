# encoding: utf-8

module HolidayHelper

  def regular_holiday_string
    dates = REGULAR_HOLIDAYS.collect do |day|
      "#{day[0]}. #{Date::MONTHNAMES[day[1]]}"
    end
    dates.join(', ')
  end

end
