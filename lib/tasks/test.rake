namespace :test do

  desc 'Run only non-integration tests'
  task units: ['test:models', 'test:domain', 'test:controllers', 'test:helpers', 'test:mailers']

  desc 'Run tests for domain'
  Rake::TestTask.new('domain') do |t|
    t.libs << 'test'
    t.pattern = 'test/domain/**/*_test.rb'
  end

end
