class Attendancetime < Worktime

  def self.label
    'Anwesenheitszeit'
  end

  def self.account_label
    'Anwesenheit'
  end
  
  # AutoStartType only available for new records or existing with this type
  def report_types
    return super if ! new_record? && report_type != AutoStartType::INSTANCE
    [AutoStartType::INSTANCE] + super   
  end
end