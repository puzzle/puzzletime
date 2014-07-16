Rails.application.routes.draw do

  root to: 'worktimes#index'

  concern :with_projects do
    resources :projects, except: [:show] do
      resources :projects, except: [:show]

      collection do
        get :search
      end
    end
  end

  resources :absences, except: [:show]

  resources :clients,except: [:show] do
    concerns :with_projects
  end

  resources :departments, except: [:show] do
    concerns :with_projects
  end

  resources :employees, except: [:show] do
    collection do
      get :settings
      patch :settings, to: 'employees#update_settings'
      get :passwd
      post :passwd, to: 'employees#update_passwd'
    end

    resources :employments, except: [:show]
    resources :overtime_vacations, except: [:show]
  end

  resources :employee_lists

  resources :holidays, except: [:show]

  # TODO limit actions
  resources :orders

  resources :order_statuses, except: [:show]

  resources :order_kinds, except: [:show]

  # TODO limit actions
  resources :path_items

  resources :portfolio_items, except: [:show]

  resources :target_scopes, except: [:show]

  resources :user_notifications, except: [:show]

  concerns :with_projects

  resources :worktimes, only: [:index]

  resources :projecttimes do
    collection do
      get :existing
      post :start
      post :stop
      match :create_part, via: [:post, :patch]
      match :delete_part, via: [:post, :delete]

      get :running
      get :split
    end
  end

  resources :absencetimes do
    collection do
      get :existing
    end
  end

  scope '/evaluator', controller: 'evaluator' do
    get ':action'

    post :book_all
    post :change_period
  end

  resources :plannings do
    collection do
      get ':action'
    end
  end

  resource :graph, only: [], controller: :graph do
    get :weekly
    get :all_absences
  end

  scope '/login', controller: 'login' do
    match :login, via: [:get, :post]
    post :logout
  end

  get 'status', to: 'status#index'


  # Install the default route as the lowest priority.
  #match '/:controller(/:action(/:id))', via: [:get, :post, :patch]


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
