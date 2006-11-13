# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  #Accessor needed for all select*.rhtml
  attr_accessor :start
  attr_accessor :end
  
  def self.conditionsFor(period = nil, idHash = {})
    condArray = [ " 1=1 "]
    if period != nil
      condArray = ["(work_date BETWEEN ? AND ?)", period.startDate, period.endDate]
    end  
    idHash.each_pair { |name, id|
      if id > 0 
        condArray[0] += "AND #{name} = ?"
        condArray.push(id)
      end
    }
    condArray
  end  
  
end
