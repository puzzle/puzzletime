# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # `PATCH /employees/:id/worktimes_commit|worktimes_review`: marks the months up to a date as committed (by the
    # employee or management) or reviewed (management). Mirrors Employees::Worktimes{Commit,Review}Controller: the
    # date must be one of Completable.completion_dates, `null` (management only) clears it.
    class WorktimeCompletionsController < BaseController
      def commit
        complete(:committed_worktimes_at, :update_committed_worktimes)
      end

      def review
        complete(:reviewed_worktimes_at, :update_reviewed_worktimes)
      end

      private

      def complete(attribute, ability)
        employee = Employee.find(params[:id])
        current_ability.authorize!(ability, employee)
        date = completion_date(attribute)
        return render_completion_error(attribute) unless date && Completable.completion_dates(current_user).include?(date.first)

        employee.update!(attribute => date.first)
        render json: { data: { type: 'employees', id: employee.id.to_s, attributes: { attribute => employee[attribute] } } },
               content_type: Mime[:jsonapi]
      end

      # [date] (date is nil to clear), or nil when the attribute is missing or not a date.
      def completion_date(attribute)
        attributes = params.dig(:data, :attributes)
        return unless attributes&.key?(attribute)

        [attributes[attribute].presence && Date.iso8601(attributes[attribute])]
      rescue ArgumentError, TypeError
        nil
      end

      def render_completion_error(attribute)
        render json: { errors: [{ status: '422', title: 'ist nicht erlaubt',
                                  source: { pointer: "/data/attributes/#{attribute}" } }] },
               status: :unprocessable_content, content_type: Mime[:jsonapi]
      end
    end
  end
end
