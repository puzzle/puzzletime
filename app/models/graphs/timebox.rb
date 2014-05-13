class Timebox

  PIXEL_PER_HOUR = 8.0

  MUST_HOURS_COLOR = '#FF0000'
  ATTENDANCE_POS_COLOR = '#55FF55'
  ATTENDANCE_NEG_COLOR = '#000000'
  BLANK_COLOR = 'transparent'

  attr_reader :height, :color, :tooltip, :worktime
  attr_writer :height, :worktime

  def initialize(worktime, color = nil, hgt = nil, tooltip = nil)
    if worktime
      @worktime = worktime
      hgt ||= self.class.height_from_hours worktime.hours
      tooltip ||= tooltip_for worktime

    end
    @height = (hgt * 10).round / 10.0
    @color = color
    @tooltip = tooltip
  end

  def stretch(factor)
    @height *= factor
  end

  def self.must_hours(must_hours)
    new(nil, MUST_HOURS_COLOR, 1, "Sollzeit (#{must_hours} h)")
  end

  def self.attendance_pos(attendance, hours)
    attendance(attendance, ATTENDANCE_POS_COLOR, hours, 'zus&auml;tzliche Anwesenheit')
  end

  def self.attendance_neg(attendance, hours)
    attendance(attendance, ATTENDANCE_NEG_COLOR, hours, 'fehlende Anwesenheit')
  end

  def self.blank(hours)
    new(nil, BLANK_COLOR, height_from_hours(hours), '')
  end

  def self.height_from_hours(hours)
    hours * PIXEL_PER_HOUR
  end

  private

  def self.attendance(attendance, color, hours, tooltip)
    new(attendance, color, height_from_hours(hours),
        "#{tooltip} (#{'%0.2f' % hours} h)")
  end

  def tooltip_for(worktime)
    worktime.timeString + ': ' + (worktime.account ? worktime.account.label : 'Anwesenheit')
  end

end
