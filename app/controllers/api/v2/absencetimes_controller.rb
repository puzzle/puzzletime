# frozen_string_literal: true

module Api
  module V2
    # Serves AbsencetimeResource; the actions come from ResourceController, `multi` books a whole period.
    class AbsencetimesController < ResourceController
      include MultiBooking

      # Books an absence on every working day of `duration` weeks (hours = the day's must hours times employment).
      def multi
        form = Forms::MultiAbsence.new
        form.employee = booking_employee(Absencetime)
        form.attributes = booking_attributes.slice(:absence_id, :work_date, :duration, :description)
        return render_validation_errors(form.worktime) unless form.valid?

        book_all(AbsencetimeResource, form.build.map { |absence| absence_attributes(absence) })
      end

      private

      def absence_attributes(absence)
        absence.slice(:absence_id, :work_date, :hours, :description).symbolize_keys
      end
    end
  end
end
