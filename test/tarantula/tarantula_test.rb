# encoding: utf-8

require 'test_helper'
require 'relevance/tarantula'

class TarantulaTest < ActionDispatch::IntegrationTest
  # Load enough test data to ensure that there's a link to every page in your
  # application. Doing so allows Tarantula to follow those links and crawl
  # every page.  For many applications, you can load a decent data set by
  # loading all fixtures.
  fixtures :all

  CREDENTIALS = ['FOO', 'secret']


  def test_as_manager
    crawl_as_user(true)
  end

  def test_as_user
    crawl_as_user(false)
  end

  private

  def setup_crawler(t)
    # some links use example.com as a domain, allow them
    t.skip_uri_patterns.delete(/^http/)
    t.skip_uri_patterns << /^http(?!:\/\/www\.example\.com)/
    t.skip_uri_patterns << /\/login\/logout/ # do not logout during tests
    t.skip_uri_patterns << /\/employees\/#{user.id}$/ # do not modify logged in user
    t.skip_uri_patterns << /\?week_date=(#{outside_four_week_window}.)*$/ # only allows week strings from one week ago until two weeks from now.
    t.skip_uri_patterns << /evaluator\/change_period\?back_url/
    t.skip_uri_patterns << /orders\/crm_load/ # js only

    t.allow_404_for /^\-?\d+$/  # change period may produce such links in tarantula
    t.allow_404_for /ordertimes\/start$/  # passing invalid work_item_id
    t.allow_404_for /absencetimes\/\d+/   # absencetime deleted elsewhere
    t.allow_404_for /ordertimes\/\d+/   # ordertime deleted elsewhere
    t.allow_404_for /employee_lists(\/\d+)?$/   # invalid employee_ids assigned
    t.allow_404_for /orders(\/\d+)?$/   # invalid employee_ids assigned
    t.allow_404_for /evaluator\/details\?category_id=(0|\d{5,12})\&/   # invalid category
    t.allow_404_for /evaluator\/((export_csv)|(compose_report)|(book_all))\?.*division_id=\d\&/   # division may have been deleted
    t.allow_404_for /accounting_posts$/   # invalid order_id
    t.allow_404_for /work_items\?returning=true$/   # only handled by js
    t.allow_404_for /order_services\/report/  # may get invalid work_item_id
    t.allow_404_for /\?.*division_id=8/  # may have been deleted

    t.handlers << Relevance::Tarantula::InvalidHtmlHandler.new

    t.crawl_timeout = 20.minutes
  end

  def crawl_as_user(manager)
    create_worktimes
    create_plannings
    set_credentials(manager)

    start_crawling
  end

  def user
    @user ||= employees(:half_year_maria)
  end

  def start_crawling
    post '/login/login', user: CREDENTIALS.first, pwd: CREDENTIALS.last
    follow_redirect!

    t = tarantula_crawler(self)
    setup_crawler(t)
    t.crawl
  end

  def create_worktimes
    work_items = AccountingPost.all.collect{|w| w.work_item}
    5.times do
      work_item = work_items.sample
      Ordertime.create!(
        employee_id: user.id,
        work_item_id: work_item.id,
        report_type: ReportType['absolute_day'],
        hours: (1..9).to_a.sample,
        work_date: Date.today - (0..8).to_a.sample.days,
        description: 'yada yada')
    end
    Absencetime.create!(
      employee_id: user.id,
      absence_id: Absence.all.sample.id,
      report_type: ReportType['absolute_day'],
      hours: 4,
      work_date: Date.today - 1.week)
  end

  def create_plannings
    work_items = WorkItem.where(parent_id: nil)
    3.times do |i|
      work_item = work_items.sample
      Planning.create!(
        employee_id: user.id,
        work_item_id: work_item.id,
        start_week: Week.from_date(Date.today + ((i-1) * 7)).to_integer,
        end_week: Week.from_date(Date.today + ((i+1) * 7)).to_integer,
        monday_am: [true, false].sample,
        monday_pm: [true, false].sample,
        tuesday_am: [true, false].sample,
        tuesday_pm: [true, false].sample,
        wednesday_am: [true, false].sample,
        wednesday_pm: [true, false].sample,
        thursday_am: [true, false].sample,
        thursday_pm: true # select at least one half day
      )
    end
  end

  def set_credentials(manager)
    user.update_attributes!(
      shortname: CREDENTIALS.first,
      passwd: Employee.encode(CREDENTIALS.last),
      management: manager)
  end

  # Creates a regexp that only allows week strings from one week ago until two weeks from now.
  def outside_four_week_window
    today = Date.today
    [today - 7, today, today + 7, today + 14].collect do |d|
      "(?!#{d.cwyear}#{d.cweek})"
    end.join
  end

end
