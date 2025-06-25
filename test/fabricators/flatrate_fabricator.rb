# frozen_string_literal: true

Fabricator(:flatrate) do
  accounting_post
  unit            { 14 }
  amount          { rand(1..200_000) }
  active_from     { '2015-01-01' }
  active_to       { '2024-12-10' }
  name            { Faker::Subscription.subscription_term }
  periodicity     { Array.new(12) { rand(1..20) } }
end
