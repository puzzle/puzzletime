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

ActiveRecord::Schema.define(version: 2022_03_24_143608) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absences", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.boolean "payed", default: false
    t.boolean "vacation", default: false, null: false
    t.index ["name"], name: "index_absences_on_name", unique: true
  end

  create_table "accounting_posts", force: :cascade do |t|
    t.integer "work_item_id", null: false
    t.integer "portfolio_item_id"
    t.float "offered_hours"
    t.decimal "offered_rate", precision: 12, scale: 2
    t.decimal "offered_total", precision: 12, scale: 2
    t.integer "remaining_hours"
    t.boolean "billable", default: true, null: false
    t.boolean "description_required", default: false, null: false
    t.boolean "ticket_required", default: false, null: false
    t.boolean "closed", default: false, null: false
    t.boolean "from_to_times_required", default: false, null: false
    t.integer "service_id"
    t.boolean "meal_compensation", default: false, null: false
    t.index ["portfolio_item_id"], name: "index_accounting_posts_on_portfolio_item_id"
    t.index ["service_id"], name: "index_accounting_posts_on_service_id"
    t.index ["work_item_id"], name: "index_accounting_posts_on_work_item_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "additional_crm_orders", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "crm_key", null: false
    t.string "name"
    t.index ["order_id"], name: "index_additional_crm_orders_on_order_id"
  end

  create_table "authentications", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.string "token_secret"
    t.bigint "employee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_authentications_on_employee_id"
  end

  create_table "billing_addresses", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "contact_id"
    t.string "supplement", limit: 255
    t.string "street", limit: 255
    t.string "zip_code", limit: 255
    t.string "town", limit: 255
    t.string "country", limit: 2
    t.string "invoicing_key"
    t.index ["client_id"], name: "index_billing_addresses_on_client_id"
    t.index ["contact_id"], name: "index_billing_addresses_on_contact_id"
  end

  create_table "clients", force: :cascade do |t|
    t.integer "work_item_id", null: false
    t.string "crm_key", limit: 255
    t.boolean "allow_local", default: false, null: false
    t.integer "last_invoice_number", default: 0
    t.string "invoicing_key"
    t.integer "sector_id"
    t.string "e_bill_account_key"
    t.index ["sector_id"], name: "index_clients_on_sector_id"
    t.index ["work_item_id"], name: "index_clients_on_work_item_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "lastname", limit: 255
    t.string "firstname", limit: 255
    t.string "function", limit: 255
    t.string "email", limit: 255
    t.string "phone", limit: 255
    t.string "mobile", limit: 255
    t.string "crm_key", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "invoicing_key"
    t.index ["client_id"], name: "index_contacts_on_client_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.string "number", limit: 255, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "payment_period", null: false
    t.text "reference"
    t.text "sla"
    t.text "notes"
  end

  create_table "custom_lists", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "employee_id"
    t.string "item_type", null: false
    t.integer "item_ids", null: false, array: true
    t.index ["employee_id"], name: "index_custom_lists_on_employee_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by", limit: 255
    t.string "queue", limit: 255
    t.string "cron", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "shortname", limit: 3, null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
    t.index ["shortname"], name: "index_departments_on_shortname", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "firstname", limit: 255, null: false
    t.string "lastname", limit: 255, null: false
    t.string "shortname", limit: 3, null: false
    t.string "passwd", limit: 255
    t.string "email", limit: 255, null: false
    t.boolean "management", default: false
    t.float "initial_vacation_days"
    t.string "ldapname", limit: 255
    t.string "eval_periods", array: true
    t.integer "department_id"
    t.date "committed_worktimes_at"
    t.date "probation_period_end_date"
    t.string "phone_office"
    t.string "phone_private"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.date "birthday"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.integer "marital_status"
    t.string "social_insurance"
    t.string "crm_key"
    t.text "additional_information"
    t.date "reviewed_worktimes_at"
    t.string "nationalities", array: true
    t.string "graduation"
    t.string "identity_card_type"
    t.date "identity_card_valid_until"
    t.string "encrypted_password", default: ""
    t.datetime "remember_created_at"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.bigint "workplace_id"
    t.boolean "worktimes_commit_reminder", default: true, null: false
    t.boolean "worktimes_reminder", default: false, null: false
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["shortname"], name: "chk_unique_name", unique: true
    t.index ["workplace_id"], name: "index_employees_on_workplace_id"
  end

  create_table "employees_invoices", id: false, force: :cascade do |t|
    t.integer "employee_id"
    t.integer "invoice_id"
    t.index ["employee_id"], name: "index_employees_invoices_on_employee_id"
    t.index ["invoice_id"], name: "index_employees_invoices_on_invoice_id"
  end

  create_table "employment_role_categories", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_employment_role_categories_on_name", unique: true
  end

  create_table "employment_role_levels", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_employment_role_levels_on_name", unique: true
  end

  create_table "employment_roles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "billable", null: false
    t.boolean "level", null: false
    t.bigint "employment_role_category_id"
    t.index ["employment_role_category_id"], name: "index_employment_roles_on_employment_role_category_id"
    t.index ["name"], name: "index_employment_roles_on_name", unique: true
  end

  create_table "employment_roles_employments", force: :cascade do |t|
    t.bigint "employment_id", null: false
    t.bigint "employment_role_id", null: false
    t.bigint "employment_role_level_id"
    t.decimal "percent", precision: 5, scale: 2, null: false
    t.index ["employment_id", "employment_role_id"], name: "index_unique_employment_employment_role", unique: true
    t.index ["employment_id"], name: "index_employment_roles_employments_on_employment_id"
    t.index ["employment_role_id"], name: "index_employment_roles_employments_on_employment_role_id"
    t.index ["employment_role_level_id"], name: "index_employment_roles_employments_on_employment_role_level_id"
  end

  create_table "employments", force: :cascade do |t|
    t.integer "employee_id"
    t.decimal "percent", precision: 5, scale: 2, null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "vacation_days_per_year", precision: 5, scale: 2
    t.string "comment"
    t.index ["employee_id"], name: "index_employments_on_employee_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.integer "kind", null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "payment_date", null: false
    t.text "description", null: false
    t.text "reason"
    t.bigint "reviewer_id"
    t.datetime "reviewed_at"
    t.bigint "order_id"
    t.date "reimbursement_date"
    t.date "submission_date", default: -> { "now()" }
    t.index ["employee_id"], name: "index_expenses_on_employee_id"
    t.index ["order_id"], name: "index_expenses_on_order_id"
    t.index ["reviewer_id"], name: "index_expenses_on_reviewer_id"
    t.index ["status"], name: "index_expenses_on_status"
  end

  create_table "holidays", force: :cascade do |t|
    t.date "holiday_date", null: false
    t.float "musthours_day", null: false
    t.index ["holiday_date"], name: "index_holidays_on_holiday_date", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "order_id", null: false
    t.date "billing_date", null: false
    t.date "due_date", null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.float "total_hours", null: false
    t.string "reference", null: false
    t.date "period_from", null: false
    t.date "period_to", null: false
    t.string "status", null: false
    t.integer "billing_address_id", null: false
    t.string "invoicing_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "grouping", default: 0, null: false
    t.index ["billing_address_id"], name: "index_invoices_on_billing_address_id"
    t.index ["order_id"], name: "index_invoices_on_order_id"
  end

  create_table "invoices_work_items", id: false, force: :cascade do |t|
    t.integer "work_item_id"
    t.integer "invoice_id"
    t.index ["invoice_id"], name: "index_invoices_work_items_on_invoice_id"
    t.index ["work_item_id"], name: "index_invoices_work_items_on_work_item_id"
  end

  create_table "order_comments", force: :cascade do |t|
    t.integer "order_id", null: false
    t.text "text", null: false
    t.integer "creator_id"
    t.integer "updater_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["order_id"], name: "index_order_comments_on_order_id"
  end

  create_table "order_contacts", primary_key: "false", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.integer "order_id", null: false
    t.string "comment", limit: 255
    t.index ["contact_id"], name: "index_order_contacts_on_contact_id"
    t.index ["order_id"], name: "index_order_contacts_on_order_id"
  end

  create_table "order_kinds", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.index ["name"], name: "index_order_kinds_on_name", unique: true
  end

  create_table "order_statuses", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "style", limit: 255
    t.boolean "closed", default: false, null: false
    t.integer "position", null: false
    t.boolean "default", default: false, null: false
    t.index ["name"], name: "index_order_statuses_on_name", unique: true
    t.index ["position"], name: "index_order_statuses_on_position"
  end

  create_table "order_targets", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "target_scope_id", null: false
    t.string "rating", limit: 255, default: "green", null: false
    t.text "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["order_id"], name: "index_order_targets_on_order_id"
    t.index ["target_scope_id"], name: "index_order_targets_on_target_scope_id"
  end

  create_table "order_team_members", primary_key: "false", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "order_id", null: false
    t.string "comment", limit: 255
    t.index ["employee_id"], name: "index_order_team_members_on_employee_id"
    t.index ["order_id"], name: "index_order_team_members_on_order_id"
  end

  create_table "order_uncertainties", id: :serial, force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "type", null: false
    t.string "name", null: false
    t.integer "probability", default: 1, null: false
    t.integer "impact", default: 1, null: false
    t.text "measure"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_uncertainties_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "work_item_id", null: false
    t.integer "kind_id"
    t.integer "responsible_id"
    t.integer "status_id"
    t.integer "department_id"
    t.integer "contract_id"
    t.integer "billing_address_id"
    t.string "crm_key", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "completed_at"
    t.date "committed_at"
    t.date "closed_at"
    t.integer "major_risk_value"
    t.integer "major_chance_value"
    t.index ["billing_address_id"], name: "index_orders_on_billing_address_id"
    t.index ["contract_id"], name: "index_orders_on_contract_id"
    t.index ["department_id"], name: "index_orders_on_department_id"
    t.index ["kind_id"], name: "index_orders_on_kind_id"
    t.index ["responsible_id"], name: "index_orders_on_responsible_id"
    t.index ["status_id"], name: "index_orders_on_status_id"
    t.index ["work_item_id"], name: "index_orders_on_work_item_id"
  end

  create_table "overtime_vacations", force: :cascade do |t|
    t.float "hours", null: false
    t.integer "employee_id", null: false
    t.date "transfer_date", null: false
    t.index ["employee_id"], name: "index_overtime_vacations_on_employee_id"
  end

  create_table "plannings", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "work_item_id", null: false
    t.date "date", null: false
    t.integer "percent", null: false
    t.boolean "definitive", default: false, null: false
    t.index ["employee_id", "work_item_id", "date"], name: "index_plannings_on_employee_id_and_work_item_id_and_date", unique: true
    t.index ["employee_id"], name: "index_plannings_on_employee_id"
    t.index ["work_item_id"], name: "index_plannings_on_work_item_id"
  end

  create_table "portfolio_items", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.boolean "active", default: true, null: false
    t.index ["name"], name: "index_portfolio_items_on_name", unique: true
  end

  create_table "sectors", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
  end

  create_table "target_scopes", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "icon", limit: 255
    t.integer "position", null: false
    t.string "rating_green_description"
    t.string "rating_orange_description"
    t.string "rating_red_description"
    t.index ["name"], name: "index_target_scopes_on_name", unique: true
    t.index ["position"], name: "index_target_scopes_on_position"
  end

  create_table "user_notifications", force: :cascade do |t|
    t.date "date_from", null: false
    t.date "date_to"
    t.text "message", null: false
    t.index ["date_from", "date_to"], name: "index_user_notifications_on_date_from_and_date_to"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.bigint "employee_id"
    t.index ["employee_id"], name: "index_versions_on_employee_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_items", force: :cascade do |t|
    t.integer "parent_id"
    t.string "name", limit: 255, null: false
    t.string "shortname", limit: 5, null: false
    t.text "description"
    t.integer "path_ids", array: true
    t.string "path_shortnames", limit: 255
    t.string "path_names", limit: 2047
    t.boolean "leaf", default: true, null: false
    t.boolean "closed", default: false, null: false
    t.index ["parent_id"], name: "index_work_items_on_parent_id"
    t.index ["path_ids"], name: "index_work_items_on_path_ids"
  end

  create_table "working_conditions", force: :cascade do |t|
    t.date "valid_from"
    t.decimal "vacation_days_per_year", precision: 5, scale: 2, null: false
    t.decimal "must_hours_per_day", precision: 4, scale: 2, null: false
  end

  create_table "workplaces", force: :cascade do |t|
    t.string "name"
  end

  create_table "worktimes", force: :cascade do |t|
    t.integer "absence_id"
    t.integer "employee_id"
    t.string "report_type", limit: 255, null: false
    t.date "work_date", null: false
    t.float "hours"
    t.time "from_start_time"
    t.time "to_end_time"
    t.text "description"
    t.boolean "billable", default: true
    t.string "type", limit: 255
    t.string "ticket", limit: 255
    t.integer "work_item_id"
    t.integer "invoice_id"
    t.boolean "meal_compensation", default: false, null: false
    t.index ["absence_id", "employee_id", "work_date"], name: "worktimes_absences"
    t.index ["employee_id", "work_date"], name: "worktimes_employees"
    t.index ["invoice_id"], name: "index_worktimes_on_invoice_id"
    t.index ["work_item_id", "employee_id", "work_date"], name: "worktimes_work_items"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "employments", "employees", name: "fk_employments_employees", on_delete: :cascade
  add_foreign_key "order_uncertainties", "orders"
  add_foreign_key "worktimes", "absences", name: "fk_times_absences", on_delete: :cascade
  add_foreign_key "worktimes", "employees", name: "fk_times_employees", on_delete: :cascade
end
