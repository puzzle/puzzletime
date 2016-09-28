# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
    can :manage,
        [Absence,
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
         Planning,
         PortfolioItem,
         Sector,
         Service,
         TargetScope,
         UserNotification,
         WorkingCondition,
         WorkItem]

    # :crud instead of :manage because cannot change settings of other employees
    can [:crud, :update_committed_worktimes, :manage_plannings], Employee

    can [:update_month_end_completions, :manage_plannings], Order

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
         :export_ma_overview],
        Evaluation
  end

  def order_responsible_abilities
    can :manage, [Client, BillingAddress, Contact]
    can :create, WorkItem

    can [:manage,
         :update_month_end_completions,
         :manage_plannings],
        Order,
        responsible_id: user.id

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

    can :manage, Planning do |planning|
      planning.order.responsible_id == user.id
    end
  end

  def everyone_abilities
    can [:read,
         :existing,
         :split,
         :create_part,
         :delete_part],
        Worktime,
        employee_id: user.id

    can :manage, Absencetime do |t|
      t.employee_id == user.id && !t.worktimes_committed?
    end

    can :manage, Ordertime do |t|
      t.employee_id == user.id && !t.worktimes_committed? && !t.work_item_closed?
    end

    can :search, WorkItem

    can [:read, :show_plannings], Employee
    can [:passwd,
         :update_passwd,
         :settings,
         :update_settings,
         :update_committed_worktimes,
         :manage_plannings],
        Employee do |employee|
      employee == user
    end

    can [:read,
         :accounting_posts,
         :services,
         :show_targets,
         :show_contract,
         :show_comments,
         :show_invoices,
         :reports,
         :show_plannings],
        Order

    can :read, [AccountingPost, Invoice, OrderComment]

    can :read, Planning
    can :manage, Planning, employee_id: user.id

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
         :orderworkitems],
        Evaluation
  end
end
