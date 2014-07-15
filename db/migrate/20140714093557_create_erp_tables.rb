# encoding: utf-8

class CreateErpTables < ActiveRecord::Migration
  def up
    # TODO add indizes

    create_table :orders do |t|
      t.belongs_to :path_item, null: false
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
      t.string :lastname
      t.string :firstname
      t.string :function
      t.string :email
      t.string :telephone
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

    create_table :path_items do |t|
      t.string :name, null: false
      t.string :shortname, null: false
      t.belongs_to :parent
      t.integer :path_ids, array: true
      t.string :path_shortnames
      t.string :path_names, limit: 2047
      t.boolean :leaf, null: false, default: true
    end

    add_column :projects, :path_item_id, :integer
    add_column :projects, :open, :boolean, null: false, default: true
    add_column :projects, :offered_rate, :integer
    add_column :projects, :portfolio_item_id, :integer
    add_column :projects, :discount_percent, :integer
    add_column :projects, :discount_fixed, :integer
    add_column :projects, :reference, :string

    add_column :clients, :path_item_id, :integer

    add_column :employees, :department_id, :integer

    migrate_projects_to_path_items

    # remove_column :projects, :client_id
    # remove_column :projects, :name
    # remove_column :projects, :short_name
    # remove_column :projects, :parent_id
    # remove_column :projects, :department_id
    # remove_column :projects, :path_ids
    # remove_column :projects, :path_shortnames
    # remove_column :projects, :path_names
    # remove_column :projects, :leaf
    # remove_column :projects, :inherited_description

    # rename_table :projects, :accounting_posts

    # rename_column :worktimes, :project_id, :accounting_post_id

    # TODO: accounting_post_id or path_item_id ??
    # rename_column :plannings, :project_id, :accounting_post_id

    # remove_column :clients, :name
    # remove_column :clients, :shortname

    drop_table :projectmemberships

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
    create_table :projectmemberships do |t|
      t.integer :project_id, null: false
      t.integer :employee_id, null: false
      t.boolean :projectmanagement, null: false, default: false
      t.boolean :active, null: false, default: true
    end

    remove_column :employees, :department_id

    remove_column :clients, :path_item_id

    # rename_column :worktimes, :accounting_post_id, :project_id

    # rename_table :accounting_posts, :projects

    remove_column :projects, :path_item_id
    remove_column :projects, :open, :boolean
    remove_column :projects, :offered_rate
    remove_column :projects, :portfolio_item_id
    remove_column :projects, :discount_percent
    remove_column :projects, :discount_fixed
    remove_column :projects, :reference


    drop_table :path_items
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

  def migrate_projects_to_path_items

  end
end
