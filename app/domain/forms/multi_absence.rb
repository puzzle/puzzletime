#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Forms::MultiAbsence
  attr_reader :absence_id, :employee, :work_date, :duration, :description, :worktime
  attr_writer :employee

  def initialize
    @duration = 1
  end

  def attributes=(attr_hash)
    @absence_id = attr_hash[:absence_id]
    @work_date = attr_hash[:work_date]
    @duration = attr_hash[:duration]
    @description = attr_hash[:description]
  end

  def valid?
    @worktime = worktime_template(@work_date,
                                  WorkingCondition.value_at(work_date, :must_hours_per_day))
    valid = @worktime.valid?
    if valid
      if duration <= 0
        valid = false
        @worktime.errors.add(:work_date, 'Die Dauer muss grösser als 0 sein.')
      end
    end
    valid
  end

  def work_date
    date_or_nil(@work_date)
  end

  def end_date
    work_date + duration * 7 - 1
  end

  def duration
    @duration.to_i
  end

  def period
    Period.new(work_date, end_date)
  end

  def errors
    @worktime ? @worktime.errors : {}
  end

  def save
    absences = []
    period.step do |date|
      employment = @employee.employment_at(date)
      if employment
        must = Holiday.musttime(date) * employment.percent_factor
        if must > 0
          absences << worktime_template(date, must)
        end
      end
    end
    absences.each(&:save)
    absences
  end

  private

  def date_or_nil(value)
    unless value.is_a? Date
      begin
        value = Date.parse(value)
      rescue
        value = nil
      end
    end
    value
  end

  def worktime_template(date, hours)
    worktime = Absencetime.new
    worktime.report_type = ReportType::HoursDayType::INSTANCE
    worktime.work_date = date
    worktime.absence_id = @absence_id
    worktime.description = @description
    worktime.employee = @employee
    worktime.hours = hours
    worktime
  end
end
