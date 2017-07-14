# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170714071631) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absences", force: :cascade do |t|
    t.string  "name",     limit: 255,                 null: false
    t.boolean "payed",                default: false
    t.boolean "private",              default: false
    t.boolean "vacation",             default: false, null: false
  end

  add_index "absences", ["name"], name: "index_absences_on_name", unique: true, using: :btree

  create_table "accounting_posts", force: :cascade do |t|
    t.integer "work_item_id",                                                    null: false
    t.integer "portfolio_item_id"
    t.float   "offered_hours"
    t.decimal "offered_rate",           precision: 12, scale: 2
    t.decimal "offered_total",          precision: 12, scale: 2
    t.integer "remaining_hours"
    t.boolean "billable",                                        default: true,  null: false
    t.boolean "description_required",                            default: false, null: false
    t.boolean "ticket_required",                                 default: false, null: false
    t.boolean "from_to_times_required",                          default: false, null: false
    t.boolean "closed",                                          default: false, null: false
    t.integer "service_id"
  end

  add_index "accounting_posts", ["portfolio_item_id"], name: "index_accounting_posts_on_portfolio_item_id", using: :btree
  add_index "accounting_posts", ["service_id"], name: "index_accounting_posts_on_service_id", using: :btree
  add_index "accounting_posts", ["work_item_id"], name: "index_accounting_posts_on_work_item_id", using: :btree

  create_table "billing_addresses", force: :cascade do |t|
    t.integer "client_id",               null: false
    t.integer "contact_id"
    t.string  "supplement"
    t.string  "street"
    t.string  "zip_code"
    t.string  "town"
    t.string  "country",       limit: 2
    t.string  "invoicing_key"
  end

  add_index "billing_addresses", ["client_id"], name: "index_billing_addresses_on_client_id", using: :btree
  add_index "billing_addresses", ["contact_id"], name: "index_billing_addresses_on_contact_id", using: :btree

  create_table "clients", force: :cascade do |t|
    t.integer "work_item_id",                        null: false
    t.string  "crm_key"
    t.boolean "allow_local",         default: false, null: false
    t.integer "last_invoice_number", default: 0
    t.string  "invoicing_key"
    t.integer "sector_id"
    t.string  "e_bill_account_key"
  end

  add_index "clients", ["sector_id"], name: "index_clients_on_sector_id", using: :btree
  add_index "clients", ["work_item_id"], name: "index_clients_on_work_item_id", using: :btree

  create_table "contacts", force: :cascade do |t|
    t.integer  "client_id",     null: false
    t.string   "lastname"
    t.string   "firstname"
    t.string   "function"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.string   "crm_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invoicing_key"
  end

  add_index "contacts", ["client_id"], name: "index_contacts_on_client_id", using: :btree

  create_table "contracts", force: :cascade do |t|
    t.string  "number",         null: false
    t.date    "start_date",     null: false
    t.date    "end_date",       null: false
    t.integer "payment_period", null: false
    t.text    "reference"
    t.text    "sla"
    t.text    "notes"
  end

  create_table "custom_lists", force: :cascade do |t|
    t.string  "name",        null: false
    t.integer "employee_id"
    t.string  "item_type",   null: false
    t.integer "item_ids",    null: false, array: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.string   "cron"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "departments", force: :cascade do |t|
    t.string "name",      limit: 255, null: false
    t.string "shortname", limit: 3,   null: false
  end

  add_index "departments", ["name"], name: "index_departments_on_name", unique: true, using: :btree
  add_index "departments", ["shortname"], name: "index_departments_on_shortname", unique: true, using: :btree

  create_table "employees", force: :cascade do |t|
    t.string  "firstname",                 limit: 255,                 null: false
    t.string  "lastname",                  limit: 255,                 null: false
    t.string  "shortname",                 limit: 3,                   null: false
    t.string  "passwd",                    limit: 255
    t.string  "email",                     limit: 255,                 null: false
    t.boolean "management",                            default: false
    t.float   "initial_vacation_days"
    t.string  "ldapname",                  limit: 255
    t.string  "eval_periods",              limit: 3,                                array: true
    t.integer "department_id"
    t.date    "committed_worktimes_at"
    t.date    "probation_period_end_date"
    t.string  "phone_office"
    t.string  "phone_private"
    t.string  "street"
    t.string  "postal_code"
    t.string  "city"
    t.date    "birthday"
    t.string  "emergency_contact_name"
    t.string  "emergency_contact_phone"
    t.integer "marital_status"
    t.string  "social_insurance"
    t.string  "crm_key"
    t.text    "additional_information"
    t.date    "reviewed_worktimes_at"
  end

  add_index "employees", ["department_id"], name: "index_employees_on_department_id", using: :btree
  add_index "employees", ["shortname"], name: "chk_unique_name", unique: true, using: :btree

  create_table "employees_invoices", id: false, force: :cascade do |t|
    t.integer "employee_id"
    t.integer "invoice_id"
  end

  add_index "employees_invoices", ["employee_id"], name: "index_employees_invoices_on_employee_id", using: :btree
  add_index "employees_invoices", ["invoice_id"], name: "index_employees_invoices_on_invoice_id", using: :btree

  create_table "employment_role_categories", force: :cascade do |t|
    t.string "name", null: false
  end

  add_index "employment_role_categories", ["name"], name: "index_employment_role_categories_on_name", unique: true, using: :btree

  create_table "employment_role_levels", force: :cascade do |t|
    t.string "name", null: false
  end

  add_index "employment_role_levels", ["name"], name: "index_employment_role_levels_on_name", unique: true, using: :btree

  create_table "employment_roles", force: :cascade do |t|
    t.string  "name",                        null: false
    t.boolean "billable",                    null: false
    t.boolean "level",                       null: false
    t.integer "employment_role_category_id"
  end

  add_index "employment_roles", ["name"], name: "index_employment_roles_on_name", unique: true, using: :btree

  create_table "employment_roles_employments", force: :cascade do |t|
    t.integer "employment_id",                                    null: false
    t.integer "employment_role_id",                               null: false
    t.integer "employment_role_level_id"
    t.decimal "percent",                  precision: 5, scale: 2, null: false
  end

  add_index "employment_roles_employments", ["employment_id", "employment_role_id"], name: "index_unique_employment_employment_role", unique: true, using: :btree

  create_table "employments", force: :cascade do |t|
    t.integer "employee_id"
    t.decimal "percent",                precision: 5, scale: 2, null: false
    t.date    "start_date",                                     null: false
    t.date    "end_date"
    t.decimal "vacation_days_per_year", precision: 5, scale: 2
    t.string  "comment"
  end

  add_index "employments", ["employee_id"], name: "index_employments_on_employee_id", using: :btree

  create_table "holidays", force: :cascade do |t|
    t.date  "holiday_date",  null: false
    t.float "musthours_day", null: false
  end

  add_index "holidays", ["holiday_date"], name: "index_holidays_on_holiday_date", unique: true, using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "order_id",                                                   null: false
    t.date     "billing_date",                                               null: false
    t.date     "due_date",                                                   null: false
    t.decimal  "total_amount",       precision: 12, scale: 2,                null: false
    t.float    "total_hours",                                                null: false
    t.string   "reference",                                                  null: false
    t.date     "period_from",                                                null: false
    t.date     "period_to",                                                  null: false
    t.string   "status",                                                     null: false
    t.boolean  "add_vat",                                     default: true, null: false
    t.integer  "billing_address_id",                                         null: false
    t.string   "invoicing_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grouping",                                    default: 0,    null: false
  end

  add_index "invoices", ["billing_address_id"], name: "index_invoices_on_billing_address_id", using: :btree
  add_index "invoices", ["order_id"], name: "index_invoices_on_order_id", using: :btree

  create_table "invoices_work_items", id: false, force: :cascade do |t|
    t.integer "work_item_id"
    t.integer "invoice_id"
  end

  add_index "invoices_work_items", ["invoice_id"], name: "index_invoices_work_items_on_invoice_id", using: :btree
  add_index "invoices_work_items", ["work_item_id"], name: "index_invoices_work_items_on_work_item_id", using: :btree

  create_table "order_comments", force: :cascade do |t|
    t.integer  "order_id",   null: false
    t.text     "text",       null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_comments", ["order_id"], name: "index_order_comments_on_order_id", using: :btree

  create_table "order_contacts", primary_key: "false", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.integer "order_id",   null: false
    t.string  "comment"
  end

  add_index "order_contacts", ["contact_id"], name: "index_order_contacts_on_contact_id", using: :btree
  add_index "order_contacts", ["order_id"], name: "index_order_contacts_on_order_id", using: :btree

  create_table "order_kinds", force: :cascade do |t|
    t.string "name", null: false
  end

  add_index "order_kinds", ["name"], name: "index_order_kinds_on_name", unique: true, using: :btree

  create_table "order_statuses", force: :cascade do |t|
    t.string  "name",                     null: false
    t.string  "style"
    t.boolean "closed",   default: false, null: false
    t.integer "position",                 null: false
  end

  add_index "order_statuses", ["name"], name: "index_order_statuses_on_name", unique: true, using: :btree
  add_index "order_statuses", ["position"], name: "index_order_statuses_on_position", using: :btree

  create_table "order_targets", force: :cascade do |t|
    t.integer  "order_id",                          null: false
    t.integer  "target_scope_id",                   null: false
    t.string   "rating",          default: "green", null: false
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_targets", ["order_id"], name: "index_order_targets_on_order_id", using: :btree
  add_index "order_targets", ["target_scope_id"], name: "index_order_targets_on_target_scope_id", using: :btree

  create_table "order_team_members", primary_key: "false", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "order_id",    null: false
    t.string  "comment"
  end

  add_index "order_team_members", ["employee_id"], name: "index_order_team_members_on_employee_id", using: :btree
  add_index "order_team_members", ["order_id"], name: "index_order_team_members_on_order_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "work_item_id",       null: false
    t.integer  "kind_id"
    t.integer  "responsible_id"
    t.integer  "status_id"
    t.integer  "department_id"
    t.integer  "contract_id"
    t.integer  "billing_address_id"
    t.string   "crm_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "completed_at"
    t.date     "committed_at"
    t.date     "closed_at"
  end

  add_index "orders", ["billing_address_id"], name: "index_orders_on_billing_address_id", using: :btree
  add_index "orders", ["contract_id"], name: "index_orders_on_contract_id", using: :btree
  add_index "orders", ["department_id"], name: "index_orders_on_department_id", using: :btree
  add_index "orders", ["kind_id"], name: "index_orders_on_kind_id", using: :btree
  add_index "orders", ["responsible_id"], name: "index_orders_on_responsible_id", using: :btree
  add_index "orders", ["status_id"], name: "index_orders_on_status_id", using: :btree
  add_index "orders", ["work_item_id"], name: "index_orders_on_work_item_id", using: :btree

  create_table "overtime_vacations", force: :cascade do |t|
    t.float   "hours",         null: false
    t.integer "employee_id",   null: false
    t.date    "transfer_date", null: false
  end

  add_index "overtime_vacations", ["employee_id"], name: "index_overtime_vacations_on_employee_id", using: :btree

  create_table "plannings", force: :cascade do |t|
    t.integer "employee_id",                  null: false
    t.integer "work_item_id",                 null: false
    t.date    "date",                         null: false
    t.integer "percent",                      null: false
    t.boolean "definitive",   default: false, null: false
  end

  add_index "plannings", ["employee_id", "work_item_id", "date"], name: "index_plannings_on_employee_id_and_work_item_id_and_date", unique: true, using: :btree
  add_index "plannings", ["employee_id"], name: "index_plannings_on_employee_id", using: :btree
  add_index "plannings", ["work_item_id"], name: "index_plannings_on_work_item_id", using: :btree

  create_table "portfolio_items", force: :cascade do |t|
    t.string  "name",                  null: false
    t.boolean "active", default: true, null: false
  end

  add_index "portfolio_items", ["name"], name: "index_portfolio_items_on_name", unique: true, using: :btree

  create_table "sectors", force: :cascade do |t|
    t.string  "name",                  null: false
    t.boolean "active", default: true, null: false
  end

  create_table "services", force: :cascade do |t|
    t.string  "name",                  null: false
    t.boolean "active", default: true, null: false
  end

  create_table "target_scopes", force: :cascade do |t|
    t.string  "name",                      null: false
    t.string  "icon"
    t.integer "position",                  null: false
    t.string  "rating_green_description"
    t.string  "rating_orange_description"
    t.string  "rating_red_description"
  end

  add_index "target_scopes", ["name"], name: "index_target_scopes_on_name", unique: true, using: :btree
  add_index "target_scopes", ["position"], name: "index_target_scopes_on_position", using: :btree

  create_table "user_notifications", force: :cascade do |t|
    t.date "date_from", null: false
    t.date "date_to"
    t.text "message",   null: false
  end

  add_index "user_notifications", ["date_from", "date_to"], name: "index_user_notifications_on_date_from_and_date_to", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "work_items", force: :cascade do |t|
    t.integer "parent_id"
    t.string  "name",                                         null: false
    t.string  "shortname",       limit: 5,                    null: false
    t.text    "description"
    t.integer "path_ids",                                                  array: true
    t.string  "path_shortnames"
    t.string  "path_names",      limit: 2047
    t.boolean "leaf",                         default: true,  null: false
    t.boolean "closed",                       default: false, null: false
  end

  add_index "work_items", ["parent_id"], name: "index_work_items_on_parent_id", using: :btree
  add_index "work_items", ["path_ids"], name: "index_work_items_on_path_ids", using: :btree

  create_table "working_conditions", force: :cascade do |t|
    t.date    "valid_from"
    t.decimal "vacation_days_per_year", precision: 5, scale: 2, null: false
    t.decimal "must_hours_per_day",     precision: 4, scale: 2, null: false
  end

  create_table "worktimes", force: :cascade do |t|
    t.integer "absence_id"
    t.integer "employee_id"
    t.string  "report_type",     limit: 255,                null: false
    t.date    "work_date",                                  null: false
    t.float   "hours"
    t.time    "from_start_time"
    t.time    "to_end_time"
    t.text    "description"
    t.boolean "billable",                    default: true
    t.string  "type",            limit: 255
    t.string  "ticket",          limit: 255
    t.integer "work_item_id"
    t.integer "invoice_id"
  end

  add_index "worktimes", ["absence_id", "employee_id", "work_date"], name: "worktimes_absences", using: :btree
  add_index "worktimes", ["employee_id", "work_date"], name: "worktimes_employees", using: :btree
  add_index "worktimes", ["invoice_id"], name: "index_worktimes_on_invoice_id", using: :btree
  add_index "worktimes", ["work_item_id", "employee_id", "work_date"], name: "worktimes_work_items", using: :btree

  add_foreign_key "employments", "employees", name: "fk_employments_employees", on_delete: :cascade
  add_foreign_key "worktimes", "absences", name: "fk_times_absences", on_delete: :cascade
  add_foreign_key "worktimes", "employees", name: "fk_times_employees", on_delete: :cascade
end
