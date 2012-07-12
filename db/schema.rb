# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 18) do

  create_table "absences", :force => true do |t|
    t.string  "name",                       :null => false
    t.boolean "payed",   :default => false
    t.boolean "private", :default => false
  end

  create_table "clients", :force => true do |t|
    t.string "name",                   :null => false
    t.string "shortname", :limit => 4, :null => false
  end

  create_table "departments", :force => true do |t|
    t.string "name",                   :null => false
    t.string "shortname", :limit => 3, :null => false
  end

  create_table "employee_lists", :force => true do |t|
    t.integer  "employee_id", :null => false
    t.string   "title",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employee_lists_employees", :id => false, :force => true do |t|
    t.integer  "employee_list_id"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employees", :force => true do |t|
    t.string  "firstname",                                             :null => false
    t.string  "lastname",                                              :null => false
    t.string  "shortname",             :limit => 3,                    :null => false
    t.string  "passwd",                                                :null => false
    t.string  "email",                                                 :null => false
    t.boolean "management",                         :default => false
    t.float   "initial_vacation_days",              :default => 0.0
    t.string  "ldapname"
    t.string  "report_type"
    t.boolean "default_attendance",                 :default => false
    t.integer "default_project_id"
    t.string  "user_periods",          :limit => 3
    t.string  "eval_periods",          :limit => 3
  end

  add_index "employees", ["shortname"], :name => "chk_unique_name", :unique => true

  create_table "employments", :force => true do |t|
    t.integer "employee_id"
    t.decimal "percent",     :precision => 5, :scale => 2, :null => false
    t.date    "start_date",                                :null => false
    t.date    "end_date"
  end

  add_index "employments", ["employee_id"], :name => "index_employments_on_employee_id"

  create_table "holidays", :force => true do |t|
    t.date  "holiday_date",  :null => false
    t.float "musthours_day", :null => false
  end

  create_table "overtime_vacations", :force => true do |t|
    t.float   "hours",         :null => false
    t.integer "employee_id",   :null => false
    t.date    "transfer_date", :null => false
  end

  create_table "plannings", :force => true do |t|
    t.integer  "employee_id",                        :null => false
    t.integer  "project_id",                         :null => false
    t.integer  "start_week",                         :null => false
    t.integer  "end_week"
    t.boolean  "definitive",      :default => false, :null => false
    t.text     "description"
    t.boolean  "monday_am",       :default => false, :null => false
    t.boolean  "monday_pm",       :default => false, :null => false
    t.boolean  "tuesday_am",      :default => false, :null => false
    t.boolean  "tuesday_pm",      :default => false, :null => false
    t.boolean  "wednesday_am",    :default => false, :null => false
    t.boolean  "wednesday_pm",    :default => false, :null => false
    t.boolean  "thursday_am",     :default => false, :null => false
    t.boolean  "thursday_pm",     :default => false, :null => false
    t.boolean  "friday_am",       :default => false, :null => false
    t.boolean  "friday_pm",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_abstract"
    t.decimal  "abstract_amount"
  end

  create_table "projectmemberships", :force => true do |t|
    t.integer "project_id"
    t.integer "employee_id"
    t.boolean "projectmanagement", :default => false
    t.date    "last_completed"
    t.boolean "active",            :default => true
  end

  add_index "projectmemberships", ["employee_id"], :name => "index_projectmemberships_on_employee_id"
  add_index "projectmemberships", ["project_id"], :name => "index_projectmemberships_on_project_id"

  create_table "projects", :force => true do |t|
    t.integer "client_id"
    t.string  "name",                                                     :null => false
    t.text    "description"
    t.boolean "billable",                            :default => true
    t.string  "report_type",                         :default => "month"
    t.boolean "description_required",                :default => false
    t.string  "shortname",            :limit => 3,                        :null => false
    t.float   "offered_hours"
    t.integer "parent_id"
    t.integer "department_id"
    t.string  "path_ids",             :limit => nil
    t.date    "freeze_until"
    t.boolean "ticket_required",                     :default => false
  end

  add_index "projects", ["client_id"], :name => "index_projects_on_client_id"

  create_table "user_notifications", :force => true do |t|
    t.date "date_from", :null => false
    t.date "date_to"
    t.text "message",   :null => false
  end

  create_table "worktimes", :force => true do |t|
    t.integer "project_id"
    t.integer "absence_id"
    t.integer "employee_id"
    t.string  "report_type",                        :null => false
    t.date    "work_date",                          :null => false
    t.float   "hours"
    t.time    "from_start_time"
    t.time    "to_end_time"
    t.text    "description"
    t.boolean "billable",        :default => true
    t.boolean "booked",          :default => false
    t.string  "type"
    t.string  "ticket"
  end

  add_index "worktimes", ["absence_id", "employee_id", "work_date"], :name => "worktimes_absences"
  add_index "worktimes", ["employee_id", "project_id", "work_date"], :name => "worktimes_projects"
  add_index "worktimes", ["employee_id", "work_date"], :name => "worktimes_attendances"

end
