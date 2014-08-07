# encoding: utf-8

require 'test_helper'

class CreateOrderTest < ActionDispatch::IntegrationTest

  setup :login

  test 'create order with existing client, without category' do
    selectize('client_work_item_id', 'Swisstopo')
    fill_mandatory_fields

    assert_creatable
    order = WorkItem.where(name: 'New Order').first
    assert_equal clients(:swisstopo).work_item_id, order.parent_id
  end

  test 'create order with new client, without category' do
    create_client

    fill_mandatory_fields

    assert_creatable
    client = WorkItem.where(name: 'New Client').first
    order = WorkItem.where(name: 'New Order').first
    assert_equal client.id, order.parent_id
  end

  test 'create order with existing client and existing category' do
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

  test 'create order with existing client and selected, but not active category' do
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

  test 'create order with existing client and new category' do
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

  test 'create order with new client and new category' do
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

  test 'create order with new client and new, but not active category' do
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

  test 'create order with changing clients changes category selection' do
    selectize('client_work_item_id', 'Puzzle')
    check('category_active')
    element = find("#category_work_item_id + .selectize-control")
    element.find('.selectize-input').click # open dropdown
    options = element.find('.selectize-dropdown-content')
    assert options.has_selector?('div', count: 2)
    selectize('client_work_item_id', 'Swisstopo')
    assert !options.has_selector?('div')
  end

  test 'create order with changing clients creates category for last selected client' do
    selectize('client_work_item_id', 'Puzzle')
    check('category_active')
    click_link('category_work_item_id_create_link')
    click_link('Abbrechen')
    selectize('client_work_item_id', 'Swisstopo')
    click_link('category_work_item_id_create_link')
    fill_in('work_item_name', with: 'New Category')
    fill_in('work_item_shortname', with: 'NECA')
    click_button 'Speichern'
    sleep 0.1
    id = find('#category_work_item_id', visible: false)['value']

    category = WorkItem.find(id)
    assert_equal 'New Category', category.name
    assert_equal work_items(:swisstopo).id, category.parent_id
  end

  test 'create order with changed client and category selections' do
    selectize('client_work_item_id', 'Puzzle')
    check('category_active')
    selectize('category_work_item_id', 'Interne Projekte')
    selectize('client_work_item_id', 'Swisstopo')

    fill_mandatory_fields

    assert_creatable
    order = WorkItem.where(name: 'New Order').first
    assert_equal work_items(:swisstopo).id, order.parent_id
  end

  test 'failed create order keeps client and category selection' do
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

  def fill_mandatory_fields
    fill_in('order_work_item_attributes_name', with: 'New Order')
    fill_in('order_work_item_attributes_shortname', with: 'NEOR')
    selectize('order_department_id', 'devone')
    selectize('order_kind_id', 'Projekt')
    selectize('order_responsible_id', employees(:mark).to_s)
  end

  def assert_creatable
    click_button 'Speichern'
    assert has_content?('New Order wurde erfolgreich erstellt')
  end

  def login
    login_as(:mark, new_order_path)
  end
end
