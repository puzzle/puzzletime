
namespace :test do
  desc 'Run only non-integration tests'
  task unit: 'test:prepare' do
    $LOAD_PATH << 'test'
    Minitest.rake_run(['test/models', 'test/helpers', 'test/controllers', 'test/domain'])
  end

  desc 'Run tests for domain'
  task domain: 'test:prepare' do
    $LOAD_PATH << 'test'
    Minitest.rake_run(['test/domain'])
  end
end
