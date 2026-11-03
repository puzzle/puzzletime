# frozen_string_literal: true

module Api
  module V2
    # Serves OrdertimeResource; the actions come from ResourceController, `repeat` books consecutive days.
    class OrdertimesController < ResourceController
      include MultiBooking

      REPEAT_ATTRIBUTES = %i[work_date repetitions hours from_start_time to_end_time description internal_description
                             billable ticket].freeze

      # Creates the same ordertime on `repetitions` consecutive days (days without employment are skipped).
      def repeat
        form = Forms::MultiOrdertime.new(booking_attributes.slice(*REPEAT_ATTRIBUTES)
                                                           .merge(account_id: booking_attributes[:work_item_id]))
        form.employee = booking_employee(Ordertime)
        return render_validation_errors(form) unless form.valid?

        book_all(OrdertimeResource, form.prepare_each.map { |row| ordertime_attributes(row[:ordertime]) })
      end

      private

      def ordertime_attributes(row)
        attributes = row.to_unsafe_h.symbolize_keys
        attributes[:work_item_id] = attributes.delete(:account_id)
        attributes.compact
      end
    end
  end
end
