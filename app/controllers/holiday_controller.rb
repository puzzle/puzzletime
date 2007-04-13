
class HolidayController < ManageController

  def modelClass
    Holiday
  end
  
  def editFields
    [ [ :holiday_date, 'Datum' ], [ :musthours_day, 'Muss Stunden' ] ]
  end
  
end
