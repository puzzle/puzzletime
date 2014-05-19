
class EmploymentController < ManageController

  VALID_GROUPS = [EmployeeController]
  GROUP_KEY = 'employment'

  def format_column(attribute, value, entry)
    if :percent == attribute
      (value == value.to_i ? value.to_i.to_s : value.to_s) + ' %'
    else
      super  attribute, value, entry
    end
  end

  def edit_fields
    []
  end

  def list_fields
    [[:start_date, 'Start Datum'],
     [:end_date, 'End Datum'],
     [:percent, 'Prozent']]
  end

end
