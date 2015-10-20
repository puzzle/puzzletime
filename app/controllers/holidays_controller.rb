# encoding: utf-8


class HolidaysController < ManageController
  self.permitted_attrs = [:holiday_date, :musthours_day]
end
