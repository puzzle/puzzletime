# frozen_string_literal: true

#  Copyright (c) 2006-2021, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ShowOrder < ActionDispatch::IntegrationTest
  setup :crm_start
  setup :login
  teardown :crm_stop

  ADDITIONAL_CRM_LABEL_TEXT = 'Weitere Highrise IDs'

  test 'show additional crm orders' do
    # check precondition
    assert_empty(order.additional_crm_orders)

    assert_selector(:xpath, ".//dt[contains(text(), '#{ADDITIONAL_CRM_LABEL_TEXT}')]")
    assert_empty additional_crm_links.all(:link, wait: false)

    # create some objects and reload page
    AdditionalCrmOrder.create!(order_id: order.id, crm_key: 'hello-world', name: '123')
    AdditionalCrmOrder.create!(order_id: order.id, crm_key: '42')
    visit current_path

    assert page.has_selector?('.orders-cockpit dd.value ul li a', text: 'hello-world: 123')
    assert page.has_selector?('.orders-cockpit dd.value ul li a', text: '42')

    additional_crm_links.all(:link, count: 2, wait: false)
    additional_crm_links.all(:link, href: /hello-world/, count: 1, wait: false)
    additional_crm_links.all(:link, href: /42/, count: 1, wait: false)
  end

  private

  def crm_start
    Settings.odoo.api_url = nil
    Settings.highrise.api_token = 'test'
    Crm.init
  end

  def crm_stop
    Settings.odoo.api_url = nil
    Settings.highrise.api_token = nil
    Crm.init
  end

  def login
    login_as(:mark)
    visit(order_path(order))
  end

  def order
    orders(:puzzletime)
  end

  def additional_crm_links_label
    find(:xpath, ".//dt[contains(text(), '#{ADDITIONAL_CRM_LABEL_TEXT}')]", visible: false)
  end

  def additional_crm_links
    additional_crm_links_label.find(:xpath, 'following-sibling::dd//ul', visible: false)
  end
end
