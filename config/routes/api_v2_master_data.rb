# frozen_string_literal: true

# Graphiti /api/v2 routes of the master data resources (drawn inside `namespace :v2` of config/routes.rb).
resources :absences
resources :billing_addresses
resources :contacts
resources :employment_roles
resources :employment_role_categories
resources :employment_role_levels
resources :holidays
resources :order_kinds
resources :order_statuses
resources :portfolio_items
resources :sectors
resources :services
resources :target_scopes
resources :user_notifications
resources :working_conditions
resources :workplaces
resources :departments
resources :employees, only: %i[index show]
