# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # The shared part of the operations that book several worktimes at once (`POST /ordertimes/repeat`,
    # `POST /absencetimes/multi`). The body is the usual `{data: {attributes: {...}}}`; every entry is saved through
    # its resource, so Ability, committed-period and validation rules are the ones of a single create.
    module MultiBooking
      private

      def booking_attributes
        @booking_attributes ||= params.dig(:data, :attributes)&.to_unsafe_h&.symbolize_keys || {}
      end

      # The employee to book for: management may name one, everyone else is themselves.
      def booking_employee(model)
        current_ability.authorize!(:create, model)
        raise CanCan::AccessDenied unless current_user.is_a?(Employee)

        given = booking_attributes[:employee_id]
        return @booking_employee = current_user unless given

        raise CanCan::AccessDenied, 'Not allowed to set: employee_id' unless current_user.management?

        @booking_employee = Employee.find(given)
      end

      # Saves all entries or none; the first invalid one fails the request (422), a forbidden one raises (403).
      def book_all(resource, rows)
        failed = nil
        created = ActiveRecord::Base.transaction do
          rows.map { |row| resource.build(booking_payload(resource, row)) }.each_with_object([]) do |proxy, saved|
            failed = proxy
            raise ActiveRecord::Rollback unless proxy.save

            saved << proxy.data
            failed = nil
          end
        end
        return render jsonapi_errors: failed if failed

        render jsonapi: resource.all(filter: { id: created.pluck(:id).join(',').presence || '0' },
                                     page: { size: [created.size, 1].max }),
               status: :created
      end

      def booking_payload(resource, row)
        row = row.merge(employee_id: @booking_employee.id) if current_user.management?
        ActionController::Parameters.new(data: { type: resource.config[:type].to_s, attributes: row })
      end

      def render_validation_errors(object)
        render json: { errors: Graphiti::ErrorSerializers::Validation.new(object).errors },
               status: :unprocessable_content, content_type: Mime[:jsonapi]
      end
    end
  end
end
