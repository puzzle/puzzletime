class WorkingConditionsController < ManageController

  self.permitted_attrs = [:valid_from, :vacation_days_per_year, :must_hours_per_day]

end