# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    module Resources
      # Ordertime, Absencetime and the worktimes commit/review workflows.
      # Mirrors WorktimesController, OrdertimesController, AbsencetimesController and
      # Employees::Worktimes{Commit,Review}Controller. `Worktime` itself is never exposed.
      # Not exposed: the session-backed split workflow and MultiWorktimesController.
      module TimeEntries
        # `hours` and the times accept "8:45", "1400", ... which the model setters parse.
        TYPES = { hours: String, from_start_time: String, to_end_time: String }.freeze
        TIMES = %i[from_start_time to_end_time].freeze
        ORDERTIME = %i[work_item_id work_date hours from_start_time to_end_time description internal_description
                       billable ticket meal_compensation].freeze
        ABSENCETIME = %i[absence_id work_date hours from_start_time to_end_time description].freeze

        # Request helpers shared by the generic routes and the multi-create operations.
        module Helpers
          # Defaults and rules the HTML controllers apply around save (WorktimesController).
          def prepare_worktime(entry, given: params.keys.map(&:to_sym))
            user = current_user
            return unless user.is_a?(Employee) # authorize! rejects everyone else

            entry.employee = user if entry.employee_id.blank? || !user.management?
            # Hours entered without times must not be recomputed from stale times.
            TIMES.each { |attr| entry[attr] = nil if given.include?(:hours) && given.exclude?(attr) }
            check_accounting_post(entry)
            check_worktimes_committed(entry, user)
          end

          def check_accounting_post(entry)
            return unless entry.is_a?(Ordertime) && entry.work_item && !entry.work_item.accounting_post

            error!({ errors: { work_item_id: ['Der Auftrag hat keine Buchungsposition.'] } }, 422)
          end

          # Employees can't touch their own committed worktimes, except as order responsible.
          def check_worktimes_committed(entry, user)
            order = entry.order if entry.is_a?(Ordertime) && entry.work_item
            return if order&.responsible_id == user.id || entry.employee_id != user.id || !entry.worktimes_committed?

            date = I18n.l(user.committed_worktimes_at, format: :month)
            error!({ errors: { work_date: ["Die Zeiten bis und mit #{date} wurden freigegeben " \
                                           'und können nicht mehr bearbeitet werden.'] } }, 422)
          end

          def notify_worktime_deleted(entry)
            return if entry.employee == current_user

            EmployeeMailer.worktime_deleted_mail(entry, current_user).deliver_now
          end

          # The employee a multi-create is for: management may name one, everyone else is themselves.
          def multi_employee(model)
            authorize!(:create, model)
            raise CanCan::AccessDenied unless current_user.is_a?(Employee)

            given = params[:employee_id]
            return current_user unless given

            error!({ error: 'Not allowed to set: employee_id' }, 403) unless current_user.management?

            Employee.find_by(id: given) || error!({ errors: { employee_id: ['existiert nicht'] } }, 422)
          end

          # Saves all entries or none (error! rolls the transaction back); the first invalid one is a 422.
          def create_all(entries)
            ActiveRecord::Base.transaction do
              entries.each do |entry|
                prepare_worktime(entry, given: [])
                authorize!(:create, entry)
                error!({ errors: entry.errors.to_hash }, 422) unless entry.save
              end
            end
          end
        end

        class << self
          def call(api)
            api.helpers Helpers
            ordertimes(api)
            absencetimes(api)
            completion(api, :committed_worktimes_at, :update_committed_worktimes, 'worktimes_commit')
            completion(api, :reviewed_worktimes_at, :update_reviewed_worktimes, 'worktimes_review')
          end

          private

          def own_or_all(model)
            lambda do |user|
              case user
              when Employee then user.management? ? model.all : model.where(employee_id: user.id)
              else model.none
              end
            end
          end

          def writable_by(attrs)
            ->(user) { user.try(:management?) ? attrs : attrs - [:employee_id] }
          end

          def destroyer
            lambda do |entry|
              entry.destroy.tap { |destroyed| notify_worktime_deleted(entry) if destroyed }
            end
          end

          def ordertimes(api)
            read = %i[id employee_id invoice_id] + ORDERTIME
            write = ORDERTIME + [:employee_id]
            api.crud Ordertime, read:, write:, types: TYPES, scope: own_or_all(Ordertime),
                                writable_by: writable_by(write),
                                prepare: ->(entry) { prepare_worktime(entry) },
                                destroy: destroyer do
              desc 'Create the same Ordertime on `repetitions` consecutive days (days without employment are ' \
                   'skipped). All or nothing.', success: Crud.resources.fetch(Ordertime).entity, is_array: true
              params do
                Crud.declare(self, Ordertime, ORDERTIME - [:meal_compensation], {}, TYPES.merge(hours: Float))
                optional :employee_id, type: Integer
                requires :repetitions, type: Integer
              end
              post :repeat do
                form = Forms::MultiOrdertime.new(declared(params, include_missing: false).to_h
                                                   .symbolize_keys.except(:employee_id, :work_item_id)
                                                   .merge(account_id: params[:work_item_id]))
                form.employee = multi_employee(Ordertime)
                error!({ errors: form.errors.to_hash }, 422) unless form.valid?

                entries = form.prepare_each.map do |row|
                  Ordertime.new(row[:ordertime].to_unsafe_h.compact.merge(employee: form.employee))
                end
                present create_all(entries), with: Crud.resources.fetch(Ordertime).entity
              end
            end
          end

          def absencetimes(api)
            read = %i[id employee_id billable] + ABSENCETIME
            write = ABSENCETIME + [:employee_id]
            api.crud Absencetime, read:, write:, types: TYPES, scope: own_or_all(Absencetime),
                                  writable_by: writable_by(write),
                                  prepare: ->(entry) { prepare_worktime(entry) },
                                  destroy: destroyer do
              desc 'Book an absence on every working day of `duration` weeks (hours = must hours of the day ' \
                   'times employment). All or nothing.', success: Crud.resources.fetch(Absencetime).entity,
                                                         is_array: true
              params do
                requires :absence_id, type: Integer
                requires :work_date, type: Date
                requires :duration, type: Integer
                optional :description, type: String
                optional :employee_id, type: Integer
              end
              post :multi do
                form = Forms::MultiAbsence.new
                form.employee = multi_employee(Absencetime)
                form.attributes = declared(params, include_missing: false).to_h.symbolize_keys
                error!({ errors: form.errors.to_hash }, 422) unless form.valid?

                present create_all(form.build), with: Crud.resources.fetch(Absencetime).entity
              end
            end
          end

          # PATCH /employees/:id/worktimes_commit|worktimes_review, see Completable.
          def completion(api, attr, ability, path)
            entity = completion_entity(attr)
            api.resource :employees do
              route_param :id, type: Integer do
                desc "Set `#{attr}` (a month end the user may pick, or null to clear; " \
                     'management: last 12 months or null; others: last or current month)',
                     success: entity
                params { requires attr, type: Date, desc: 'month end date, nullable' }
                patch path do
                  employee = Crud.base(Employee, current_user).find(params[:id])
                  authorize!(ability, employee)
                  date = params[attr]
                  error!({ errors: { attr => ['ist nicht erlaubt'] } }, 422) unless Completable.completion_dates(current_user).include?(date)

                  employee.update!(attr => date)
                  present employee, with: entity
                end
              end
            end
          end

          def completion_entity(attr)
            Class.new(Grape::Entity) do
              expose :id, documentation: { type: Integer }
              expose attr, documentation: { type: Date }
              define_singleton_method(:entity_name) { "Employee#{attr.to_s.camelize}" }
            end
          end
        end
      end
    end
  end
end
