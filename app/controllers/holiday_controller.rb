# encoding: utf-8


class HolidayController < ManageController

  GROUP_KEY = 'holiday'

  def edit_fields
    [[:holiday_date, 'Datum'], [:musthours_day, 'Muss Stunden']]
  end

end
