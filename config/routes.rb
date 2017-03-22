Rails.application.routes.draw do

  root to: 'worktimes#index'

  resources :absences, except: [:show]

  resources :clients, except: [:show] do
    collection do
      get :categories
      get :contacts_with_crm, to: 'contacts#with_crm'
    end

    resources :billing_addresses
    resources :contacts
  end

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
  end

  resources :employee_summaries, only: [:index, :show]

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

    resource :contract, only: [:show, :edit, :update]

    resource :multi_worktimes, only: [:update] do
      post :edit
      get :edit, to: redirect('/orders/%{order_id}/order_services')
    end

    resources :order_comments, only: [:index, :create, :edit, :update]
    resource :order_targets, only: [:show, :update]

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

  scope '/evaluator', controller: 'evaluator' do
    get ':action'

    post :change_period
  end

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

  get :weekly_graph, to: 'weekly_graph#show'
  get :vacations, to: 'vacations#show'

  scope '/reports' do
    get '/orders', to: 'order_reports#index', as: :reports_orders
    get '/workload', to: 'workload_report#index', as: :reports_workload
    get '/revenue', to: 'revenue_reports#index', as: :reports_revenue
  end

  scope '/login', controller: 'login' do
    match :login, via: [:get, :post]
    post :logout
  end

  get 'status', to: 'status#index'

  get '/404', to: 'errors#404'
  get '/500', to: 'errors#500'
  get '/503', to: 'errors#503'

  get 'design_guide', to: 'design_guide#index'

end
