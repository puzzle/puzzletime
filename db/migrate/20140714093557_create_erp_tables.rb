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

    create_table :order_statuses do |t|
      t.string :name, null: false
      t.string :style
      t.boolean :closed, null: false, default: false
      t.integer :position, null: false
    end

    create_table :order_comments do |t|
      t.belongs_to :order, null: false
      t.text :text, null: false
      t.timestamps
    end

    add_index :order_comments, :order_id

    create_table :target_scopes do |t|
      t.string :name, null: false
      t.string :icon
      t.integer :position, null: false
    end

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
      t.integer :discount_percent
      t.integer :discount_fixed
      t.string :report_type
      t.boolean :billable, null: false, default: true
      t.boolean :description_required, null: false, default: false
      t.boolean :ticket_required, null: false, default: false
      t.boolean :closed, null: false, default: false
    end

    add_index :accounting_posts, :work_item_id
    add_index :accounting_posts, :portfolio_item_id

    add_column :clients, :work_item_id, :integer
    add_column :clients, :crm_key, :string

    add_column :employees, :department_id, :integer

    add_column :worktimes, :work_item_id, :integer

    add_column :plannings, :work_item_id, :integer

    add_column :projects, :work_item_id, :integer # just temporary to simplify the migration

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

    ['Web Application Development', 'Enterprise Applikation Development', 'Schulung'].each do |n|
      PortfolioItem.create!(name: n)
    end

    TargetScope.create!(name: 'Kosten', icon: 'usd', position: 10)
    TargetScope.create!(name: 'Termin', icon: 'time', position: 20)
    TargetScope.create!(name: 'Qualität', icon: 'star-empty', position: 30)

    # rename projecttime to ordertime
    Worktime.where(type: 'Projecttime').update_all(type: 'Ordertime')

    migrate_projects_to_work_items

    remove_column :projects, :work_item_id

    # remove_column :plannings, :project_id

    # remove_column :worktimes, :project_id

    # remove_column :clients, :name
    # remove_column :clients, :shortname
    # change_column :clients, :work_item_id, :integer, null: false
    change_column :clients, :name, :string, null: true
    change_column :clients, :shortname, :string, null: true

    # drop_table :projects, :accounting_posts
    # drop_table :projectmemberships
  end

  def down
    #create_table :projectmemberships do |t|
    #  t.integer :project_id, null: false
    #  t.integer :employee_id, null: false
    #  t.boolean :projectmanagement, null: false, default: false
    #  t.boolean :active, null: false, default: true
    #end

    # rename ordertime to projecttime
    Worktime.where(type: 'Ordertime').update_all(type: 'Projecttime')

    remove_column :employees, :department_id

    remove_column :clients, :crm_key
    remove_column :clients, :work_item_id

    remove_column :worktimes, :work_item_id

    remove_column :plannings, :work_item_id

    # add_column :worktimes, :project_id, :integer

    # add_column :plannings, :project_id, :integer

    # create_table :projects

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
    end
  end

  def add_work_items_for_projects
    count = Project.count(leaf: true)
    Project.where(leaf: true).each_with_index do |project, index|
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
    # TODO whitlist project with depth 2

    # until we have the list, migrate it without creating a category
    unless project.parent.work_item
      client = Client.find(project.parent[:client_id])
      create_work_item!(project.parent, client.work_item, false)
    end

    create_work_item!(project, project.parent.work_item, true)
    create_order!(project)
    create_accounting_post!(project)
  end

  def migrate_depth3_project(project)
    l1_project = project.parent.parent
    l2_project = project.parent

    unless l1_project.work_item
      client = Client.find(l1_project[:client_id])
      create_work_item!(l1_project, client.work_item, false)
    end

    unless l2_project.work_item
      create_work_item!(l2_project, l1_project.work_item, false)
      create_order!(l2_project)
    end

    create_work_item!(project, l2_project.work_item, true)
    create_accounting_post!(project)
  end

  def create_work_item!(project, parent_work_item, leaf)
    # TODO clarify if freeze_until has to be migrated
    project.create_work_item!(parent_id: parent_work_item.id,
                              name: project[:name],
                              shortname: project[:shortname],
                              description: project[:description],
                              leaf: leaf)
    project.save!
  end

  def create_order!(project)
    kind = OrderKind.list.third # 'Projekt'
    status = OrderStatus.list.first # 'Bearbeitung'
    responsible = project_responsible(project)
    project.work_item.create_order!(kind: kind,
                                    status: status,
                                    responsible: responsible,
                                    department_id: project[:department_id])
  end

  def create_accounting_post!(project)
    project.work_item.create_accounting_post!(billable: project[:billable],
                                              description_required: project[:description_required],
                                              ticket_required: project[:ticket_required])
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
    # TODO: specify default responsible
    membership ? membership.employee : Employee.find_by_shortname('MW')
  end

  def projectmanagement_membership(project)
    Projectmembership.where(project_id: project.id, projectmanagement: true).first
  end

  def assert_all_entries_have_work_items(model_class)
    count = model_class.where('work_item_id is null').count
    if count > 0
      fail "Missing work_items for #{count} #{model_class.name.downcase.pluralize} (e.g. #{model_class.name} ##{model_class.where('work_item_id is null').first.id})"
    end
  end

end
