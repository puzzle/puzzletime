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
    t.skip_uri_patterns << /\/synchronize$/

    t.allow_404_for /^\-?\d+$/  # change period may produce such links in tarantula
    t.allow_404_for /projecttimes\/start$/  # passing invalid project_id
    t.allow_404_for /attendancetimes\/\d+/   # attendance deleted elsewhere
    t.allow_404_for /absencetimes\/\d+/   # absencetime deleted elsewhere
    t.allow_404_for /projecttimes\/\d+/   # projecttime deleted elsewhere
    t.allow_404_for /attendancetimes\/split_attendance/  # attendance modified elsewhere
    t.allow_404_for /evaluator\/attendance_details\?category_id=(0|\d{5,12})\&/   # invalid category

    t.crawl_timeout = 20.minutes
  end

  def crawl_as_user(manager)
    user = employees(:half_year_maria)
    create_worktimes(user)
    user.update_attributes!(
      shortname: CREDENTIALS.first,
      passwd: Employee.encode(CREDENTIALS.last),
      management: manager)

    start_crawling
  end

  def start_crawling
    post '/login/login', user: CREDENTIALS.first, pwd: CREDENTIALS.last
    follow_redirect!

    t = tarantula_crawler(self)
    setup_crawler(t)
    t.crawl
  end

  def create_worktimes(user)
    projects = Project.leaves
    5.times do
      project = projects.sample
      Projectmembership.create(employee_id: user.id, project_id: project.top_project.id, active: true)
      Projecttime.create!(
        employee_id: user.id,
        project_id: project.id,
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

end
