require 'test_helper'

class GemsuranceTest < ActiveSupport::TestCase
  test 'included gems have no known security vulnerability' do
    skip "skipped as not run with GEMSURANCE=true" unless ENV['GEMSURANCE'].to_s.downcase == 'true'
    `bundle exec gemsurance`
    assert $?.to_i.zero?, "One or more of your Ruby gems has a known security vulnerability. Check #{Rails.root}/gemsurance_report.html for more info."
  end
end