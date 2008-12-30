class Attendancetime < Worktime

  attr_reader :projecttime

  def self.label
    'Anwesenheitszeit'
  end

  def self.account_label
    'Anwesenheit'
  end
  
  def projecttime=(value)
    @projecttime = value.kind_of?(String) ? value.to_i != 0 : value
  end
  
  def corresponding_type
    Projecttime
  end
  
end