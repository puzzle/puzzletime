# encoding: utf-8

class Splitable

  INCOMPLETE_FINISH = true
  SUBMIT_BUTTONS = nil

  attr_reader :original, :worktimes

  def initialize(original)
    @original = original
    @worktimes = []
  end

  def add_worktime(worktime)
    if original.report_type > HoursWeekType::INSTANCE && worktime.work_date != original.work_date
      worktime.work_date = original.work_date
      worktime.errors.add(:work_date, 'Das Datum kann nicht geändert werden')
      return false
    end
    @worktimes.push(worktime)
  end

  def remove_worktime(index)
    @worktimes.delete_at(index) if @worktimes[index].new_record?
  end

  def worktime_template
    worktime = last_worktime.template Projecttime.new
    worktime.hours = remaining_hours
    worktime.from_start_time = next_start_time
    worktime.to_end_time = original.to_end_time
    worktime.project_id ||= worktime.employee.default_project_id
    worktime
  end

  def complete?
    remaining_hours < 0.00001     # we are working with floats: use delta
  end

  def save
    worktimes.each { |wtime|  wtime.save }
  end

  def page_title
    'Aufteilen'
  end

  def empty?
    worktimes.empty?
  end

  protected

  def remaining_hours
    original.hours - worktimes.inject(0) { |sum, time| sum + time.hours }
  end

  def next_start_time
    worktimes.empty? ?
      original.from_start_time :
      worktimes.last.to_end_time
  end

  def last_worktime
    worktimes.empty? ? original : worktimes.last
  end

end
