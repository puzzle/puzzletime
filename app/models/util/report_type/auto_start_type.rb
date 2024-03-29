# frozen_string_literal: true

class ReportType
  class AutoStartType < ReportType::StartStopType
    INSTANCE = new 'auto_start', 'Von/Bis offen', 12

    def time_string(worktime)
      return unless worktime.from_start_time.is_a?(Time)

      "Start um #{I18n.l(worktime.from_start_time, format: :time)}"
    end

    def validate_worktime(worktime)
      # set defaults
      worktime.work_date = Time.zone.today
      worktime.hours = 0
      worktime.to_end_time = nil
      # validate
      worktime.errors.add(:from_start_time, 'Die Anfangszeit ist ungültig') unless worktime.from_start_time.is_a?(Time)
      return unless worktime.employee

      existing = worktime.employee.send(:"running_#{worktime.class.name[0..-5].downcase}")
      return unless existing && existing != worktime

      worktime.errors.add(:employee_id, "Es wurde bereits eine offene #{worktime.class.model_name.human} erfasst")
    end
  end
end
