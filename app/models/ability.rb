#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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
    elsif user.is_a?(ApiClient)
      api_client_abilities
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
         Expense,
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
         WorkItem,
         Workplace]

    # :crud instead of :manage because cannot change settings of other employees
    can [:crud,
         :update_committed_worktimes,
         :update_reviewed_worktimes,
         :manage_plannings,
         :show_worktime_graph,
         :social_insurance,
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
    can [:create, :destroy], Absencetime
    can [:create, :update, :destroy], Ordertime do |t|
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
         :capacity_report,
         :export_report,
         :meal_compensation],
        Evaluations::Evaluation
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

    can :manage, [AccountingPost, Contract, OrderUncertainty] do |instance|
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
      is_responsible     = (i.order.responsible_id == user.id)
      is_open            = !%w(deleted paid partially_paid).include?(i.status)
      is_manual_and_used = i.manual? && i.total_amount > 1

      is_responsible && is_open && !is_manual_and_used
    end

    can :read, Ordertime do |t|
      t.order.responsible_id == user.id
    end
    can [:create, :update, :destroy], Ordertime do |t|
      t.order.responsible_id == user.id && !t.work_item_closed? && !t.invoice_sent_or_paid?
    end
    can :managed, Evaluations::Evaluation

    can :manage, Planning do |planning|
      planning.order.responsible_id == user.id
    end

    can :revenue_reports, Department
    can :social_insurance, Employee
  end

  def api_client_abilities
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
    can [:settings,
         :update_settings,
         :update_committed_worktimes,
         :show_worktime_graph,
         :social_insurance,
         :manage_plannings],
        Employee,
        id: user.id

    can :index, Employment, employee_id: user.id

    can [:read,
         :accounting_posts,
         :controlling,
         :create_comment,
         :search,
         :services,
         :show_targets,
         :show_uncertainties,
         :show_contract,
         :show_comments,
         :show_invoices,
         :reports,
         :show_plannings],
        Order

    can :show_plannings, AccountingPost

    can :read, [AccountingPost, Invoice, OrderUncertainty]

    can :read, Planning
    can :manage, Planning, employee_id: user.id

    can :manage, CustomList, employee_id: user.id

    can [:compose_report,
         :report,
         :export_csv,
         :userworkitems,
         :userabsences,
         :usersubworkitems,
         :subworkitems,
         :workitememployees,
         :orderworkitems],
        Evaluations::Evaluation

    can :manage, Expense, employee_id: user.id

    can [:create, :read], OrderComment
  end
end
