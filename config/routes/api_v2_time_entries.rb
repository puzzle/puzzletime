# frozen_string_literal: true

# Graphiti /api/v2 routes of the time entry resources (drawn inside `namespace :v2` of config/routes.rb).
resources :ordertimes do
  post :repeat, on: :collection
end

resources :absencetimes do
  post :multi, on: :collection
end

# Not part of the employee resource: marking months as committed / reviewed has its own rules (Completable).
patch 'employees/:id/worktimes_commit', to: 'worktime_completions#commit'
patch 'employees/:id/worktimes_review', to: 'worktime_completions#review'
