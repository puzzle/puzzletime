# frozen_string_literal: true

# Graphiti /api/v2 routes of accounting posts, invoices and plannings (drawn inside `namespace :v2`).

resources :accounting_posts
resources :invoices, only: %i[index show]
resources :plannings, only: %i[index show]
get 'orders/:id/accounting_posts', to: 'accounting_posts#by_order'
