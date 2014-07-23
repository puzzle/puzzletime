# encoding: utf-8

# define deleted models
class Project < ActiveRecord::Base
  acts_as_tree order: 'shortname'
  belongs_to :work_item
  
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

class CreateErpTables < ActiveRecord::Migration
  def up
    # TODO add indizes for every belongs to relation

    create_table :orders do |t|
      t.belongs_to :work_item, null: false
      t.belongs_to :kind
      t.belongs_to :responsible
      t.belongs_to :status
      t.belongs_to :department
      t.belongs_to :contract
      t.belongs_to :billing_address

      t.timestamps
    end

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

    create_table :target_scopes do |t|
      t.string :name, null: false
      t.string :icon
      t.integer :position, null: false
    end

    create_table :order_targets do |t|
      t.belongs_to :order
      t.belongs_to :target_scope
      t.string :rating, null: false, default: OrderTarget::RATINGS.first
      t.text :comment

      t.timestamps
    end

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

      t.timestamps
    end

    create_table :billing_addresses do |t|
      t.belongs_to :client
      t.belongs_to :contact
      t.string :supplement
      t.string :street
      t.string :zip_code
      t.string :town
      t.string :country
    end

    create_table :contacts_orders, primary_key: false do |t|
      t.belongs_to :contact, null: false
      t.belongs_to :order, null: false
    end

    create_table :employees_orders, primary_key: false do |t|
      t.belongs_to :employee, null: false
      t.belongs_to :order, null: false
    end

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

    add_column :clients, :work_item_id, :integer

    add_column :employees, :department_id, :integer

    add_column :worktimes, :work_item_id, :integer

    add_column :plannings, :work_item_id, :integer
    
    add_column :projects, :work_item_id, :integer # just temporary to simplify the migration

    migrate_projects_to_work_items
    
    remove_column :projects, :work_item_id


    # remove_column :plannings, :project_id

    # remove_column :worktimes, :project_id

    # remove_column :clients, :name
    # remove_column :clients, :shortname
    change_column :clients, :name, :string, null: true
    change_column :clients, :shortname, :string, null: true

    # drop_table :projects, :accounting_posts
    # drop_table :projectmemberships

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
  end

  def down
    #create_table :projectmemberships do |t|
    #  t.integer :project_id, null: false
    #  t.integer :employee_id, null: false
    #  t.boolean :projectmanagement, null: false, default: false
    #  t.boolean :active, null: false, default: true
    #end

    remove_column :employees, :department_id

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
    add_work_items_for_clients
    add_work_items_for_projects
    create_accounting_posts
    create_orders
    migrate_planning_project_ids
    #TODO rename_table :projecttime, :order_time
  end
  
  def add_work_items_for_clients
    Client.all.each do |client|
      # access attributes directly because of delegations
      client.create_work_item!(name: client[:name], shortname: client[:shortname])
    end
  end
  
  def add_work_items_for_projects
    Project.where(leaf: true).each do |project|
      case project.path_ids.size
      when 1
        client = Client.find(project[:client_id])
        project.create_work_item!(parent_id: client.work_item.id,
                                  name: project[:name],
                                  shortname: project[:shortname],
                                  description: project[:description],
                                  leaf: true)
      when 2
        # TODO whitlist project with "tiefe 2"
      when 3
        # TODO add work items for each project
      else
        throw "Project #{project.path_shortnames} has invalid numbers of parents (#{project.path_ids.size} parents but only 1-3 are supported)"
      end
    end
  end
  
  # create accounting post to leaf work items, get inherited values
  def create_accounting_posts
    Project.where(leaf: true).each do |project|
      #get inherited values
      freeze_until = project.latest_freeze_until
      description = project.inherited_description
      # TODO where is the new freeze attribute?
      # TODO wherewo kommt die beschreibung hin? fehlt etwa ein work_item? 
      project.work_item.create_accounting_post! if project.work_item # TODO remove if as soon as add_work_items_for_projects has been implemented
    end  
  end    
  
  # create orders for corresponding work items (dependent on path depth)
  def create_orders
    # TODO create orders for corresponding work items (dependent on path depth)    
  end
  
  def migrate_planning_project_ids
    assert_valid_plannings_before_migration
    migrate_plannings
    
    # TODO assert valid plannings after migration
    #assert_valid_plannings_after_migration
  end
    
  def assert_valid_plannings_before_migration
    Planning.all.each do |planning|
      unless planning.valid?
        throw "Bad data found in planning #{planning.id}. Exception #{e}"
      end
    end
  end
  
  def migrate_plannings
    Planning.all.each do |planning|
      planning.update_attributes!(work_item_id: planning.project.work_item_id)
    end
  end
  
  def assert_valid_plannings_after_migration
    Planning.all.each do |planning|
      unless planning.work_item
        throw "Missing work_item for planning #{planning.id}"
      end
    end
  end
  
end
