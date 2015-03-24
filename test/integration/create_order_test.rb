# encoding: utf-8

require 'test_helper'

class CreateOrderTest < ActionDispatch::IntegrationTest

  setup :login

  teardown :reset_crm

  test 'create order with existing client, without category' do
    timeout_safe do
      click_add_contact # disabled
      assert page.has_no_selector?('#order_order_contacts_attributes_0_contact_id_or_crm')

      click_link('category_work_item_id_create_link') # disabled
      assert page.has_no_selector?('#work_item_name')

      selectize('client_work_item_id', 'Swisstopo')

      click_add_contact
      selectize('order_order_contacts_attributes_0_contact_id_or_crm', 'Stein Erich')
      fill_in('order_order_contacts_attributes_0_comment', with: 'Director')

      fill_mandatory_fields

      assert_creatable
      order = WorkItem.where(name: 'New Order').first
      assert_equal clients(:swisstopo).work_item_id, order.parent_id
      assert_equal [contacts(:swisstopo_2)], order.order.contacts
    end
  end

  test 'create order with new client, without category' do
    timeout_safe do
      create_client

      fill_mandatory_fields

      assert_creatable
      client = WorkItem.where(name: 'New Client').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, order.parent_id
    end
  end

  test 'create order with existing client and existing category' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      selectize('category_work_item_id', 'Interne Projekte')

      fill_mandatory_fields

      assert_creatable
      client = clients(:puzzle)
      category = work_items(:intern)
      order = WorkItem.where(name: 'New Order').first
      assert_equal category.id, order.parent_id
    end
  end

  test 'create order with existing client and selected, but not active category' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      selectize('category_work_item_id', 'Interne Projekte')
      uncheck('category_active')

      fill_mandatory_fields

      assert_creatable
      client = clients(:puzzle)
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.work_item_id, order.parent_id
    end
  end

  test 'create order with existing client and new category' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      create_category

      fill_mandatory_fields

      assert_creatable
      client = clients(:puzzle)
      category = WorkItem.where(name: 'New Category').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, category.parent_id
      assert_equal category.id, order.parent_id
    end
  end

  test 'create order with new client and new category' do
    timeout_safe do
      create_client
      check('category_active')
      create_category

      fill_mandatory_fields

      assert_creatable
      client = WorkItem.where(name: 'New Client').first
      category = WorkItem.where(name: 'New Category').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, category.parent_id
      assert_equal category.id, order.parent_id
    end
  end

  test 'create order with new client and new, but not active category' do
    timeout_safe do
      create_client
      check('category_active')
      create_category
      uncheck('category_active')

      fill_mandatory_fields

      assert_creatable
      client = WorkItem.where(name: 'New Client').first
      category = WorkItem.where(name: 'New Category').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, category.parent_id
      assert_equal client.id, order.parent_id
    end
  end

  test 'create order with changing clients changes category selection' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      element = find("#category_work_item_id + .selectize-control")
      element.find('.selectize-input').click # open dropdown
      options = element.find('.selectize-dropdown-content')
      assert options.has_selector?('div', count: 2)
      selectize('client_work_item_id', 'Swisstopo')
      assert !options.has_selector?('div')
    end
  end

  test 'create order with changing clients creates category for last selected client' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      click_link('category_work_item_id_create_link')
      click_link('Abbrechen')
      selectize('client_work_item_id', 'Swisstopo')
      click_link('category_work_item_id_create_link')
      fill_in('work_item_name', with: 'New Category')
      fill_in('work_item_shortname', with: 'NECA')
      click_button 'Speichern'

      assert find("#category_work_item_id + .selectize-control").
        has_selector?('.selectize-input .item', text: 'New Category')
      #sleep 0.2
      id = find('#category_work_item_id', visible: false)['value']

      category = WorkItem.find(id)
      assert_equal 'New Category', category.name
      assert_equal work_items(:swisstopo).id, category.parent_id
    end
  end

  test 'create order with changed client and category selections' do
    timeout_safe do
      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      selectize('category_work_item_id', 'Interne Projekte')
      selectize('client_work_item_id', 'Swisstopo')

      fill_mandatory_fields

      assert_creatable
      order = WorkItem.where(name: 'New Order').first
      assert_equal work_items(:swisstopo).id, order.parent_id
    end
  end

  test 'create order with changing clients load contacts for last one' do
    timeout_safe do
      selectize('client_work_item_id', 'Swisstopo')
      selectize('client_work_item_id', 'Puzzle')
      selectize('client_work_item_id', 'PBS')

      click_add_contact

      selectize = find("#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control")
      selectize.find('.selectize-input').click # populate & open dropdown
      assert selectize.has_no_selector?(".selectize-dropdown-content .option")

      selectize('client_work_item_id', 'Puzzle')

      click_add_contact

      selectize = find("#order_order_contacts_attributes_1_contact_id_or_crm + .selectize-control")
      selectize.find('.selectize-input').click # populate & open dropdown
      assert selectize.has_selector?(".selectize-dropdown-content .option", count: 2)
    end
  end

  test 'failed create order keeps client and category selection' do
    timeout_safe do
      order = Order.new(department: departments(:devone),
                        responsible: employees(:mark),
                        kind: order_kinds(:projekt))
      order.build_work_item(parent_id: work_items(:intern).id, name: 'New Order', shortname: 'NEOR')
      order.save!

      selectize('client_work_item_id', 'Puzzle')
      check('category_active')
      selectize('category_work_item_id', 'Interne Projekte')
      fill_mandatory_fields

      click_button 'Speichern'

      assert_text('ist bereits vergeben')
      assert_equal work_items(:puzzle).id.to_s, find('#client_work_item_id', visible: false)['value']
      assert_equal work_items(:intern).id.to_s, find('#category_work_item_id', visible: false)['value']
      assert has_checked_field?('category_active')
    end
  end

  test 'order name and new client is filled from crm' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: 'New Client', key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns(
        [{ lastname: 'Miller', firstname: 'John', crm_key: 123 },
         { lastname: 'Nader', firstname: 'Fred', crm_key: 456 }]
      ).twice
      Crm.instance.expects(:find_person).with('456').returns(
        { lastname: 'Nader', firstname: 'Fred', crm_key: 456 })

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      assert_equal 'New Client', find('#client_work_item_attributes_name')['value']
      fill_in('client_work_item_attributes_shortname', with: 'NECL')
      click_button 'Speichern'

      assert_equal 'New Order', find('#order_work_item_attributes_name')['value']

      click_add_contact
      selectize('order_order_contacts_attributes_0_contact_id_or_crm', 'Nader Fred')

      fill_mandatory_fields(false)

      assert_creatable
      client = WorkItem.where(name: 'New Client').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, order.parent_id
      contact = Contact.find_by_lastname('Nader')
      assert_equal '456', contact.crm_key
      assert_equal client.client, contact.client
      assert_equal [contact], order.order.contacts
    end
  end

  test 'order name and new client is filled from crm, category is added' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: 'New Client', key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns([]).twice

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      assert_equal 'New Client', find('#client_work_item_attributes_name')['value']
      fill_in('client_work_item_attributes_shortname', with: 'NECL')
      click_button 'Speichern'

      assert_equal 'New Order', find('#order_work_item_attributes_name')['value']

      check('category_active')
      create_category
      fill_mandatory_fields(false)

      assert_creatable
      client = WorkItem.where(name: 'New Client').first
      category = WorkItem.where(name: 'New Category').first
      order = WorkItem.where(name: 'New Order').first
      assert_equal client.id, category.parent_id
      assert_equal category.id, order.parent_id
    end
  end

  test 'order name and existing client is filled from crm' do
    timeout_safe do
      Crm.instance = Crm::Base.new
      client = clients(:swisstopo)
      client.update!(crm_key: '456')
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: client.name, key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns(
        [{ lastname: 'Miller', firstname: 'John', crm_key: 123 },
         { lastname: 'Nader', firstname: 'Fred', crm_key: 456 }]
      ).twice
      Crm.instance.expects(:find_person).with('456').returns(
        { lastname: 'Nader', firstname: 'Fred', crm_key: 456 })

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      assert_equal 'New Order', find('#order_work_item_attributes_name')['value']

      click_add_contact

      selectize('order_order_contacts_attributes_0_contact_id_or_crm', 'Nader Fred')
      fill_mandatory_fields(false)

      assert_creatable
      order = WorkItem.where(name: 'New Order').first
      assert_equal clients(:swisstopo).work_item_id, order.parent_id
      assert_equal [Contact.find_by_lastname('Nader')], order.order.contacts
    end
  end

  test 'order name and existing client is filled from crm, new category is added' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      client = clients(:swisstopo)
      client.update!(crm_key: '456')
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: client.name, key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns([]).twice

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      check('category_active')
      create_category
      fill_mandatory_fields(false)

      assert_creatable
      order = WorkItem.where(name: 'New Order').first
      category = WorkItem.where(name: 'New Category').first
      assert_equal client.work_item_id, category.parent_id
      assert_equal category.id, order.parent_id
    end
  end

  test 'order name and existing client is filled from crm, existing category is selected' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      client = clients(:puzzle)
      client.update!(crm_key: '456')
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: client.name, key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns([]).twice

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      check('category_active')
      selectize('category_work_item_id', 'Interne Projekte')
      fill_mandatory_fields(false)

      assert_creatable
      order = WorkItem.where(name: 'New Order').first
      category = work_items(:intern)
      assert_equal category.id, order.parent_id
    end
  end

  test 'failed create order keeps client selection' do
    timeout_safe do
      order = Order.new(department: departments(:devone),
                        responsible: employees(:mark),
                        kind: order_kinds(:projekt))
      order.build_work_item(parent_id: work_items(:puzzle).id, name: 'New Order', shortname: 'NEOR')
      order.save!

      Crm.instance = Crm::Highrise.new
      client = clients(:puzzle)
      client.update!(crm_key: '456')
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: client.name, key: '456' }
      })
      Crm.instance.expects(:find_client_contacts).returns(
        [{ lastname: 'Miller', firstname: 'John', crm_key: 123 },
         { lastname: 'Nader', firstname: 'Fred', crm_key: 456 }]
      ).twice
      Crm.instance.expects(:find_person).with('456').returns(
        { lastname: 'Nader', firstname: 'Fred', crm_key: 456 })

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      click_add_contact
      selectize('order_order_contacts_attributes_0_contact_id_or_crm', 'Hauswart Hans')
      click_add_contact
      selectize('order_order_contacts_attributes_1_contact_id_or_crm', 'Nader Fred')

      fill_mandatory_fields(false)

      click_button 'Speichern'

      assert_text('ist bereits vergeben')
      assert_equal '123', find('#order_crm_key')['value']
      assert_equal work_items(:puzzle).id.to_s, find('#client_work_item_id', visible: false)['value']
      assert_equal 'New Order', find('#order_work_item_attributes_name')['value']
      assert has_unchecked_field?('category_active')

      selecti0 = find("#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control")
      assert selecti0.find('.selectize-input').has_content?('Hauswart Hans')
      selecti0.find('.selectize-input').click # populate & open dropdown
      assert selecti0.has_selector?(".selectize-dropdown-content .option", count: 3)

      selecti1 = find("#order_order_contacts_attributes_1_contact_id_or_crm + .selectize-control")
      assert selecti1.find('.selectize-input').has_content?('Nader Fred')

      click_add_contact
      selectize('order_order_contacts_attributes_2_contact_id_or_crm', 'Miller John')
    end
  end

  test 'unknown crm key returns message' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      Crm.instance.expects(:find_order).with('123').returns(nil)

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      assert page.has_selector?('#crm_key', text: 'Nicht gefunden')
    end
  end

  test 'existing crm order returns message' do
    timeout_safe do
      Crm.instance = Crm::Highrise.new
      order = orders(:puzzletime)
      order.update!(crm_key: '123')
      Crm.instance.expects(:find_order).with('123').returns({
        name: 'New Order',
        key: 123,
        url: 'http://crm/orders/123',
        client: { name: 'Puzzle', key: '456' }
      })

      # reload after crm change
      visit(new_order_path)

      fill_in('order_crm_key', with: '123')
      click_link('Übernehmen')

      assert_match /bereits erfasst/, find('#crm_key').text
    end
  end

  test 'create order team members fields' do
    visit(new_order_path)

    assert has_no_field?("order_order_team_members_attributes_0_employee_id")
    assert_no_selector("a[data-object-class='order-team-member'].remove_nested_fields_link")

    find("a[data-object-class='order_team_member'].add_nested_fields_link").click
    assert find_field("order_order_team_members_attributes_0_employee_id", visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_team_member'].remove_nested_fields_link", count: 1)

    find("a[data-object-class='order_team_member'].add_nested_fields_link").click
    assert find_field("order_order_team_members_attributes_1_employee_id", visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_team_member'].remove_nested_fields_link", count: 2)
  end

  private

  def create_client
    click_link('client_work_item_id_create_link')
    fill_in('client_work_item_attributes_name', with: 'New Client')
    fill_in('client_work_item_attributes_shortname', with: 'NECL')
    click_button 'Speichern'
  end

  def create_category
    click_link('category_work_item_id_create_link')
    fill_in('work_item_name', with: 'New Category')
    fill_in('work_item_shortname', with: 'NECA')
    click_button 'Speichern'
  end

  def click_add_contact
    find("a.add_nested_fields_link[data-object-class='order_contact']").click
  end

  def fill_mandatory_fields(with_name = true)
    fill_in('order_work_item_attributes_name', with: 'New Order') if with_name
    fill_in('order_work_item_attributes_shortname', with: 'NEOR')
    selectize('order_department_id', 'devone')
    selectize('order_kind_id', 'Projekt')
    selectize('order_responsible_id', employees(:mark).to_s)
  end

  def assert_creatable
    click_button 'Speichern'
    assert has_content?('New Order wurde erfolgreich erstellt')
  end

  def reset_crm
    Crm.instance = nil
  end

  def login
    login_as(:mark, new_order_path)
  end
end
