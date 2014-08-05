class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, :to => :crud

    if user.management?
      can :manage, [Absence,
                    AccountingPost,
                    Client,
                    Department,
                    Employment,
                    Holiday,
                    Order,
                    OrderKind,
                    OrderStatus,
                    OvertimeVacation,
                    PortfolioItem,
                    TargetScope,
                    UserNotification,
                    WorkItem]
      can :crud, Employee
      can [:read, :create, :update], Worktime

      can [:clients,
           :employees,
           :overtime,
           :clientworkitems,
           :departments,
           :departmentorders,
           :managed,
           :employeeworkitems,
           :employeeabsences,
           :export_capacity_csv,
           :export_extended_capacity_csv,
           :export_ma_overview], Evaluation
    elsif user.order_responsible?
      can :create, Client
      can :create, WorkItem
      can :manage, Order, responsible_id: user.id
      can :manage, AccountingPost
      can :managed, Evaluation
    end

    can :manage, Worktime, employee_id: user.id

    can [:change_passwd, :update_passwd, :settings, :update_settings], Employee do |employee|
      employee == user
    end

    can :read, Order

    can :manage, Planning

    can :manage, EmployeeList

    can [:absencedetails,
         :empoloyeesubworkitmes,
         :userworkitems,
         :userabsences,
         :usersubworkitems,
         :subworkitems,
         :workitememployees], Evaluation

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/bryanrite/cancancan/wiki/Defining-Abilities
  end
end
