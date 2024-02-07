# frozen_string_literal: true

class ReportType
  class StartStopType < ReportType
    INSTANCE = new 'start_stop_day', 'Von/Bis Zeit', 10
    START_STOP = true

    def time_string(worktime)
      if worktime.from_start_time.is_a?(Time) &&
         worktime.to_end_time.is_a?(Time)
        "#{I18n.l(worktime.from_start_time,
                  format: :time)} - #{I18n.l(worktime.to_end_time, format: :time)} (#{rounded_hours(worktime)} h)"
      end
    end

    def copy_times(source, target)
      super(source, target)
      target.from_start_time = source.from_start_time
      target.to_end_time = source.to_end_time
    end

    def validate_worktime(worktime)
      worktime.errors.add(:from_start_time, 'Die Anfangszeit ist ungültig') unless worktime.from_start_time.is_a?(Time)
      worktime.errors.add(:to_end_time, 'Die Endzeit ist ungültig') unless worktime.to_end_time.is_a?(Time)
      if worktime.from_start_time.is_a?(Time) && worktime.to_end_time.is_a?(Time) &&
         worktime.to_end_time <= worktime.from_start_time
        worktime.errors.add(:to_end_time, 'Die Endzeit muss nach der Startzeit sein')
      end
      return unless worktime.from_start_time&.to_date != worktime.to_end_time&.to_date

      worktime.errors.add(:to_end_time, 'Die Endzeit muss zwischen 00:00-23:59 liegen')
    end
  end
end
