# encoding: utf-8

class Timebox

  PIXEL_PER_HOUR = 8.0

  MUST_HOURS_COLOR = '#FF0000'
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

  def self.blank(hours)
    new(nil, BLANK_COLOR, height_from_hours(hours), '')
  end

  def self.height_from_hours(hours)
    hours * PIXEL_PER_HOUR
  end

  private

  def tooltip_for(worktime)
    worktime.time_string + ': ' + (worktime.account ? worktime.account.label : 'Anwesenheit')
  end

end
