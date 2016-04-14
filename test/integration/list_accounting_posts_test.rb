# encoding: UTF-8

require 'test_helper'

class ListAccountingPostsTest < ActionDispatch::IntegrationTest
  test 'list accounting_posts when booked-on-order has no add link' do
    timeout_safe do
      list_accounting_posts_for :puzzletime
      assert has_no_link?('Buchungsposition hinzufügen')
      assert_selector('a.forbidden', text: 'Buchungsposition hinzufügen', count: 1)
    end
  end

  test 'list accounting_posts when booked on subposition has add link' do
    timeout_safe do
      list_accounting_posts_for :hitobito_demo
      assert has_link?('Buchungsposition hinzufügen')
    end
  end

  private

  def list_accounting_posts_for(order_label)
    login_as :mark
    visit order_accounting_posts_path(orders(order_label))
  end
end
