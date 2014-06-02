# encoding: utf-8

require 'test_helper'
require 'relevance/tarantula'

class TarantulaTest < ActionDispatch::IntegrationTest
  # Load enough test data to ensure that there's a link to every page in your
  # application. Doing so allows Tarantula to follow those links and crawl
  # every page.  For many applications, you can load a decent data set by
  # loading all fixtures.
  fixtures :all

  def test_tarantula
    post '/login/login', user: 'ggg', pwd: 'Yaataw'
    follow_redirect!

    t = tarantula_crawler(self)

    t.skip_uri_patterns << /\/synchronize$/

    t.allow_404_for /^\-?\d+$/  # change period may produce such links in tarantula
    t.allow_404_for /projecttimes\/start$/  # passing invalid project_id
    t.allow_404_for /attendancetimes\/14/   # attendance modified elsewhere
    t.allow_404_for /attendancetimes\/split_attendance/  # attendance modified elsewhere

    t.crawl
  end

  # TODO: test as non-admin user
end
