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

<<<<<<< HEAD
ActiveRecord::Schema.define(version: 20140626104953) do
=======
ActiveRecord::Schema.define(version: 20140624093557) do
>>>>>>> create erp models

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absences", force: true do |t|
    t.string  "name",                    null: false
    t.boolean "payed",   default: false
    t.boolean "private", default: false
  end

  create_table "billing_addresses", force: true do |t|
    t.integer "client_id"
    t.integer "contact_id"
    t.string  "supplement"
    t.string  "street"
    t.string  "zip_code"
    t.string  "town"
    t.string  "country"
  end

  create_table "clients", force: true do |t|
    t.string "name",                null: false
    t.string "shortname", limit: 4, null: false
  end

  create_table "contacts", force: true do |t|
    t.string   "lastname"
    t.string   "firstname"
    t.string   "function"
    t.string   "email"
    t.string   "telephone"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts_orders", primary_key: "false", :default => { :expr => "nextval('contacts_orders_false_seq'::regclass)" }, force: true do |t|
    t.integer "contact_id", null: false
    t.integer "order_id",   null: false
  end

  create_table "contracts", force: true do |t|
    t.string  "number",         null: false
    t.date    "start_at"
    t.date    "finish_at"
    t.integer "payment_period"
    t.string  "reference"
  end

  create_table "departments", force: true do |t|
    t.string "name",                null: false
    t.string "shortname", limit: 3, null: false
  end

  create_table "employee_lists", force: true do |t|
    t.integer  "employee_id", null: false
    t.string   "title",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employee_lists_employees", id: false, force: true do |t|
    t.integer  "employee_list_id"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employees", force: true do |t|
    t.string  "firstname",                                       null: false
    t.string  "lastname",                                        null: false
    t.string  "shortname",             limit: 3,                 null: false
    t.string  "passwd"
    t.string  "email",                                           null: false
    t.boolean "management",                      default: false
    t.float   "initial_vacation_days", :default => { :expr => "(0)::double precision" }
    t.string  "ldapname"
    t.string  "eval_periods",          limit: 3,                              array: true
    t.integer "departement_id"
    t.index ["shortname"], :name => "chk_unique_name", :unique => true
  end

  create_table "employees_orders", primary_key: "false", :default => { :expr => "nextval('employees_orders_false_seq'::regclass)" }, force: true do |t|
    t.integer "employee_id", null: false
    t.integer "order_id",    null: false
  end

  create_table "employments", force: true do |t|
    t.integer "employee_id"
    t.decimal "percent",     precision: 5, scale: 2, null: false
    t.date    "start_date",                          null: false
    t.date    "end_date"
    t.index ["employee_id"], :name => "index_employments_on_employee_id"
    t.foreign_key ["employee_id"], "employees", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_employments_employees"
  end

  create_table "holidays", force: true do |t|
    t.date  "holiday_date",  null: false
    t.float "musthours_day", null: false
  end

  create_table "order_comments", force: true do |t|
    t.integer  "order_id",   null: false
    t.text     "text",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_kinds", force: true do |t|
    t.string "name", null: false
  end

  create_table "order_statuses", force: true do |t|
    t.string  "name",     null: false
    t.integer "position", null: false
  end

  create_table "order_targets", force: true do |t|
    t.integer  "target_scope_id", null: false
    t.integer  "order_id",        null: false
    t.string   "rating"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: true do |t|
    t.integer  "budget_item_id",     null: false
    t.integer  "kind_id"
    t.integer  "responsible_id"
    t.integer  "status_id"
    t.integer  "department_id"
    t.integer  "contract_id"
    t.integer  "billing_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "overtime_vacations", force: true do |t|
    t.float   "hours",         null: false
    t.integer "employee_id",   null: false
    t.date    "transfer_date", null: false
  end

  create_table "plannings", force: true do |t|
    t.integer  "employee_id",                     null: false
    t.integer  "project_id",                      null: false
    t.integer  "start_week",                      null: false
    t.integer  "end_week"
    t.boolean  "definitive",      default: false, null: false
    t.text     "description"
    t.boolean  "monday_am",       default: false, null: false
    t.boolean  "monday_pm",       default: false, null: false
    t.boolean  "tuesday_am",      default: false, null: false
    t.boolean  "tuesday_pm",      default: false, null: false
    t.boolean  "wednesday_am",    default: false, null: false
    t.boolean  "wednesday_pm",    default: false, null: false
    t.boolean  "thursday_am",     default: false, null: false
    t.boolean  "thursday_pm",     default: false, null: false
    t.boolean  "friday_am",       default: false, null: false
    t.boolean  "friday_pm",       default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_abstract"
    t.decimal  "abstract_amount"
  end

<<<<<<< HEAD
=======
  create_table "portfolio_items", force: true do |t|
    t.string  "name",                  null: false
    t.boolean "active", default: true, null: false
  end

>>>>>>> create erp models
  create_table "projectmemberships", force: true do |t|
    t.integer "project_id",                        null: false
    t.integer "employee_id",                       null: false
    t.boolean "projectmanagement", default: false, null: false
    t.boolean "active",            default: true,  null: false
  end

  create_table "projects", force: true do |t|
    t.integer "client_id"
    t.string  "name",                                                 null: false
    t.text    "description"
    t.boolean "billable",                           default: true
    t.string  "report_type",                        default: "month"
    t.boolean "description_required",               default: false
    t.string  "shortname",             limit: 3,                      null: false
    t.float   "offered_hours"
    t.integer "parent_id"
    t.integer "department_id"
    t.integer "path_ids",                                                          array: true
    t.date    "freeze_until"
    t.boolean "ticket_required",                    default: false
    t.string  "path_shortnames"
    t.string  "path_names",            limit: 2047
    t.boolean "leaf",                               default: true,    null: false
    t.text    "inherited_description"
    t.boolean "closed",                             default: false,   null: false
    t.integer "offered_rate"
    t.integer "portfolio_item_id"
    t.integer "discount"
    t.string  "reference"
    t.index ["client_id"], :name => "index_projects_on_client_id"
    t.foreign_key ["client_id"], "clients", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_projects_clients"
    t.foreign_key ["department_id"], "departments", ["id"], :on_update => :no_action, :on_delete => :set_null, :name => "fk_project_department"
    t.foreign_key ["parent_id"], "projects", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_project_parent"
  end

<<<<<<< HEAD
=======
  create_table "target_scopes", force: true do |t|
    t.string "label", null: false
  end

>>>>>>> create erp models
  create_table "user_notifications", force: true do |t|
    t.date "date_from", null: false
    t.date "date_to"
    t.text "message",   null: false
  end

  create_table "worktimes", force: true do |t|
    t.integer "project_id"
    t.integer "absence_id"
    t.integer "employee_id"
    t.string  "report_type",                     null: false
    t.date    "work_date",                       null: false
    t.float   "hours"
    t.time    "from_start_time"
    t.time    "to_end_time"
    t.text    "description"
    t.boolean "billable",        default: true
    t.boolean "booked",          default: false
    t.string  "type"
    t.string  "ticket"
    t.index ["absence_id", "employee_id", "work_date"], :name => "worktimes_absences", :conditions => "((type)::text = 'Absencetime'::text)"
    t.index ["employee_id", "work_date"], :name => "worktimes_attendances", :conditions => "((type)::text = 'Attendancetime'::text)"
    t.index ["project_id", "employee_id", "work_date"], :name => "worktimes_projects", :conditions => "((type)::text = 'Projecttime'::text)"
    t.foreign_key ["absence_id"], "absences", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_times_absences"
    t.foreign_key ["employee_id"], "employees", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_times_employees"
    t.foreign_key ["project_id"], "projects", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_times_projects"
  end

end
