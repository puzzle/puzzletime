#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'worktimes#index'

  # mount DryCrudJsonapiSwagger::Engine => '/apidocs'

  namespace :api do
    mount Rswag::Ui::Engine => 'doc'
    get 'swagger', to: 'apidocs#show'

    namespace :v1 do
      resources :employees, only: [:index, :show]
    end

    #get '*path', to: redirect("/api/v1/%{path}")
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
      get :passwd
      post :passwd, to: 'employees#update_passwd'
    end

    member do
      get :log, to: 'employees/log#index'
    end

    resources :employments, except: [:show]
    resources :overtime_vacations, except: [:show]
    resource :worktimes_commit, only: [:edit, :update], controller: 'employees/worktimes_commit'
    resource :worktimes_review, only: [:edit, :update], controller: 'employees/worktimes_review'
  end

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

    resources :accounting_posts, except: [:show]

    resource :order_controlling, only: [:show], controller: 'order_controlling'

    resource :contract, only: [:show, :edit, :update]

    resource :multi_worktimes, only: [:update] do
      post :edit
      get :edit, to: redirect('/orders/%{order_id}/order_services')
    end

    resources :order_comments, only: [:index, :create, :edit, :update]
    resource :order_targets, only: [:show, :update]
    resources :order_uncertainties, only: [:index]
    resources :order_risks, except: [:index, :show],
                            defaults: { type: 'OrderRisk' },
                            controller: 'order_uncertainties'
    resources :order_chances, except: [:index, :show],
                              defaults: { type: 'OrderChance' },
                              controller: 'order_uncertainties'

    resource :order_services, only: [:show, :edit, :update] do
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

    resource :order_plannings, only: [:index, :show, :update, :destroy] do
      get 'new', on: :member, as: 'new'
    end

    resource :completed, only: [:edit, :update], controller: 'orders/completed'
    resource :committed, only: [:edit, :update], controller: 'orders/committed'
  end

  resources :order_statuses, except: [:show]

  resources :order_kinds, except: [:show]

  resources :portfolio_items, except: [:show]

  resources :sectors, except: [:show]

  resources :services, except: [:show]

  resources :target_scopes, except: [:show]

  resources :user_notifications, except: [:show]

  resources :work_items, only: [:new, :create] do
    collection do
      get :search
    end
  end

  resources :working_conditions, except: [:show]

  resources :worktimes, only: [:index]

  resources :ordertimes do
    collection do
      get :existing
      get :split
      match :create_part, via: [:post, :patch]
      match :delete_part, via: [:post, :delete]
    end
  end

  resources :absencetimes do
    collection do
      get :existing
    end
  end

  resources :employee_master_data, only: [:index, :show]

  scope '/evaluator', controller: 'evaluator' do
    get :index
    get :overview
    get :details

    get :compose_report
    get :report
    get :export_csv

    get ':evaluation', to: 'evaluator#overview'
  end

  resource :periods, only: [:show, :update, :destroy]

  namespace :plannings do
    resources :orders, only: [:index, :show, :update, :destroy] do
      get 'new', on: :member, as: 'new'
    end

    resources :employees, only: [:index, :show, :update, :destroy] do
      get 'new', on: :member, as: 'new'
    end

    resources :departments, only: [:index] do
      resource :multi_orders, only: [:show, :new, :update, :destroy]
      resource :multi_employees, only: [:show, :new, :update, :destroy]
    end

    resources :custom_lists do
      resource :multi_orders, only: [:show, :new, :update, :destroy]
      resource :multi_employees, only: [:show, :new, :update, :destroy]
    end

    resource :company, only: :show
  end

  get :vacations, to: 'vacations#show'
  get 'weekly_graph/:employee_id', to: 'weekly_graph#show', as: :weekly_graph

  scope '/reports' do
    get :orders, to: 'order_reports#index', as: :reports_orders
    get :workload, to: 'workload_report#index', as: :reports_workload
    get :revenue, to: 'revenue_reports#index', as: :reports_revenue
    get :capacity, to: 'capacity_report#index', as: :reports_capacity
    get :role_distribution, to: 'role_distribution_report#index', as: :reports_role_distribution
  end

  scope '/login', controller: 'login' do
    match :login, via: [:get, :post]
    post :logout
  end

  get 'status/health', to: 'status#health'
  get 'status/readiness', to: 'status#readiness'

  get '/404', to: 'errors#404'
  get '/500', to: 'errors#500'
  get '/503', to: 'errors#503'

  get 'design_guide', to: 'design_guide#index'

end
