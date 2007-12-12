# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 10) do

  create_table "absences", :force => true do |t|
    t.string  "name",                     :null => false
    t.boolean "payed", :default => false
  end

  create_table "clients", :force => true do |t|
    t.string "name",                   :null => false
    t.string "contact"
    t.string "shortname", :limit => 4, :null => false
  end

  create_table "employees", :force => true do |t|
    t.string  "firstname",                                             :null => false
    t.string  "lastname",                                              :null => false
    t.string  "shortname",             :limit => 3,                    :null => false
    t.string  "passwd",                                                :null => false
    t.string  "email",                                                 :null => false
    t.boolean "management",                         :default => false
    t.float   "initial_vacation_days"
    t.string  "ldapname"
  end

  add_index "employees", ["shortname"], :name => "chk_unique_name", :unique => true

  create_table "employments", :force => true do |t|
    t.integer "employee_id"
    t.integer "percent",     :null => false
    t.date    "start_date",  :null => false
    t.date    "end_date"
  end

  add_index "employments", ["employee_id"], :name => "index_employments_on_employee_id"

  create_table "engine_schema_info", :id => false, :force => true do |t|
    t.string  "engine_name"
    t.integer "version"
  end

  create_table "holidays", :force => true do |t|
    t.date  "holiday_date",  :null => false
    t.float "musthours_day", :null => false
  end

  create_table "overtime_vacations", :force => true do |t|
    t.float   "hours",         :null => false
    t.integer "employee_id",   :null => false
    t.date    "transfer_date", :null => false
  end

  create_table "projectmemberships", :force => true do |t|
    t.integer "project_id"
    t.integer "employee_id"
    t.boolean "projectmanagement", :default => false
    t.date    "last_completed"
  end

  add_index "projectmemberships", ["employee_id"], :name => "index_projectmemberships_on_employee_id"
  add_index "projectmemberships", ["project_id"], :name => "index_projectmemberships_on_project_id"

  create_table "projects", :force => true do |t|
    t.integer "client_id"
    t.string  "name",                                                   :null => false
    t.text    "description"
    t.boolean "billable",                          :default => true
    t.string  "report_type",                       :default => "month"
    t.boolean "description_required",              :default => false
    t.string  "shortname",            :limit => 3,                      :null => false
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
  end

  add_index "worktimes", ["absence_id", "work_date", "employee_id"], :name => "worktimes_absences"
  add_index "worktimes", ["work_date", "employee_id"], :name => "worktimes_attendances"
  add_index "worktimes", ["employee_id", "project_id", "work_date"], :name => "worktimes_projects"

end
