class CreateErpTables < ActiveRecord::Migration
  def up
    create_table :orders do |t|
      t.belongs_to :budget_item, null: false
      t.belongs_to :kind
      t.belongs_to :responsible
      t.belongs_to :status
      t.belongs_to :department
      t.belongs_to :contract
      t.belongs_to :billing_address

      t.string :target_cost, default: Order::TARGET_RATINGS.first
      t.string :target_date, default: Order::TARGET_RATINGS.first
      t.string :target_quality, default: Order::TARGET_RATINGS.first
      t.string :targets_comment
      t.datetime :targets_updated_at

      t.timestamps
    end

    create_table :order_kinds do |t|
      t.string :name, null: false
    end

    create_table :order_statuses do |t|
      t.string :name, null: false
      t.integer :position, null: false
    end

    create_table :order_comments do |t|
      t.belongs_to :order, null: false
      t.text :text, null: false
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

    add_column :projects, :closed, :boolean, null: false, default: false
    add_column :projects, :offered_rate, :integer
    add_column :projects, :portfolio_item_id, :integer
    add_column :projects, :discount, :integer
    add_column :projects, :reference, :string

    #rename_table :projects, :budget_items
    #rename_column :worktimes, :project_id, :budget_item_id

    add_column :employees, :department_id, :integer

    #drop_table :projectmemberships

    if Client.column_names.include?('contact')
      remove_column :clients, :contact
    end

    %w(Projekt Mandat Support Wartung Support&Wartung Schulung Kleinauftrag Subscriptions).each do |n|
      OrderKind.create!(name: n)
    end

    %w(Bearbeitung Abschluss Garantie Abgeschlossen).each_with_index do |n, i|
      OrderStatus.create!(name: n, position: (i+1) * 10)
    end

    ['Web Application Development', 'Enterprise Applikation Development', 'Schulung'].each do |n|
      PortfolioItem.create!(name: n)
    end
  end

  def down
    #create_table :projectmemberships do |t|
    #  t.integer :project_id, null: false
    #  t.integer :employee_id, null: false
    #  t.boolean :projectmanagement, null: false, default: false
    #  t.boolean :active, null: false, default: true
    #end

    remove_column :employees, :department_id

    #rename_column :worktimes, :budget_item_id, :project_id
    #rename_table :budget_items, :projects

    remove_column :projects, :reference
    remove_column :projects, :discount
    remove_column :projects, :portfolio_item_id
    remove_column :projects, :offered_rate
    remove_column :projects, :closed

    drop_table :portfolio_items
    drop_table :employees_orders
    drop_table :contacts_orders
    drop_table :billing_addresses
    drop_table :contacts
    drop_table :contracts
    drop_table :order_comments
    drop_table :order_statuses
    drop_table :order_kinds
    drop_table :orders
  end
end
