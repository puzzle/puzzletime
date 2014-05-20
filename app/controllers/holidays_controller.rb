# encoding: utf-8


class HolidaysController < CrudController

  self.permitted_attrs = [:holiday_date, :musthours_day]

end
