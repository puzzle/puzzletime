# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CreateTables < ActiveRecord::Migration[5.1]
  def change
    create_table 'absences' do |t|
      t.string 'name', limit: 255, null: false
      t.boolean 'payed',                default: false
      t.boolean 'private',              default: false
      t.boolean 'vacation',             default: false, null: false
    end

    add_index 'absences', ['name'], name: 'index_absences_on_name', unique: true

    create_table 'accounting_posts' do |t|
      t.integer 'work_item_id', null: false
      t.integer 'portfolio_item_id'
      t.float 'offered_hours'
      t.decimal 'offered_rate',           precision: 12, scale: 2
      t.decimal 'offered_total',          precision: 12, scale: 2
      t.integer 'remaining_hours'
      t.boolean 'billable',                                        default: true,  null: false
      t.boolean 'description_required',                            default: false, null: false
      t.boolean 'ticket_required',                                 default: false, null: false
      t.boolean 'closed',                                          default: false, null: false
      t.boolean 'from_to_times_required',                          default: false, null: false
    end

    add_index 'accounting_posts', ['portfolio_item_id'], name: 'index_accounting_posts_on_portfolio_item_id'
    add_index 'accounting_posts', ['work_item_id'], name: 'index_accounting_posts_on_work_item_id'

    create_table 'billing_addresses' do |t|
      t.integer 'client_id', null: false
      t.integer 'contact_id'
      t.string 'supplement',    limit: 255
      t.string 'street',        limit: 255
      t.string 'zip_code',      limit: 255
      t.string 'town',          limit: 255
      t.string 'country',       limit: 2
      t.string 'invoicing_key'
    end

    add_index 'billing_addresses', ['client_id'], name: 'index_billing_addresses_on_client_id'
    add_index 'billing_addresses', ['contact_id'], name: 'index_billing_addresses_on_contact_id'

    create_table 'clients' do |t|
      t.integer 'work_item_id', null: false
      t.string 'crm_key', limit: 255
      t.boolean 'allow_local',                     default: false, null: false
      t.integer 'last_invoice_number',             default: 0
      t.string 'invoicing_key'
    end

    add_index 'clients', ['work_item_id'], name: 'index_clients_on_work_item_id'

    create_table 'contacts' do |t|
      t.integer 'client_id', null: false
      t.string 'lastname',      limit: 255
      t.string 'firstname',     limit: 255
      t.string 'function',      limit: 255
      t.string 'email',         limit: 255
      t.string 'phone',         limit: 255
      t.string 'mobile',        limit: 255
      t.string 'crm_key',       limit: 255
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'invoicing_key'
    end

    add_index 'contacts', ['client_id'], name: 'index_contacts_on_client_id'

    create_table 'contracts' do |t|
      t.string 'number', limit: 255, null: false
      t.date 'start_date',                 null: false
      t.date 'end_date',                   null: false
      t.integer 'payment_period', null: false
      t.text 'reference'
      t.text 'sla'
      t.text 'notes'
    end

    create_table 'delayed_jobs' do |t|
      t.integer 'priority',               default: 0, null: false
      t.integer 'attempts',               default: 0, null: false
      t.text 'handler',                            null: false
      t.text 'last_error'
      t.datetime 'run_at'
      t.datetime 'locked_at'
      t.datetime 'failed_at'
      t.string 'locked_by',  limit: 255
      t.string 'queue',      limit: 255
      t.string 'cron',       limit: 255
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'delayed_jobs', %w[priority run_at], name: 'delayed_jobs_priority'

    create_table 'departments' do |t|
      t.string 'name',      limit: 255, null: false
      t.string 'shortname', limit: 3,   null: false
    end

    add_index 'departments', ['name'], name: 'index_departments_on_name', unique: true
    add_index 'departments', ['shortname'], name: 'index_departments_on_shortname', unique: true

    create_table 'employee_lists' do |t|
      t.integer 'employee_id', null: false
      t.string 'title', limit: 255, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'employee_lists', ['employee_id'], name: 'index_employee_lists_on_employee_id'

    create_table 'employee_lists_employees', id: false do |t|
      t.integer 'employee_list_id'
      t.integer 'employee_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'employee_lists_employees', ['employee_id'], name: 'index_employee_lists_employees_on_employee_id'
    add_index 'employee_lists_employees', ['employee_list_id'],
              name: 'index_employee_lists_employees_on_employee_list_id'

    create_table 'employees' do |t|
      t.string 'firstname',             limit: 255,                 null: false
      t.string 'lastname',              limit: 255,                 null: false
      t.string 'shortname',             limit: 3,                   null: false
      t.string 'passwd',                limit: 255
      t.string 'email',                 limit: 255, null: false
      t.boolean 'management', default: false
      t.float 'initial_vacation_days'
      t.string 'ldapname', limit: 255
      t.string 'eval_periods', array: true
      t.integer 'department_id'
    end

    add_index 'employees', ['department_id'], name: 'index_employees_on_department_id'
    add_index 'employees', ['shortname'], name: 'chk_unique_name', unique: true

    create_table 'employees_invoices', id: false do |t|
      t.integer 'employee_id'
      t.integer 'invoice_id'
    end

    add_index 'employees_invoices', ['employee_id'], name: 'index_employees_invoices_on_employee_id'
    add_index 'employees_invoices', ['invoice_id'], name: 'index_employees_invoices_on_invoice_id'

    create_table 'employments' do |t|
      t.integer 'employee_id'
      t.decimal 'percent', precision: 5, scale: 2, null: false
      t.date 'start_date', null: false
      t.date 'end_date'
    end

    add_index 'employments', ['employee_id'], name: 'index_employments_on_employee_id'

    create_table 'holidays' do |t|
      t.date 'holiday_date', null: false
      t.float 'musthours_day', null: false
    end

    add_index 'holidays', ['holiday_date'], name: 'index_holidays_on_holiday_date', unique: true

    create_table 'invoices' do |t|
      t.integer 'order_id', null: false
      t.date 'billing_date',                                               null: false
      t.date 'due_date',                                                   null: false
      t.decimal 'total_amount', precision: 12, scale: 2, null: false
      t.float 'total_hours', null: false
      t.string 'reference', null: false
      t.date 'period_from',                                                null: false
      t.date 'period_to',                                                  null: false
      t.string 'status', null: false
      t.boolean 'add_vat', default: true, null: false
      t.integer 'billing_address_id', null: false
      t.string 'invoicing_key'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.integer 'grouping', default: 0, null: false
    end

    add_index 'invoices', ['billing_address_id'], name: 'index_invoices_on_billing_address_id'
    add_index 'invoices', ['order_id'], name: 'index_invoices_on_order_id'

    create_table 'invoices_work_items', id: false do |t|
      t.integer 'work_item_id'
      t.integer 'invoice_id'
    end

    add_index 'invoices_work_items', ['invoice_id'], name: 'index_invoices_work_items_on_invoice_id'
    add_index 'invoices_work_items', ['work_item_id'], name: 'index_invoices_work_items_on_work_item_id'

    create_table 'order_comments' do |t|
      t.integer 'order_id', null: false
      t.text 'text', null: false
      t.integer 'creator_id'
      t.integer 'updater_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'order_comments', ['order_id'], name: 'index_order_comments_on_order_id'

    create_table 'order_contacts', primary_key: 'false' do |t|
      t.integer 'contact_id',             null: false
      t.integer 'order_id',               null: false
      t.string 'comment', limit: 255
    end

    add_index 'order_contacts', ['contact_id'], name: 'index_order_contacts_on_contact_id'
    add_index 'order_contacts', ['order_id'], name: 'index_order_contacts_on_order_id'

    create_table 'order_kinds' do |t|
      t.string 'name', limit: 255, null: false
    end

    add_index 'order_kinds', ['name'], name: 'index_order_kinds_on_name', unique: true

    create_table 'order_statuses' do |t|
      t.string 'name',     limit: 255, null: false
      t.string 'style',    limit: 255
      t.boolean 'closed', default: false, null: false
      t.integer 'position', null: false
    end

    add_index 'order_statuses', ['name'], name: 'index_order_statuses_on_name', unique: true
    add_index 'order_statuses', ['position'], name: 'index_order_statuses_on_position'

    create_table 'order_targets' do |t|
      t.integer 'order_id',                                      null: false
      t.integer 'target_scope_id',                               null: false
      t.string 'rating', limit: 255, default: 'green', null: false
      t.text 'comment'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'order_targets', ['order_id'], name: 'index_order_targets_on_order_id'
    add_index 'order_targets', ['target_scope_id'], name: 'index_order_targets_on_target_scope_id'

    create_table 'order_team_members', primary_key: 'false' do |t|
      t.integer 'employee_id',             null: false
      t.integer 'order_id',                null: false
      t.string 'comment', limit: 255
    end

    add_index 'order_team_members', ['employee_id'], name: 'index_order_team_members_on_employee_id'
    add_index 'order_team_members', ['order_id'], name: 'index_order_team_members_on_order_id'

    create_table 'orders' do |t|
      t.integer 'work_item_id', null: false
      t.integer 'kind_id'
      t.integer 'responsible_id'
      t.integer 'status_id'
      t.integer 'department_id'
      t.integer 'contract_id'
      t.integer 'billing_address_id'
      t.string 'crm_key', limit: 255
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'orders', ['billing_address_id'], name: 'index_orders_on_billing_address_id'
    add_index 'orders', ['contract_id'], name: 'index_orders_on_contract_id'
    add_index 'orders', ['department_id'], name: 'index_orders_on_department_id'
    add_index 'orders', ['kind_id'], name: 'index_orders_on_kind_id'
    add_index 'orders', ['responsible_id'], name: 'index_orders_on_responsible_id'
    add_index 'orders', ['status_id'], name: 'index_orders_on_status_id'
    add_index 'orders', ['work_item_id'], name: 'index_orders_on_work_item_id'

    create_table 'overtime_vacations' do |t|
      t.float 'hours', null: false
      t.integer 'employee_id', null: false
      t.date 'transfer_date', null: false
    end

    add_index 'overtime_vacations', ['employee_id'], name: 'index_overtime_vacations_on_employee_id'

    create_table 'plannings' do |t|
      t.integer 'employee_id',                     null: false
      t.integer 'start_week',                      null: false
      t.integer 'end_week'
      t.boolean 'definitive', default: false, null: false
      t.text 'description'
      t.boolean 'monday_am',       default: false, null: false
      t.boolean 'monday_pm',       default: false, null: false
      t.boolean 'tuesday_am',      default: false, null: false
      t.boolean 'tuesday_pm',      default: false, null: false
      t.boolean 'wednesday_am',    default: false, null: false
      t.boolean 'wednesday_pm',    default: false, null: false
      t.boolean 'thursday_am',     default: false, null: false
      t.boolean 'thursday_pm',     default: false, null: false
      t.boolean 'friday_am',       default: false, null: false
      t.boolean 'friday_pm',       default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'is_abstract'
      t.decimal 'abstract_amount'
      t.integer 'work_item_id', null: false
    end

    add_index 'plannings', ['employee_id'], name: 'index_plannings_on_employee_id'
    add_index 'plannings', ['work_item_id'], name: 'index_plannings_on_work_item_id'

    create_table 'portfolio_items' do |t|
      t.string 'name', limit: 255, null: false
      t.boolean 'active', default: true, null: false
    end

    add_index 'portfolio_items', ['name'], name: 'index_portfolio_items_on_name', unique: true

    create_table 'target_scopes' do |t|
      t.string 'name',     limit: 255, null: false
      t.string 'icon',     limit: 255
      t.integer 'position', null: false
    end

    add_index 'target_scopes', ['name'], name: 'index_target_scopes_on_name', unique: true
    add_index 'target_scopes', ['position'], name: 'index_target_scopes_on_position'

    create_table 'user_notifications' do |t|
      t.date 'date_from', null: false
      t.date 'date_to'
      t.text 'message', null: false
    end

    add_index 'user_notifications', %w[date_from date_to], name: 'index_user_notifications_on_date_from_and_date_to'

    create_table 'work_items' do |t|
      t.integer 'parent_id'
      t.string 'name',            limit: 255,                  null: false
      t.string 'shortname',       limit: 5,                    null: false
      t.text 'description'
      t.integer 'path_ids', array: true
      t.string 'path_shortnames', limit: 255
      t.string 'path_names',      limit: 2047
      t.boolean 'leaf',                         default: true,  null: false
      t.boolean 'closed',                       default: false, null: false
    end

    add_index 'work_items', ['parent_id'], name: 'index_work_items_on_parent_id'
    add_index 'work_items', ['path_ids'], name: 'index_work_items_on_path_ids'

    create_table 'working_conditions' do |t|
      t.date 'valid_from'
      t.decimal 'vacation_days_per_year', precision: 5, scale: 2, null: false
      t.decimal 'must_hours_per_day',     precision: 4, scale: 2, null: false
    end

    create_table 'worktimes' do |t|
      t.integer 'absence_id'
      t.integer 'employee_id'
      t.string 'report_type', limit: 255, null: false
      t.date 'work_date', null: false
      t.float 'hours'
      t.time 'from_start_time'
      t.time 'to_end_time'
      t.text 'description'
      t.boolean 'billable',                    default: true
      t.boolean 'booked',                      default: false
      t.string 'type',            limit: 255
      t.string 'ticket',          limit: 255
      t.integer 'work_item_id'
      t.integer 'invoice_id'
    end

    add_index 'worktimes', %w[absence_id employee_id work_date], name: 'worktimes_absences'
    add_index 'worktimes', %w[employee_id work_date], name: 'worktimes_employees'
    add_index 'worktimes', ['invoice_id'], name: 'index_worktimes_on_invoice_id'
    add_index 'worktimes', %w[work_item_id employee_id work_date], name: 'worktimes_work_items'

    add_foreign_key 'employments', 'employees', name: 'fk_employments_employees', on_delete: :cascade
    add_foreign_key 'worktimes', 'absences', name: 'fk_times_absences', on_delete: :cascade
    add_foreign_key 'worktimes', 'employees', name: 'fk_times_employees', on_delete: :cascade
  end
end
