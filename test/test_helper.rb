# encoding: utf-8

require 'simplecov'
require 'simplecov-rcov'
SimpleCov.coverage_dir 'test/coverage'
# use this formatter for jenkins compatibility
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.command_name 'Unit Tests'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'

MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]

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
