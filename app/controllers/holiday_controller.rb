
class HolidayController < ManageController

  GROUP_KEY = 'holiday'

  def editFields
    [[:holiday_date, 'Datum'], [:musthours_day, 'Muss Stunden']]
  end

end
