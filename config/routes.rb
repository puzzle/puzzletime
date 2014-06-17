Rails.application.routes.draw do

  root to: 'worktimes#index'

  concern :memberships do
    post 'manager/:id', action: 'create_manager'
    delete 'manager/:id', action: 'destroy_manager'
    post :membership, action: 'create_membership'
    delete 'membership/:id', action: 'destroy_membership'
  end

  concern :with_projects do
    resources :projects, only: [:index, :edit, :update] do
      resources :projects, only: [:index, :edit, :update]
      resource :project_memberships, only: [:show], concerns: :memberships

      collection do
        post :synchronize
      end
    end
  end

  resources :absences, except: [:show]

  resources :clients, only: [:index] do
    collection do
      post :synchronize
    end

    concerns :with_projects
  end

  resources :departments, only: [:index] do
    collection do
      post :synchronize
    end

    concerns :with_projects
  end

  resources :employees, only: [:index, :edit, :update] do
    collection do
      get :settings
      post :settings, to: 'employees#update_settings'
      get :passwd
      post :passwd, to: 'employees#update_passwd'
      post :synchronize
    end

    resources :employments, only: [:index]
    resources :overtime_vacations, except: [:show]
    resource :employee_memberships, only: [:show], concerns: :memberships
  end

  resources :employee_lists

  resource :employee_memberships, only: [:show], concerns: :memberships

  resources :holidays, except: [:show]

  resources :user_notifications, except: [:show]

  concerns :with_projects

  resources :worktimes, only: [] do
    collection do
      get :running
    end
  end

  resources :projecttimes do
    member do
      get :confirm_delete
    end

    collection do
      post 'start'
      post 'stop'
      post 'create_part'
      match 'delete_part', via: [:post, :delete]

      get ':action'
    end
  end

  resources :absencetimes do
    member do
      get :confirm_delete
    end

    collection do
      post :create_multi_absence
      get ':action'
    end
  end

  scope '/evaluator', controller: 'evaluator' do
    post :complete_project
    post :complete_all
    post :book_all
    post :change_period

    get ':action'
  end

  resources :plannings do
    collection do
      get ':action'
    end
  end

  scope '/graph', controller: 'graph' do
    get :weekly
    get :all_absences
  end

  scope '/login', controller: 'login' do
    match 'login', via: [:get, :post, :patch]
    post 'logout'
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
