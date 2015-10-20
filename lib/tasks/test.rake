namespace :test do
  task units: ['test:models', 'test:controllers', 'test:helpers', 'test:mailers']
end
