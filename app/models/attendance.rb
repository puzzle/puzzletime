class Attendance < Splitable
  
  def initialize(time)
    super(time)
    original.project_id = DEFAULT_PROJECT_ID
    original.description = 'Präsenzzeit'
  end
    
  def save
    if incomplete?
      original.hours = remainingHours
      original.save
    end
    super
  end
  
end