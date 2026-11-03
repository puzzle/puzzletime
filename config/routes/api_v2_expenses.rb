# frozen_string_literal: true

# Graphiti /api/v2 routes of expenses, overtime vacations and employments (drawn inside `namespace :v2`).
resources :expenses do
  member do
    put :receipt, action: :update_receipt
    get :receipt, action: :show_receipt
    patch :review
  end
end
resources :overtime_vacations
resources :employments
