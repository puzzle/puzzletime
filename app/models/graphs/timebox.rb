class Timebox
  
  MUST_HOURS_COLOR = '#FF0000'
  ATTENDANCE_POS_COLOR = '#55FF55'
  ATTENDANCE_NEG_COLOR = '#000000'
  BLANK_COLOR = 'transparent'
  
  attr_reader :height, :color, :tooltip
  attr_writer :height
  
  def initialize(height, color, tooltip)
    @height = height
    @color = color
    @tooltip = tooltip
  end
  
  def stretch(factor)
    @height *= factor
  end
  
  def self.must_hours
    new(1, MUST_HOURS_COLOR, 'Sollzeit')
  end
  
  def self.attendance_pos(height)
    new(height, ATTENDANCE_POS_COLOR, 'Anwesenheit')
  end

  def self.attendance_neg(height)
    new(height, ATTENDANCE_NEG_COLOR, 'Anwesenheit')
  end
  
  def self.blank(height)
    new(height, BLANK_COLOR, '')
  end
  
end