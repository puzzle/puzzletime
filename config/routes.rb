Rails.application.routes.draw do

  root to: 'evaluator#user_projects'

  concern :memberships do
    post :manager, to: 'create_manager'
    delete :manager, to: 'destroy_manager'
    post :membership, to: 'create_membership'
    delete :membership, to: 'destroy_membership'
  end

  concern :with_projects do
    resources :projects, only: [:index, :edit, :update] do
      resources :projects, only: [:index, :edit, :update] do
        resource :project_memberships, only: [:show], concerns: :memberships
      end
    end
  end

  resources :absences, except: [:show]

  resources :clients, only: [:index], concerns: :with_projects

  resources :departments, only: [:index], concerns: :with_projects

  resources :employees, except: [:show, :destroy] do
    collection do
      get :settings
      post :settings, to: 'employees#update_settings'
      get :passwd
      post :passwd, to: 'employees#update_passwd'
    end

    resources :employments, only: [:index]
    resources :overtime_vacations, except: [:show]
    resource :employee_memberships, only: [:show], concerns: :memberships
  end

  resources :employee_lists

  resource :employee_memberships, only: [:show], concerns: :memberships

  resources :holidays, except: [:show]

  resources :user_notifications, execpt: [:show]

  concerns :with_projects

  scope '/planning', controller: 'planning' do
    post 'create'
    post 'update'
    post 'delete'
    get ':action'
  end

  scope '/login', controller: 'login' do
    match 'login', via: [:get, :post, :patch]
    post 'logout'
  end

  # TODO: POST actions:
  # evaluator  :complete_project, :complete_all, :book_all
  # attendancetime :auto_start_stop, :startNow, :endNow
  # manage: :create, :update, :delete, :synchronize
  # worktime: :delete, :create_part, :delete_part, :start, :stop, :create, :update

  # Install the default route as the lowest priority.
  match '/:controller(/:action(/:id))', via: [:get, :post, :patch]

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
