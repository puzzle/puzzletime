# encoding: utf-8
ENV['RAILS_ENV'] = 'test'

if ENV['TEST_REPORTS']
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.coverage_dir 'test/coverage'
  # use this formatter for jenkins compatibility
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.command_name 'Unit Tests'
  SimpleCov.start 'rails'
end

require File.expand_path('../../config/environment', __FILE__)
Rails.env = 'test'
require 'rails/test_help'
require 'mocha/mini_test'
require 'capybara/rails'
Settings.reload!

if ENV['TEST_REPORTS']
  require 'minitest/reporters'
  MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                            MiniTest::Reporters::JUnitReporter.new]
end

unless ENV['HEADLESS'] == 'false'
  require 'headless'

  headless = Headless.new(destroy_at_exit: false)
  headless.start
end

Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }


class ActiveSupport::TestCase

  include CustomAssertions

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def login
    login_as(:mark)
  end

  def login_as(user)
    @request.session[:user_id] = user ? employees(user).id : nil
  end

  def logout
    @request.session[:user_id] = nil
  end

end

class ActionDispatch::IntegrationTest

  include Capybara::DSL
  include IntegrationHelper

  DatabaseCleaner.strategy = :truncation

  self.use_transactional_tests = false

  setup do
    Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'].to_i if ENV['CAPYBARA_SERVER_PORT']
    Capybara.default_driver = :selenium
    Capybara.default_max_wait_time = 5
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

  if ENV['FIREFOX_PATH']
    Capybara.register_driver :selenium do |app|
      require 'selenium/webdriver'
      Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_PATH']
      capa = Selenium::WebDriver::Remote::Capabilities.firefox(marionette: false)
      Capybara::Selenium::Driver.new(app, browser: :firefox, desired_capabilities: capa)
    end
  end

end
