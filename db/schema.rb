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

ActiveRecord::Schema.define(version: 20140626104953) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absences", force: true do |t|
    t.string  "name",                    null: false
    t.boolean "payed",   default: false
    t.boolean "private", default: false
  end

  create_table "clients", force: true do |t|
    t.string "name"
    t.string "shortname"
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
    t.index ["shortname"], :name => "chk_unique_name", :unique => true
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

  create_table "overtime_vacations", force: true do |t|
    t.float   "hours",         null: false
    t.integer "employee_id",   null: false
    t.date    "transfer_date", null: false
  end

  create_table "plannings", force: true do |t|
    t.integer  "employee_id",                     null: false
    t.integer  "project_id"
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
    t.index ["client_id"], :name => "index_projects_on_client_id"
    t.foreign_key ["client_id"], "clients", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_projects_clients"
    t.foreign_key ["department_id"], "departments", ["id"], :on_update => :no_action, :on_delete => :set_null, :name => "fk_project_department"
    t.foreign_key ["parent_id"], "projects", ["id"], :on_update => :no_action, :on_delete => :cascade, :name => "fk_project_parent"
  end

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
