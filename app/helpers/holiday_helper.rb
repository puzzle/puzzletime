module HolidayHelper

  def regularHolidayString
    dates = REGULAR_HOLIDAYS.collect do |day|
      "#{day[0]}. #{Date::MONTHNAMES[day[1]]}"
    end
    dates.join(', ')
  end

end
