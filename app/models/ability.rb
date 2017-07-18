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
         Holiday,
         Contract,
         Order,
         OrderKind,
         OrderStatus,
         OrderTarget,
         OrderUncertainty,
         OvertimeVacation,
         Planning,
         PortfolioItem,
         Sector,
         Service,
         TargetScope,
         UserNotification,
         WorkingCondition,
         EmploymentRole,
         EmploymentRoleLevel,
         EmploymentRoleCategory,
         Reports::Workload,
         WorkItem]

    # :crud instead of :manage because cannot change settings of other employees
    can [:crud,
         :update_committed_worktimes,
         :update_reviewed_worktimes,
         :manage_plannings,
         :show_worktime_graph,
         :log],
        Employee

    can :update, OrderComment do |c|
      c.creator_id == user.id
    end
    can [:create, :read], OrderComment

    # cannot change settings of other employees
    can [:crud, :update_committed_worktimes], Employee do |_|
      true
    end

    can [:create,
         :read,
         :sync,
         :preview_total,
         :billing_addresses,
         :filter_fields],
        Invoice
    can [:edit, :update, :destroy], Invoice do |i|
      !%w(deleted paid partially_paid).include?(i.status)
    end

    can [:read], Worktime
    can [:create, :update], Absencetime
    can [:create, :update], Ordertime do |t|
      !t.work_item_closed? && !t.invoice_sent_or_paid?
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
         :export_role_distribution],
        Evaluation
  end

  def order_responsible_abilities
    can :manage, [Client, BillingAddress, Contact]
    can :create, WorkItem

    can :manage, Order, responsible_id: user.id
    cannot :update_committed, Order

    can :update, OrderComment do |c|
      c.creator_id == user.id
    end
    can [:create, :read], OrderComment

    can :manage, [AccountingPost, Contract] do |instance|
      instance.order.responsible_id == user.id
    end

    can [:create,
         :read,
         :sync,
         :preview_total,
         :billing_addresses,
         :filter_fields],
        Invoice do |i|
      i.order.responsible_id == user.id
    end
    can [:edit, :update, :destroy], Invoice do |i|
      i.order.responsible_id == user.id &&
        !%w(deleted paid partially_paid).include?(i.status)
    end

    can :read, Ordertime do |t|
      t.order.responsible_id == user.id
    end
    can [:create, :update], Ordertime do |t|
      t.order.responsible_id == user.id && !t.work_item_closed? && !t.invoice_sent_or_paid?
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
      t.employee_id == user.id && !t.worktimes_committed? &&
        !t.work_item_closed? && !t.invoice_sent_or_paid?
    end

    can :search, WorkItem

    can [:read, :show_plannings], Employee
    can [:passwd,
         :update_passwd,
         :settings,
         :update_settings,
         :update_committed_worktimes,
         :show_worktime_graph,
         :manage_plannings],
        Employee,
        id: user.id

    can :index, Employment, employee_id: user.id

    can [:read,
         :accounting_posts,
         :services,
         :show_targets,
         :show_uncertainties,
         :show_contract,
         :show_comments,
         :show_invoices,
         :reports,
         :show_plannings],
        Order

    can :read, [AccountingPost, Invoice, OrderComment]

    can :read, Planning
    can :manage, Planning, employee_id: user.id

    can :manage, CustomList, employee_id: user.id

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
