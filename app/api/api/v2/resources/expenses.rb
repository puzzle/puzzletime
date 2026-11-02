# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    module Resources
      # Expense (+ receipt, review), OvertimeVacation and Employment.
      #
      # Expense and Employment are scoped: employees only get their own rows (Ability only restricts
      # per instance, `index` would otherwise list everything). Rules mirror ExpensesController,
      # ExpensesReviewsController and EmploymentsController.
      module Expenses
        RECEIPT_MAX_BYTES = 10.megabytes
        RECEIPT_TYPES = %w[image/png image/jpeg image/gif image/webp application/pdf].freeze
        EXPENSE_READ = %i[id employee_id kind status amount payment_date description reason reviewer_id
                          reviewed_at order_id reimbursement_date submission_date].freeze
        EXPENSE_WRITE = %i[payment_date kind order_id description amount].freeze
        ROLES_KEY = :employment_roles_employments_attributes

        def self.call(api)
          api.helpers Helpers
          register_expenses(api)
          register_overtime_vacations(api)
          register_employments(api)
          expense_extra_routes(api)
        end

        def self.own_or_all(model)
          lambda do |user|
            next model.none unless user.is_a?(Employee)

            user.management? ? model.all : model.where(employee_id: user.id)
          end
        end

        def self.register_expenses(api)
          api.crud Expense,
                   read: EXPENSE_READ,
                   write: [:employee_id, *EXPENSE_WRITE],
                   scope: own_or_all(Expense),
                   writable_by: ->(user) { user.management? ? [:employee_id, *EXPENSE_WRITE] : EXPENSE_WRITE },
                   prepare: lambda { |entry|
                     if entry.new_record?
                       entry.employee_id ||= current_user.id if current_user.is_a?(Employee)
                     else
                       protect_approved_expense!(entry)
                       resubmit_rejected_expense(entry)
                     end
                   },
                   destroy: lambda { |entry|
                     protect_approved_expense!(entry)
                     entry.destroy
                   }
          Api::V2::Crud.relate(Employee, :expenses)
        end

        def self.register_overtime_vacations(api)
          api.crud OvertimeVacation,
                   read: %i[id employee_id hours transfer_date],
                   write: %i[hours transfer_date], create_only: %i[employee_id]
          Api::V2::Crud.relate(Employee, :overtime_vacations)
        end

        def self.register_employments(api)
          api.crud Employment,
                   read: [:id, :employee_id, :percent, :start_date, :end_date, :vacation_days_per_year, :comment,
                          { employment_roles_employments: %i[id employment_role_id employment_role_level_id percent] }],
                   write: %i[percent start_date end_date vacation_days_per_year comment],
                   create_only: %i[employee_id],
                   nested: { ROLES_KEY => %i[employment_role_id employment_role_level_id percent] },
                   scope: own_or_all(Employment),
                   prepare: ->(entry) { validate_employment!(entry) }
          Api::V2::Crud.relate(Employee, :employments)
        end

        # Receipt upload/download and the management review. Not part of plain CRUD.
        def self.expense_extra_routes(api)
          api.resource('expenses') do
            route_param(:id, type: Integer) do
              desc 'Attach or replace the receipt (png, jpeg, gif, webp, pdf; max 10 MB decoded). ' \
                   'The file type is detected from the content; images are resized.',
                   success: Api::V2::Crud.resources.fetch(Expense).entity
              params do
                requires :filename, type: String
                requires :data_base64, type: String, desc: 'Base64 encoded file content'
              end
              put :receipt do
                entry = Api::V2::Crud.base(Expense, current_user).find(params[:id])
                authorize!(:update, entry)
                protect_approved_expense!(entry)
                resubmit_rejected_expense(entry)
                attach_expense_receipt(entry)
                entry.save!
                present entry, with: Api::V2::Crud.resources.fetch(Expense).entity
              end

              desc 'Receipt metadata and content (404 when none attached)'
              get :receipt do
                entry = Api::V2::Crud.base(Expense, current_user).find(params[:id])
                authorize!(:show, entry)
                receipt = entry.receipt
                error!({ error: 'Not found' }, 404) unless receipt.attached?

                { filename: receipt.filename.to_s, content_type: receipt.content_type,
                  byte_size: receipt.byte_size, page_count: receipt.metadata[:page_count],
                  data_base64: [receipt.download].pack('m0') }
              end

              desc 'Review an expense (management). Sets reviewer and reviewed_at; only pending or ' \
                   'deferred expenses can be reviewed. reimbursement_date is ignored when rejecting.',
                   success: Api::V2::Crud.resources.fetch(Expense).entity
              params do
                requires :status, type: String, values: %w[approved rejected deferred]
                optional :reimbursement_date, type: Date
                optional :reason, type: String
              end
              patch :review do
                authorize!(:manage, Expense.new)
                entry = Api::V2::Crud.base(Expense, current_user).find(params[:id])
                review_expense(entry)
                present entry, with: Api::V2::Crud.resources.fetch(Expense).entity
              end
            end
          end
        end

        # Endpoint helpers (included into the Grape endpoint).
        module Helpers
          def protect_approved_expense!(entry)
            return unless entry.approved? && !current_user.management?

            error!({ error: 'Freigegebene Spesen können nicht verändert werden.' }, 403)
          end

          # An owner editing a rejected expense resubmits it (ExpensesController#update).
          def resubmit_rejected_expense(entry)
            return unless entry.rejected? && entry.employee == current_user

            entry.submission_date = Time.zone.today
            entry.status = :pending
          end

          def review_expense(entry)
            error!({ errors: { status: ["#{entry} wurde bereits bearbeitet"] } }, 422) unless entry.pending? || entry.deferred?

            attrs = declared(params, include_missing: false).to_h.symbolize_keys
            attrs.delete(:reimbursement_date) if attrs[:status] == 'rejected'
            entry.assign_attributes(attrs.merge(reviewer: current_user, reviewed_at: Time.zone.now))
            save!(entry)
          end

          def attach_expense_receipt(entry)
            data = decode_receipt(params[:data_base64])
            type = Marcel::MimeType.for(StringIO.new(data))
            receipt_error!("Unsupported file type #{type}") unless RECEIPT_TYPES.include?(type)

            Tempfile.create(['receipt', File.extname(params[:filename])], binmode: true) do |file|
              file.write(data)
              file.flush
              ::Expenses::ReceiptAttacher.new(entry).attach(file, filename: params[:filename], content_type: type)
            end
          rescue Vips::Error
            receipt_error!('File could not be processed')
          end

          def decode_receipt(encoded)
            receipt_error!('Receipt is too large') if encoded.bytesize > (RECEIPT_MAX_BYTES * 4 / 3) + 4
            data = encoded.unpack1('m0')
            receipt_error!('Receipt is too large') if data.bytesize > RECEIPT_MAX_BYTES
            data
          rescue ArgumentError
            receipt_error!('Receipt is not valid base64')
          end

          def receipt_error!(message)
            error!({ errors: { receipt: [message] } }, 422)
          end

          # Replaces EmploymentsController#check_percent / #check_employment_role_uniqueness, evaluated on the
          # assigned entry (rows marked for destruction do not count), plus the previous employment that
          # Employment#update_previous_end_date will close (its save! failure would otherwise be an empty 422).
          def validate_employment!(entry)
            roles = entry.employment_roles_employments.reject(&:marked_for_destruction?)

            entry.errors.add(:percent, 'Funktionsanteile und Beschäftigungsgrad stimmen nicht überein.') if entry.percent && entry.percent != roles.sum { |role| role.percent || 0 }
            ids = roles.map(&:employment_role_id)
            entry.errors.add(:employment_roles_employments, 'Funktionen können nicht doppelt erfasst werden.') if ids.length != ids.uniq.length
            error!({ errors: entry.errors.to_hash }, 422) if entry.errors.any?

            validate_previous_employment!(entry)
          end

          def validate_previous_employment!(entry)
            return unless entry.new_record? && entry.start_date && entry.employee_id

            previous = entry.previous_employment
            return unless previous

            previous.end_date = entry.start_date - 1
            return if previous.valid?

            error!({ errors: { previous_employment: previous.errors.full_messages } }, 422)
          end
        end
      end
    end
  end
end
