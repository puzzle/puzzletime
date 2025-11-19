# frozen_string_literal: true

#  Copyright (c) 2006-2023, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  devise_for :employees,
             controllers: { sessions: 'employees/sessions', omniauth_callbacks: 'employees/omniauth_callbacks' }, skip: [:registrations]
  as :employee do
    get 'employees/edit' => 'devise/registrations#edit', :as => 'edit_employee_registration'
    patch 'employees' => 'devise/registrations#update', :as => 'employee_registration'
  end

  root to: 'worktimes#index'

  # mount DryCrudJsonapiSwagger::Engine => '/apidocs'

  namespace :api do
    defaults format: :jsonapi do
      namespace :v1 do
        resources :employees, only: %i[index show]
      end
    end

    mount Rswag::Ui::Engine => 'docs'
    get '/docs/:api_version', to: 'apidocs#show', constraints: { api_version: /v\d+/ }
  end

  resources :absences, except: [:show]

  resources :clients, except: [:show] do
    collection do
      get :categories
      get :contacts_with_crm, to: 'contacts#with_crm'
    end

    resources :billing_addresses
    resources :contacts
  end

  get 'configurations', to: 'configurations#index'

  resources :departments, except: [:show]

  resources :employees do
    collection do
      get :settings
      patch :settings, to: 'employees#update_settings'
    end

    member do
      get :log, to: 'employees/log#index'
    end

    resources :expenses
    resources :employments, except: [:show]
    resources :overtime_vacations, except: [:show]
    resource :worktimes_commit, only: %i[edit update], controller: 'employees/worktimes_commit'
    resource :worktimes_review, only: %i[edit update], controller: 'employees/worktimes_review'
  end

  resources :expenses
  resources :expenses_reviews, only: %i[show create update index]

  resources :employment_roles, except: [:show]
  resources :employment_role_levels, except: [:show]
  resources :employment_role_categories, except: [:show]

  resources :holidays, except: [:show]

  resources :orders do
    collection do
      get :search
      post :crm_load
    end

    member do
      get :employees
    end

    resources :accounting_posts, except: [:show] do
      collection do
        get :export_csv
      end
    end

    resource :order_cost, only: [:show]

    resource :order_controlling, only: [:show], controller: 'order_controlling'

    resource :contract, only: %i[show edit update]

    resource :multi_worktimes, only: [:update] do
      post :edit
      get :edit, to: redirect('/orders/%{order_id}/order_services')
    end

    resources :order_comments, only: %i[index create edit update]
    resource :order_targets, only: %i[show update]
    resources :order_uncertainties, only: [:index]
    resources :order_risks, except: %i[index show],
                            defaults: { type: 'OrderRisk' },
                            controller: 'order_uncertainties'
    resources :order_chances, except: %i[index show],
                              defaults: { type: 'OrderChance' },
                              controller: 'order_uncertainties'

    resource :order_services, only: %i[show edit update] do
      get :export_worktimes_csv
      get :compose_report
      get :report
    end

    resources :invoices do
      collection do
        get :preview_total
        get :billing_addresses
        get :filter_fields
      end
      member do
        put :sync
      end
    end

    resource :order_plannings, only: %i[index show update destroy] do
      get 'new', on: :member, as: 'new'
    end

    resource :completed, only: %i[edit update], controller: 'orders/completed'
    resource :committed, only: %i[edit update], controller: 'orders/committed'
  end

  resources :order_statuses, except: [:show]

  resources :order_kinds, except: [:show]

  resources :portfolio_items, except: [:show]

  resources :sectors, except: [:show]

  resources :services, except: [:show]

  resources :target_scopes, except: [:show]

  resources :user_notifications, except: [:show]

  resources :work_items, only: %i[new create] do
    collection do
      get :search
    end
  end

  resources :working_conditions, except: [:show]

  resources :worktimes, only: [:index]

  resources :workplaces

  resources :ordertimes do
    collection do
      get :existing
      get :split
      match :create_part, via: %i[post patch]
      match :delete_part, via: %i[post delete]
    end
  end

  resources :absencetimes do
    collection do
      get :existing
    end
  end

  resources :employee_master_data, only: %i[index show]

  scope '/evaluator', controller: 'evaluator' do
    get :index, as: 'evaluator'
    get :overview
    get :details

    get :compose_report
    get :report
    get :export_csv

    get ':evaluation', to: 'evaluator#overview'
  end

  resource :periods, only: %i[show update destroy]

  namespace :plannings do
    resources :orders, only: %i[index show update destroy] do
      get 'new', on: :member, as: 'new'
    end

    resources :employees, only: %i[index show update destroy] do
      get 'new', on: :member, as: 'new'
    end

    resources :departments, only: [:index] do
      resource :multi_orders, only: %i[show new update destroy]
      resource :multi_employees, only: %i[show new update destroy]
    end

    resources :custom_lists do
      resource :multi_orders, only: %i[show new update destroy]
      resource :multi_employees, only: %i[show new update destroy]
    end

    resource :company, only: :show
  end

  resources :meal_compensations, only: %i[index show] do
    member do
      get :details
    end
  end

  get :vacations, to: 'vacations#show'
  get 'weekly_graph/:employee_id', to: 'weekly_graph#show', as: :weekly_graph

  scope '/reports' do
    get :orders, to: 'order_reports#index', as: :reports_orders
    get :invoices, to: 'invoice_reports#index', as: :reports_invoices
    put 'invoices/sync', to: 'invoice_reports#sync', as: :reports_invoices_sync
    get :workload, to: 'workload_report#index', as: :reports_workload
    get :revenue, to: 'revenue_reports#index', as: :reports_revenue
    get :capacity, to: 'capacity_report#index', as: :reports_capacity
    get :export, to: 'export_report#index', as: :reports_export
  end

  get '/login', to: redirect('/employees/sign_in')
  get '/login/login', to: redirect('/employees/sign_in')

  get 'status/health', to: 'status#health'
  get 'status/readiness', to: 'status#readiness'

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/503', to: 'errors#service_unavailable', via: :all

  get 'design_guide', to: 'design_guide#index'
end
