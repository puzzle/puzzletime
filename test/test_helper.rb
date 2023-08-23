#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

ENV['RAILS_ENV'] = 'test'

# if ENV['TEST_REPORTS']
#   require 'simplecov'
#   require 'simplecov-rcov'
#   SimpleCov.coverage_dir 'test/coverage'
#   # use this formatter for jenkins compatibility
#   SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
#   SimpleCov.command_name 'Unit Tests'
#   SimpleCov.start 'rails'

#   require 'minitest/reporters'
#   MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
#                             MiniTest::Reporters::JUnitReporter.new]
# end

require File.expand_path('../../config/environment', __FILE__)
Rails.env = 'test'
require 'rails/test_help'
require 'mocha/minitest'
require 'capybara/rails'

require 'webmock/minitest'
WebMock.disable_net_connect!(
  allow_localhost: true, # required for selenium
  allow: [
    'github.com', # required for webdrivers/geckodriver
    /github-production-release-asset-\w+.s3.amazonaws.com/, # required for webdrivers/geckodriver
    /github-releases.githubusercontent.com/, # required for webdrivers/geckodriver
    /objects.githubusercontent.com/, # required for webdrivers/geckodriver
    'chromedriver.storage.googleapis.com' # required for webdrivers/chromedriver
  ]
)

Settings.reload!

Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }

# load Cuprite Capybara integration
require 'capybara/cuprite'

Capybara.register_driver :chrome do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1920, 1080],
      # See additional options for Dockerized environment in the respective section of this article
      browser_options: {
        # Required for ARM chips on which CI might run
        'disable-smooth-scrolling' => true,
      },
      # Increase Chrome startup wait time (required for stable CI builds)
      process_timeout: 10,
      # Enable debugging capabilities
      inspector: true,
      # Allow running Chrome in a headful mode by setting HEADLESS env
      # var to a falsey value
      headless: !ENV['HEADLESS'].in?(%w[n 0 no false])
  )
end

Capybara.default_driver = Capybara.javascript_driver = :chrome
Capybara.server = :puma, { Silent: true } # Silence that nasty log output
Capybara.default_max_wait_time = 5

class ActiveSupport::TestCase
  include CustomAssertions

  extend RetryOnFlakyTests[
    # randomly happening on CI
    Ferrum::PendingConnectionsError,
    # race condition when trying to move mouse to element, can happen e.g. after fade-in/out of modal dialog
    Ferrum::CoordinatesNotFoundError,
    # race condition when trying to click element, can happen e.g. after fade-in/out of modal dialog
    Capybara::Cuprite::MouseEventFailed,
    max_tries: 3
  ]

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
    employee = employees(user)
    sign_in employee
    @request.session[:user_id] = user ? employee.id : nil
    @request.session[:employee_id] = user ? employee.id : nil
  end

  def logout
    sign_out Employee
    @request.session[:user_id] = @request.session[:employee_id] = nil
  end

  # Since we've removed the hardcoded regular holidays, insert them manually
  def setup_regular_holidays(years)
    years = [years].flatten.compact
    dates = [[1, 1], [2, 1], [1, 8], [25, 12], [26, 12]]
    dates.each do |day, month|
      years.each do |year|
        Holiday.create!(holiday_date: Date.new(year, month, day), musthours_day: 0)
      end
    end
  end

  def set_period(start_date: '1.1.2006', end_date: '31.12.2006')
    @controller.session[:period] = [start_date, end_date]
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Devise::Test::IntegrationHelpers
  include IntegrationHelper

  DatabaseCleaner.strategy = :truncation

  self.use_transactional_tests = false

  setup do
    clear_cookies
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
