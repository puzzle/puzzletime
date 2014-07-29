require 'test_helper'

class OrdersControllerTest < ActionController::TestCase

  setup :login

  test 'GET index sorted by order' do
    get :index, sort: 'order'
    assert_equal orders(:allgemein, :hitobito_demo, :puzzletime), assigns(:orders)
  end

  test 'GET index sorted by kind' do
    get :index, sort: 'kind'
    assert_equal orders(:allgemein, :puzzletime, :hitobito_demo), assigns(:orders)
  end

  test 'GET index sorted by department' do
    get :index, sort: 'department'
    assert_equal orders(:puzzletime, :hitobito_demo, :allgemein), assigns(:orders)
  end

  test 'GET index sorted by responsible' do
    get :index, sort: 'responsible'
    assert_equal orders(:allgemein, :hitobito_demo, :puzzletime), assigns(:orders)
  end

  test 'GET index sorted by status' do
    get :index, sort: 'status'
    assert_equal orders(:hitobito_demo, :puzzletime, :allgemein), assigns(:orders)
  end

  test 'GET new presets some values' do
    get :new
    user = employees(:mark)
    order = assigns(:order)
    assert_equal user.department_id, order.department_id
    assert_equal user, order.responsible
  end

  test 'POST create sets values' do
    assert_difference('Order.count') do
      post :create, client_work_item_id: clients(:swisstopo).id,
                    order: {
                      work_item_attributes: {
                        name: 'New Order',
                        shortname: 'NEO'
                      },
                      department_id: departments(:devtwo).id,
                      responsible_id: employees(:pascal).id,
                      kind_id: order_kinds(:projekt).id,
                      status_id: order_statuses(:bearbeitung).id }
    end

    assert_redirected_to orders_path(returning: true)

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal 'NEO', item.shortname
    assert_equal clients(:swisstopo).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id
  end

  test 'PATCH update sets values' do
    patch :update, id: orders(:puzzletime).id,
                   order: {
                     work_item_attributes: {
                       name: 'New Order',
                       shortname: 'NEO'
                     },
                     department_id: departments(:devtwo).id,
                     responsible_id: employees(:pascal).id,
                     kind_id: order_kinds(:projekt).id,
                     status_id: order_statuses(:bearbeitung).id }

    assert_redirected_to orders_path(returning: true)

    order = orders(:puzzletime).reload
    item = order.work_item
    assert_equal 'New Order', item.name
    assert_equal 'NEO', item.shortname
    assert_equal clients(:puzzle).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id
  end
end
