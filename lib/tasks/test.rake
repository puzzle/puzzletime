namespace :test do
  desc 'Run only non-integration tests'
  task units: ['test:models', 'test:controllers', 'test:helpers', 'test:mailers']
end
