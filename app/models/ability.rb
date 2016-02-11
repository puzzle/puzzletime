class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    @user = user
    alias_action :create, :read, :update, :destroy, :delete, to: :crud

    if user.management?
      management_abilities
    elsif user.order_responsible?
      order_responsible_abilities
    end

    everyone_abilities
  end

  private

  def management_abilities
    can :manage, [Absence,
                  AccountingPost,
                  BillingAddress,
                  Client,
                  Contact,
                  Department,
                  Employment,
                  Invoice,
                  Holiday,
                  Contract,
                  Order,
                  OrderKind,
                  OrderStatus,
                  OrderTarget,
                  OrderComment,
                  OvertimeVacation,
                  PortfolioItem,
                  Sector,
                  Service,
                  TargetScope,
                  UserNotification,
                  WorkingCondition,
                  WorkItem]

    # cannot change settings of other employees
    can [:crud, :update_committed_worktimes], Employee do |_|
      true
    end

    can [:read], Worktime
    can [:create, :update], Absencetime
    can [:create, :update], Ordertime do |t|
      !t.work_item_closed?
    end

    can [:clients,
         :employees,
         :overtime,
         :clientworkitems,
         :departments,
         :departmentorders,
         :managed,
         :employeeworkitems,
         :employeesubworkitems,
         :absences,
         :employeeabsences,
         :export_capacity_csv,
         :export_extended_capacity_csv,
         :export_ma_overview], Evaluation
  end

  def order_responsible_abilities
    can :manage, [Client, BillingAddress, Contact]
    can :create, WorkItem
    can :manage, Order, responsible_id: user.id
    can :manage, [AccountingPost, Contract, Invoice, OrderComment] do |instance|
      instance.order.responsible_id == user.id
    end
    can :read, Ordertime do |t|
      t.order.responsible_id == user.id
    end
    can [:create, :update], Ordertime do |t|
      t.order.responsible_id == user.id && !t.work_item_closed?
    end
    can :managed, Evaluation
  end

  def everyone_abilities
    can [:read, :existing, :split, :create_part, :delete_part],
        Worktime,
        employee_id: user.id

    can :manage, Absencetime do |t|
      t.employee_id == user.id && !t.worktimes_committed?
    end

    can :manage, Ordertime do |t|
      t.employee_id == user.id && !t.worktimes_committed? && !t.work_item_closed?
    end

    can :search, WorkItem

    can :read, Employee
    can [:passwd, :update_passwd, :settings, :update_settings,
         :update_committed_worktimes], Employee do |employee|
      employee == user
    end

    can [:read, :accounting_posts, :services, :show_targets, :show_contract, :show_comments,
         :show_invoices, :reports], Order

    can :read, [AccountingPost, Invoice, OrderComment]

    can :manage, Planning

    can :manage, EmployeeList

    can [:select_period,
         :current_period,
         :change_period,
         :compose_report,
         :report,
         :export_csv,
         :absencedetails,
         :userworkitems,
         :userabsences,
         :usersubworkitems,
         :subworkitems,
         :workitememployees,
         :orderworkitems], Evaluation
  end
end
