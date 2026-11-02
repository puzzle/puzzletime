# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # Plain-JSON API covering the domain models, mounted at /api/v2. Swagger spec: /api/v2/swagger_doc.
    #
    # Authentication: HTTP Basic with the shared API client credentials, or the employee's
    # Devise session. Authorization: `Ability`. Add a model by adding a `crud` line below;
    # see Api::V2::Crud.
    class Root < Grape::API
      extend Crud

      format :json
      content_type :json, 'application/json'

      helpers do
        params :pagination do
          optional :page, type: Integer
          optional :per_page, type: Integer, values: 1..100
        end

        def current_user
          basic = Rack::Auth::Basic::Request.new(env)
          @current_user ||= if basic.provided? && basic.basic?
                              ApiClient.new.authenticate(*basic.credentials)
                            else
                              env['warden'].user(:employee)
                            end
        end

        def authorize!(action, subject)
          (@ability ||= Ability.new(current_user)).authorize!(action, subject)
        end

        # Attributes from the request that this user may assign. Declared-but-forbidden ones are a 403.
        def writable(res, creating:)
          allowed = (res.writable_by ? res.writable_by.call(current_user) : res.write) + res.nested.keys
          allowed += res.create_only if creating
          given = declared(params, include_missing: false).to_h.symbolize_keys
          forbidden = (given.keys & (res.write + res.create_only)) - allowed
          error!({ error: "Not allowed to set: #{forbidden.join(', ')}" }, 403) if forbidden.any?

          given.slice(*allowed)
        end

        def save!(entry)
          error!({ errors: entry.errors.to_hash }, 422) unless entry.save
        end

        def paginate(scope)
          entries = scope.page(params[:page]).per(params[:per_page])
          header 'Pagination-Total-Count', entries.total_count.to_s
          header 'Pagination-Per-Page', entries.limit_value.to_s
          header 'Pagination-Current-Page', entries.current_page.to_s
          header 'Pagination-Total-Pages', entries.total_pages.to_s
          entries
        end
      end

      before do
        error!({ error: 'Unauthorized' }, 401) unless current_user
        json_request = request.get? || request.delete? || request.media_type == 'application/json'
        # Session cookies are sent cross-site; a JSON content type cannot be forged by a plain form post.
        error!({ error: 'Content-Type must be application/json' }, 415) unless json_request
        PaperTrail.request.whodunnit = current_user.id
      end

      rescue_from(ActiveRecord::RecordNotFound) { error!({ error: 'Not found' }, 404) }
      rescue_from(CanCan::AccessDenied) { error!({ error: 'Forbidden' }, 403) }
      rescue_from(ActiveRecord::RecordInvalid) { |e| error!({ errors: e.record.errors.to_hash }, 422) }

      # Registry. Omit `write` for read-only resources.
      crud Absence,
           read: %i[id name payed vacation], write: %i[name payed vacation]
      crud BillingAddress,
           read: %i[id client_id contact_id supplement street zip_code town country],
           write: %i[client_id contact_id supplement street zip_code town country],
           relationships: %i[client contact]
      crud Client,
           read: %i[id crm_key allow_local sector_id e_bill_account_key work_item_id],
           relationships: %i[sector contacts billing_addresses]
      crud Contact,
           read: %i[id client_id lastname firstname function email phone mobile crm_key],
           write: %i[client_id lastname firstname function email phone mobile crm_key],
           relationships: %i[client billing_addresses]
      crud Department,
           read: %i[id name shortname], write: %i[name shortname], relationships: %i[employees]
      crud Employee,
           read: %i[id firstname lastname shortname department_id workplace_id],
           relationships: %i[department workplace]
      crud EmploymentRole,
           read: %i[id name billable level employment_role_category_id],
           write: %i[name billable level employment_role_category_id],
           relationships: %i[employment_role_category]
      crud EmploymentRoleCategory,
           read: %i[id name], write: %i[name], relationships: %i[employment_roles]
      crud EmploymentRoleLevel,
           read: %i[id name], write: %i[name]
      crud Holiday,
           read: %i[id holiday_date musthours_day], write: %i[holiday_date musthours_day]
      crud OrderKind,
           read: %i[id name], write: %i[name]
      crud OrderStatus,
           read: %i[id name style closed position default], write: %i[name style closed position default]
      crud PortfolioItem,
           read: %i[id name active], write: %i[name active]
      crud Sector,
           read: %i[id name active], write: %i[name active], relationships: %i[clients]
      crud Service,
           read: %i[id name active], write: %i[name active]
      crud TargetScope,
           read: %i[id name icon position rating_green_description rating_orange_description rating_red_description],
           write: %i[name icon position rating_green_description rating_orange_description rating_red_description]
      crud UserNotification,
           read: %i[id date_from date_to message], write: %i[date_from date_to message]
      crud WorkingCondition,
           read: %i[id valid_from vacation_days_per_year must_hours_per_day],
           write: %i[valid_from vacation_days_per_year must_hours_per_day]
      crud Workplace,
           read: %i[id name], write: %i[name]

      # Resources with rules beyond plain CRUD, one module each.
      Resources::TimeEntries.call(self)
      Resources::Expenses.call(self)
      Resources::Orders.call(self)
      Resources::Accounting.call(self)

      generate_crud_routes

      add_swagger_documentation info: { title: 'PuzzleTime API', version: 'v2' },
                                security_definitions: { basic: { type: 'basic' } },
                                security: [{ basic: [] }],
                                hide_documentation_path: true
    end
  end
end
