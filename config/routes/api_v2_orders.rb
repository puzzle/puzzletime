# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Graphiti /api/v2 routes of orders and everything scoped under them (drawn inside `namespace :v2`).
resources :orders do
  member do
    patch :completed, to: 'order_operations#completed'
    patch :committed, to: 'order_operations#committed'
    patch :targets, to: 'order_operations#update_targets'
    get :contract, to: 'order_operations#contract'
    put :contract, to: 'order_operations#update_contract'

    %w[comments order_uncertainties order_risks order_chances targets invoices accounting_posts].each do |children|
      get children, to: 'order_children#index', defaults: { children: }
    end
  end
end
resources :clients
resources :order_comments, only: %i[show create update]
resources :order_uncertainties, only: %i[index show]
resources :order_risks
resources :order_chances
