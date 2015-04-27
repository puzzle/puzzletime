# encoding: utf-8

# define deleted models that are used in the migration
class Project < ActiveRecord::Base
  acts_as_tree order: 'shortname'
  belongs_to :work_item
  schema_validations except: :path_ids

  def latest_freeze_until
    if parent.nil?
      freeze_until
    else
      parent_freeze_until = parent.latest_freeze_until
      if freeze_until.nil?
        parent_freeze_until
      elsif parent_freeze_until.nil?
        freeze_until
      else
        [freeze_until, parent_freeze_until].max
      end
    end
  end
end

class Projectmembership < ActiveRecord::Base
  belongs_to :employee
end

require Rails.root.join('app', 'models', 'planning')
class Planning < ActiveRecord::Base
  belongs_to :project
end

class CreateErpTables < ActiveRecord::Migration
  def up
    create_table :orders do |t|
      t.belongs_to :work_item, null: false
      t.belongs_to :kind
      t.belongs_to :responsible
      t.belongs_to :status
      t.belongs_to :department
      t.belongs_to :contract
      t.belongs_to :billing_address
      t.string :crm_key

      t.timestamps
    end

    add_index :orders, :work_item_id
    add_index :orders, :kind_id
    add_index :orders, :responsible_id
    add_index :orders, :status_id
    add_index :orders, :department_id
    add_index :orders, :contract_id
    add_index :orders, :billing_address_id

    create_table :order_kinds do |t|
      t.string :name, null: false
    end

    add_index :order_kinds, :name, unique: true

    create_table :order_statuses do |t|
      t.string :name, null: false
      t.string :style
      t.boolean :closed, null: false, default: false
      t.integer :position, null: false
    end

    add_index :order_statuses, :name, unique: true
    add_index :order_statuses, :position

    create_table :order_comments do |t|
      t.belongs_to :order, null: false
      t.text :text, null: false
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    add_index :order_comments, :order_id

    create_table :target_scopes do |t|
      t.string :name, null: false
      t.string :icon
      t.integer :position, null: false
    end

    add_index :target_scopes, :name, unique: true
    add_index :target_scopes, :position

    create_table :order_targets do |t|
      t.belongs_to :order, null: false
      t.belongs_to :target_scope, null: false
      t.string :rating, null: false, default: OrderTarget::RATINGS.first
      t.text :comment

      t.timestamps
    end

    add_index :order_targets, :order_id
    add_index :order_targets, :target_scope_id

    create_table :contracts do |t|
      t.string :number, null: false
      t.date :start_date
      t.date :end_date
      t.integer :payment_period
      t.string :reference
    end

    create_table :contacts do |t|
      t.belongs_to :client, null: false
      t.string :lastname
      t.string :firstname
      t.string :function
      t.string :email
      t.string :phone
      t.string :mobile
      t.string :crm_key

      t.timestamps
    end

    add_index :contacts, :client_id

    create_table :billing_addresses do |t|
      t.belongs_to :client, null: false
      t.belongs_to :contact, null: false
      t.string :supplement
      t.string :street
      t.string :zip_code
      t.string :town
      t.string :country
    end

    add_index :billing_addresses, :client_id
    add_index :billing_addresses, :contact_id

    create_table :contacts_orders, primary_key: false do |t|
      t.belongs_to :contact, null: false
      t.belongs_to :order, null: false
    end

    add_index :contacts_orders, :contact_id
    add_index :contacts_orders, :order_id

    create_table :employees_orders, primary_key: false do |t|
      t.belongs_to :employee, null: false
      t.belongs_to :order, null: false
    end

    add_index :employees_orders, :employee_id
    add_index :employees_orders, :order_id

    create_table :portfolio_items do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
    end

    add_index :portfolio_items, :name, unique: true

    create_table :work_items do |t|
      t.belongs_to :parent
      t.string :name, null: false
      t.string :shortname, null: false, limit: 5
      t.text :description
      t.integer :path_ids, array: true
      t.string :path_shortnames
      t.string :path_names, limit: 2047
      t.boolean :leaf, null: false, default: true
      t.boolean :closed, null: false, default: false # inherited from order and accounting post
    end

    add_index :work_items, :parent_id
    add_index :work_items, :path_ids

    create_table :accounting_posts do |t|
      t.belongs_to :work_item, null: false
      t.belongs_to :portfolio_item
      t.string :reference
      t.integer :offered_hours
      t.integer :offered_rate
      t.decimal :offered_total, precision: 12, scale: 2
      t.integer :discount_percent
      t.integer :discount_fixed
      t.integer :remaining_hours
      t.boolean :billable, null: false, default: true
      t.boolean :description_required, null: false, default: false
      t.boolean :ticket_required, null: false, default: false
      t.boolean :from_to_times_required, null: false, default: false
      t.boolean :closed, null: false, default: false
    end

    add_index :accounting_posts, :work_item_id
    add_index :accounting_posts, :portfolio_item_id

    add_column :clients, :work_item_id, :integer
    add_index :clients, :work_item_id

    add_column :clients, :crm_key, :string

    add_column :employees, :department_id, :integer
    add_index :employees, :department_id

    add_column :worktimes, :work_item_id, :integer

    remove_index :worktimes, name: 'worktimes_absences'
    remove_index :worktimes, name: 'worktimes_attendances'
    add_index :worktimes,
              ["work_item_id", "employee_id", "work_date"],
              name: "worktimes_work_items"
    add_index :worktimes,
              ["absence_id", "employee_id", "work_date"],
              name: "worktimes_absences"
    add_index :worktimes,
              ["employee_id", "work_date"],
              name: "worktimes_employees"

    add_column :plannings, :work_item_id, :integer
    add_index :plannings, :work_item_id
    add_index :plannings, :employee_id

    add_index :absences, :name, unique: true
    add_index :departments, :name, unique: true
    add_index :departments, :shortname, unique: true
    add_index :employee_lists, :employee_id
    add_index :employee_lists_employees, :employee_list_id
    add_index :employee_lists_employees, :employee_id
    add_index :holidays, :holiday_date, unique: true
    add_index :overtime_vacations, :employee_id
    add_index :user_notifications, [:date_from, :date_to]

    add_column :projects, :work_item_id, :integer # just temporary to simplify the migration

    Planning.reset_column_information

    if Client.column_names.include?('contact')
      remove_column :clients, :contact
    end

    %w(Projekt Mandat Support Wartung Support&Wartung Schulung Kleinauftrag Subscriptions).each do |n|
      OrderKind.create!(name: n)
    end

    OrderStatus.create!(name: 'Bearbeitung', style: 'success', position: 10)
    OrderStatus.create!(name: 'Abschluss', style: 'info', position: 20)
    OrderStatus.create!(name: 'Garantie', style: 'warning', position: 30)
    OrderStatus.create!(name: 'Abgeschlossen', style: 'danger', position: 40)

    ['Null', 'Web Application Development', 'Enterprise Applikation Development', 'Schulung'].each do |n|
      PortfolioItem.create!(name: n)
    end

    TargetScope.create!(name: 'Kosten', icon: 'usd', position: 10)
    TargetScope.create!(name: 'Termin', icon: 'time', position: 20)
    TargetScope.create!(name: 'Qualität', icon: 'heart-empty', position: 30)

    # rename projecttime to ordertime
    Worktime.where(type: 'Projecttime').update_all(type: 'Ordertime')

    migrate_projects_to_work_items

    remove_column :plannings, :project_id
    change_column :plannings, :work_item_id, :integer, null: false

    remove_column :worktimes, :project_id

    remove_column :clients, :name
    remove_column :clients, :shortname
    change_column :clients, :work_item_id, :integer, null: false

    drop_table :projectmemberships
    drop_table :projects

    drop_table :engine_schema_info rescue nil
  end

  def down
    create_table :projectmemberships do |t|
      t.integer :project_id, null: false
      t.integer :employee_id, null: false
      t.boolean :projectmanagement, null: false, default: false
      t.boolean :active, null: false, default: true
    end

    create_table :projects do |t|
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
    end

    # rename ordertime to projecttime
    Worktime.where(type: 'Ordertime').update_all(type: 'Projecttime')

    remove_column :employees, :department_id

    remove_column :clients, :crm_key
    remove_column :clients, :work_item_id

    remove_column :worktimes, :work_item_id

    remove_column :plannings, :work_item_id

    add_column :worktimes, :project_id, :integer

    add_column :plannings, :project_id, :integer

    drop_table :accounting_posts
    drop_table :work_items
    drop_table :portfolio_items
    drop_table :employees_orders
    drop_table :contacts_orders
    drop_table :billing_addresses
    drop_table :contacts
    drop_table :contracts
    drop_table :order_targets
    drop_table :target_scopes
    drop_table :order_comments
    drop_table :order_statuses
    drop_table :order_kinds
    drop_table :orders
  end

  private

  def migrate_projects_to_work_items
    say_with_time 'add work_items for clients' do
      add_work_items_for_clients
    end
    say_with_time 'add work_items for projects' do
      add_work_items_for_projects
    end
    say_with_time 'migrate planning project ids' do
      migrate_planning_project_ids
    end
  end

  def add_work_items_for_clients
    Client.find_each do |client|
      # access attributes directly because of delegations
      client.create_work_item!(name: client[:name], shortname: client[:shortname])
      client.update_attribute(:work_item_id, client.work_item_id) # workaround because of missing contact column
    end
    assert_all_entries_have_work_items(Client)
  end

  def add_work_items_for_projects
    count = Project.count(leaf: true)
    index = 0
    Project.where(leaf: true).find_each do |project|
      say "   (#{index}/#{count})" if index > 0 && index % 50 == 0
      case project.path_ids.size
      when 1
        migrate_depth1_project(project)
      when 2
        migrate_depth2_project(project)
      when 3
        migrate_depth3_project(project)
      else
        fail "Project #{project.path_shortnames} has invalid numbers of parents (#{project.path_ids.size} parents but only 1-3 are supported)"
      end

      # migrate ordertime project ids
      Ordertime.where(project_id: project.id).update_all(work_item_id: project.work_item.id)
      index += 1
    end

    assert_all_entries_have_work_items(Project)
    assert_all_entries_have_work_items(Ordertime)
  end

  def migrate_depth1_project(project)
    client = Client.find(project[:client_id])
    create_work_item!(project, client.work_item, true)
    create_order!(project)
    create_accounting_post!(project)
  end

  def migrate_depth2_project(project)
    if depth2_with_category?(project)
      migrate_depth2_project_with_category(project)
    else
      migrate_depth2_project_with_accounting_posts(project)
    end
  end

  def migrate_depth2_project_with_category(project)
    create_category_if_missing(project.parent)

    create_work_item!(project, project.parent.work_item, true)
    create_order!(project)
    create_accounting_post!(project)
  end

  def migrate_depth2_project_with_accounting_posts(project)
    unless project.parent.work_item
      client = Client.find(project.parent[:client_id])
      create_work_item!(project.parent, client.work_item, false)
      create_order!(project.parent)
    end

    create_work_item!(project, project.parent.work_item, true)
    create_accounting_post!(project)
  end

  def migrate_depth3_project(project)
    l1_project = project.parent.parent
    l2_project = project.parent

    create_category_if_missing(l1_project)

    unless l2_project.work_item
      create_work_item!(l2_project, l1_project.work_item, false)
      create_order!(l2_project)
    end

    create_work_item!(project, l2_project.work_item, true)
    create_accounting_post!(project)
  end

  def create_category_if_missing(top_project)
    unless top_project.work_item
      client = Client.find(top_project[:client_id])
      create_work_item!(top_project, client.work_item, false)
    end
  end

  def create_work_item!(project, parent_work_item, leaf)
    project.create_work_item!(parent_id: parent_work_item.id,
                              name: project[:name],
                              shortname: project[:shortname],
                              description: project[:description],
                              leaf: leaf)
    project.save!
  rescue
    p project
    p parent_work_item
    raise
  end

  def create_order!(project)
    responsible = project_responsible(project)
    project.work_item.create_order!(kind: default_order_kind,
                                    status: default_order_status,
                                    responsible: responsible,
                                    department_id: project[:department_id])
  end

  def create_accounting_post!(project)
    project.work_item.create_accounting_post!(billable: project[:billable],
                                              description_required: project[:description_required],
                                              ticket_required: project[:ticket_required],
                                              from_to_times_required: project[:report_type] == 'start_stop_day',
                                              portfolio_item: default_portfolio_item)
  rescue
    p project
    raise
  end

  def migrate_planning_project_ids
    Planning.find_each do |planning|
      planning.update_column(:work_item_id, planning.project.work_item_id)
    end
  end

  def project_responsible(project)
    # find a project management member for this project or its parents
    membership = projectmanagement_membership(project)
    if !membership && project.parent
      membership = projectmanagement_membership(project.parent)
      if !membership && project.parent.parent
        membership = projectmanagement_membership(project.parent.parent)
      end
    end
    membership ? membership.employee : default_order_responsible
  end

  def projectmanagement_membership(project)
    Projectmembership.where(project_id: project.id, projectmanagement: true).first
  end

  def assert_all_entries_have_work_items(model_class)
    count = model_class.where('work_item_id is null').count
    if count > 0
      fail "Missing work_items for #{count} #{model_class.name.downcase.pluralize} (#{model_class.name} # #{model_class.where('work_item_id is null').pluck(:id).join(', ')})"
    end
  end

  def default_order_responsible
    @default_order_responsible ||= Employee.find_by_shortname('MW')
  end

  def default_order_kind
    @default_order_kind ||= OrderKind.find_by_name('Projekt')
  end

  def default_order_status
    @default_order_status ||= OrderStatus.find_by_name('Abgeschlossen')
  end

  def default_portfolio_item
    @default_portfolio_item ||= PortfolioItem.find_by_name('Null')
  end



  DEPTH2_WITH_CATEGORY =
    [2748, 2881, 2297, 2515, 2691, 3064, 3065, 366, 367, 1226, 2361, 2438, 2441, 2489, 217, 218,
     223, 224, 225, 226, 227, 568, 2476, 2768, 534, 604, 905, 2226, 2228, 2358, 2439, 2585, 516,
     517, 2690, 2430, 2359, 2360, 352, 353, 2231, 1063, 2609, 2610, 2677, 2478, 2479, 1096, 149,
     154, 164, 1542, 2497, 1398, 2248, 2480, 3095, 2216, 2217, 2218, 2219, 2215, 2220, 2221, 2222,
     2490, 2293, 2391, 2597, 2625, 2626, 2336, 2335, 2354, 2355, 2556, 2373, 2374, 2375, 2376,
     2377, 2378, 2514, 2390, 3202, 3203, 3206, 2509, 2510, 2511, 2484, 2485, 2486, 2487, 2488,
     2505, 2530, 2583, 2584, 2503, 2482, 2483, 2572, 2586, 2607, 2636, 2642, 2559, 2560, 2524,
     2527, 2528, 2529, 3102, 3103, 3344, 2641, 2826, 2654, 2784, 3166, 3076, 3077, 2764, 2700,
     2915, 3392, 3391, 3311, 2740, 2745, 3004, 2747, 2910, 3135, 3007, 2912, 3181, 3182, 2820,
     2821, 3042, 2892, 3006, 3291, 2845, 2846, 2847, 2848, 2849, 2850, 2851, 2907, 3117, 3289,
     3313, 2859, 2860, 2861, 2863, 3165, 2870, 3148, 2914, 3043, 3126, 3234, 3321, 3322, 3386,
     3390, 2895, 3138, 3163, 3285, 2898, 3081, 2903, 2999, 3001, 3040, 3109, 3129, 3142, 3154,
     3155, 3217, 3242, 3243, 3292, 2998, 3034, 3035, 3036, 3084, 3268, 3329, 3408, 3009, 3021,
     3136, 3023, 3025, 3029, 3032, 3164, 3038, 3108, 3074, 3168, 3171, 3173, 3079, 3124, 3083,
     3115, 3116, 3345, 3346, 3141, 3384, 3111, 3131, 3133, 3144, 3282, 3283, 3198, 3199, 3222,
     3318, 3186, 3208, 3248, 3251, 3253, 3410, 3417, 3466, 3297, 3396, 3315, 3393, 3353, 3348, 3350, 3371,
     3398, 2987, 2988, 2985, 2986, 3153, 3157]

  DEPTH2_WITH_ACCOUNTING_POSTS =
    [2250, 2251, 2362, 2320, 2321, 2493, 2301, 2302, 2303, 2304, 2305, 2306, 2307, 2308, 327, 328,
     195, 196, 732, 2232, 2785, 3342, 303, 304, 2383, 2322, 2323, 2357, 2567, 2634, 1311, 1312, 720,
     721, 722, 1313, 1314, 1315, 1316, 1317, 1318, 1319, 1320, 1321, 2289, 2284, 2285,
     2286, 2287, 2288, 2290, 2398, 2506, 2507, 2508, 2294, 2917, 2299, 2312, 2440, 2314, 2348,
     2349, 2350, 2351, 2319, 2329, 2325, 2326, 2327, 2328, 2435, 2575, 2331, 2332, 2333, 2338,
     2339, 2340, 2342, 2343, 2570, 2345, 2346, 2347, 2653, 2652, 2843, 2381, 2380, 2382, 2395,
     2396, 2397, 2393, 2394, 2401, 2402, 2403, 2405, 2454, 2455, 2456, 2496, 2458, 2459, 2460,
     2461, 2462, 2463, 2464, 2465, 2466, 2467, 2468, 2469, 2470, 2471, 2472, 2473, 2475, 2517,
     2518, 2519, 2520, 2552, 2553, 2542, 2543, 2544, 2545, 2546, 2547, 2549, 2550, 2558, 2814,
     3075, 3293, 2596, 2582, 2598, 2600, 2619, 2620, 2599, 2589, 2590, 2591, 2604, 2618, 2630,
     2631, 2633, 2725, 2639, 2646, 2722, 2723, 2697, 3209, 3210, 2730, 2731, 2732, 3201, 3128,
     2905, 2906, 3113, 2795, 2818, 2797, 2813, 2805, 2806, 2807, 2808, 2810, 2811, 2812, 2836,
     2837, 3200, 2834, 2833, 3080, 2891, 2919, 2920, 2922, 2923, 2924, 2925, 2927, 2928, 2929,
     2931, 2932, 2933, 2934, 2936, 2937, 2939, 2940, 2942, 2943, 2945, 2946, 3014, 2948, 2950,
     2951, 2958, 2959, 3239, 2961, 2962, 2963, 2964, 2965, 2967, 2968, 2970, 2972, 2974, 2976,
     2977, 2978, 2979, 2980, 2990, 2991, 2994, 2995, 3189, 3218, 3219, 3159, 3160, 3343, 3262,
     3263, 3264, 3265, 3266, 3267]

  def depth2_with_category?(project)
    case project.id
    when *DEPTH2_WITH_CATEGORY then true
    when *DEPTH2_WITH_ACCOUNTING_POSTS then false
    else
      puts("Projekt #{project.id} - #{project.path_shortnames} ist nicht kategorisiert!")
      !(project.parent.work_item && project.parent.work_item.order)
    end
  end

end
