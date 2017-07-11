require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup :login

  test 'GET index sorted by order' do
    get :index, params: { sort: 'order', status_id: '' }
    assert_equal orders(:allgemein, :hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
  end

  test 'GET index sorted by kind' do
    get :index, params: { sort: 'kind', status_id: '' }
    assert_equal orders(:allgemein, :puzzletime, :hitobito_demo, :webauftritt), assigns(:orders)
  end

  test 'GET index sorted by department' do
    get :index, params: { sort: 'department', status_id: '' }
    assert_equal orders(:puzzletime, :webauftritt, :hitobito_demo, :allgemein), assigns(:orders)
  end

  test 'GET index sorted by responsible' do
    get :index, params: { sort: 'responsible', status_id: '' }
    assert_equal orders(:webauftritt, :allgemein, :hitobito_demo, :puzzletime), assigns(:orders)
  end

  test 'GET index sorted by status' do
    get :index, params: { sort: 'status', status_id: '' }
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt, :allgemein), assigns(:orders)
  end

  test 'GET index with default filter for manager' do
    login_as(:mark)
    get :index
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index with default filter for user' do
    login_as(:pascal)
    get :index
    assert_equal [orders(:hitobito_demo)], assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id,
                   'department_id' => departments(:devtwo).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index with default filter for responsible' do
    login_as(:lucien)
    get :index
    assert_equal orders(:hitobito_demo, :puzzletime), assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id,
                   'responsible_id' => employees(:lucien).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by department' do
    get :index, params: { department_id: departments(:devone).id }
    assert_equal orders(:puzzletime, :webauftritt), assigns(:orders)
    assert_equal({ 'department_id' => departments(:devone).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by responsible' do
    get :index, params: { responsible_id: employees(:lucien).id }
    assert_equal orders(:hitobito_demo, :puzzletime), assigns(:orders)
    assert_equal({ 'responsible_id' => employees(:lucien).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by status' do
    get :index, params: { status_id: order_statuses(:bearbeitung).id }
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by kind' do
    get :index, params: { kind_id: order_kinds(:projekt).id }
    assert_equal orders(:hitobito_demo, :webauftritt), assigns(:orders)
    assert_equal({ 'kind_id' => order_kinds(:projekt).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by status and kind' do
    get :index, params: { status_id: order_statuses(:bearbeitung).id, kind_id: order_kinds(:mandat).id }
    assert_equal [orders(:puzzletime)], assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id.to_s,
                   'kind_id' => order_kinds(:mandat).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by department, responsible, status and kind' do
    get :index, params: {
                  department_id: departments(:devtwo).id,
                  responsible_id: employees(:lucien).id,
                  status_id: order_statuses(:bearbeitung).id,
                  kind_id: order_kinds(:mandat).id
                }
    assert_equal [], assigns(:orders)
    assert_equal({ 'department_id' => departments(:devtwo).id.to_s,
                   'responsible_id' => employees(:lucien).id.to_s,
                   'status_id' => order_statuses(:bearbeitung).id.to_s,
                   'kind_id' => order_kinds(:mandat).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index uses remembered params if no params are given' do
    session[:list_params] = {
      '/orders' => {
        'status_id' => order_statuses(:bearbeitung).id.to_s,
        'kind_id' => order_kinds(:mandat).id.to_s
      }
    }
    get :index
    assert_equal [orders(:puzzletime)], assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id.to_s,
                   'kind_id' => order_kinds(:mandat).id.to_s },
                 session[:list_params]['/orders'])
  end

  test 'GET index overwrites remembered params if params are given' do
    session[:list_params] = {
      '/orders' => {
        'status_id' => order_statuses(:bearbeitung).id.to_s,
        'kind_id' => order_kinds(:mandat).id.to_s
      }
    }
    get :index, params: { status_id: order_statuses(:abgeschlossen).id, responsible_id: employees(:mark).id }
    assert_equal [orders(:allgemein)], assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:abgeschlossen).id.to_s,
                   'responsible_id' => employees(:mark).id.to_s },
                 session[:list_params]['/orders'])
  end


  test 'GET show' do
    get :show, params: { id: orders(:hitobito_demo).id }
    assert_template 'show'
  end

  test 'GET new presets some values' do
    get :new
    user = employees(:mark)
    order = assigns(:order)
    assert_nil order.department_id
    assert_equal user, order.responsible
  end

  test 'POST create sets values' do
    assert_difference('Order.count') do
      post :create,
           params: {
             client_work_item_id: clients(:swisstopo).work_item_id,
             order: {
                work_item_attributes: {
                  name: 'New Order',
                  shortname: 'NEO'
                },
                department_id: departments(:devtwo).id,
                responsible_id: employees(:pascal).id,
                kind_id: order_kinds(:projekt).id,
                status_id: order_statuses(:bearbeitung).id,
                order_team_members_attributes: {
                  '0' => { employee_id: employees(:half_year_maria).id, comment: 'rolle maria' },
                  '1' => { employee_id: employees(:next_year_pablo).id, comment: 'rolle pablo' }
                },
                order_contacts_attributes: {
                  '0' => { contact_id_or_crm: contacts(:swisstopo_1).id, comment: 'funktion 1' },
                  '1' => { contact_id_or_crm: contacts(:swisstopo_2).id, comment: 'funktion 2' }
                }
              }
           }
    end

    assert_redirected_to edit_order_path(assigns(:order))

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal 'NEO', item.shortname
    assert_equal clients(:swisstopo).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    order_contacts = order.order_contacts.map { |oc| [oc.contact_id, oc.comment] }.sort
    assert_equal [[contacts(:swisstopo_1).id, 'funktion 1'], [contacts(:swisstopo_2).id, 'funktion 2']].sort, order_contacts

    order_team_members = order.order_team_members.map { |otm| [otm.employee.id, otm.comment] }.sort
    assert_equal [[employees(:half_year_maria).id, 'rolle maria'], [employees(:next_year_pablo).id, 'rolle pablo']].sort, order_team_members
  end

  test 'POST create copies sub accounting posts and everything' do
    source = orders(:hitobito_demo)
    source.order_team_members.create!(employee: employees(:pascal), comment: 'Coder')
    source.order_team_members.create!(employee: employees(:lucien), comment: 'PL')
    source.order_contacts.create!(contact: contacts(:puzzle_rava), comment: 'BL')
    source.create_contract!(number: 'hito1234', start_date: '2005-01-01', end_date: '2020-07-30')

    post :create,
         params: {
           client_work_item_id: clients(:puzzle).work_item_id,
           copy_id: source.id,
           order: {
             work_item_attributes: {
               parent_id: source.work_item.parent.id,
               name: 'New Order',
               shortname: 'NEO'
             },
             department_id: departments(:devtwo).id,
             responsible_id: employees(:pascal).id,
             kind_id: order_kinds(:projekt).id,
             status_id: order_statuses(:bearbeitung).id,
             order_team_members_attributes: {
               '0' => { employee_id: employees(:half_year_maria).id, comment: 'rolle maria' },
               '1' => { employee_id: employees(:next_year_pablo).id, comment: 'rolle pablo' }
             },
             order_contacts_attributes: {
               '0' => { contact_id_or_crm: contacts(:puzzle_rava).id, comment: 'funktion 1' }
             }
           }
         }

    assert_equal [], assigns(:order).errors.full_messages
    assert_redirected_to edit_order_path(assigns(:order))

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    order_contacts = order.order_contacts.map { |oc| [oc.contact_id, oc.comment] }.sort
    assert_equal [[contacts(:puzzle_rava).id, 'funktion 1']], order_contacts

    order_team_members = order.order_team_members.map { |otm| [otm.employee.id, otm.comment] }.sort
    assert_equal [[employees(:half_year_maria).id, 'rolle maria'], [employees(:next_year_pablo).id, 'rolle pablo']].sort, order_team_members

    assert_equal 'hito1234', order.contract.number
    assert_not_equal source.contract_id, order.contract_id

    assert_equal source.work_item.parent_id, item.parent_id

    assert_equal 2, order.accounting_posts.count
    assert_not_equal work_items(:hitobito_demo_app), order.accounting_posts.first
    assert_equal work_items(:hitobito_demo_app).name, order.accounting_posts.first.name
  end

  test 'POST create copies same level accounting post' do
    source = orders(:webauftritt)

    post :create,
         params: {
           client_work_item_id: clients(:swisstopo).work_item_id,
           copy_id: source.id,
           order: {
             work_item_attributes: {
               parent_id: source.work_item.parent.id,
               name: 'New Order',
               shortname: 'NEO'
             },
             department_id: departments(:devtwo).id,
             responsible_id: employees(:pascal).id,
             kind_id: order_kinds(:projekt).id,
             status_id: order_statuses(:bearbeitung).id
           }
         }

    assert_equal [], assigns(:order).errors.full_messages
    assert_redirected_to edit_order_path(assigns(:order))

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    assert_equal [], order.order_contacts
    assert_equal [], order.order_team_members

    assert_not_equal source.contract_id, order.contract_id

    assert_equal source.work_item.parent_id, item.parent_id

    assert_equal 1, order.accounting_posts.count
    post = order.accounting_posts.first
    assert_not_equal work_items(:webauftritt), post.work_item
    assert_equal order.work_item, post.work_item
    assert_equal 140, post.offered_rate
  end

  test 'POST create copies same level accounting post with category' do
    source = Fabricate(:order, work_item: Fabricate(:work_item, parent: work_items(:intern), name: 'test', shortname: 'tst'))
    Fabricate(:accounting_post, work_item: source.work_item)

    post :create,
         params: {
           client_work_item_id: clients(:puzzle).work_item_id,
           copy_id: source.id,
           order: {
             work_item_attributes: {
               parent_id: source.work_item.parent.id,
               name: 'New Order',
               shortname: 'NEO'
             },
             department_id: departments(:devtwo).id,
             responsible_id: employees(:pascal).id,
             kind_id: order_kinds(:projekt).id,
             status_id: order_statuses(:bearbeitung).id
           }
         }

    assert_equal [], assigns(:order).errors.full_messages
    assert_redirected_to edit_order_path(assigns(:order))

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    assert_equal [], order.order_contacts
    assert_equal [], order.order_team_members

    assert_nil order.contract_id

    assert_equal source.work_item.parent_id, item.parent_id

    assert_equal 1, order.accounting_posts.count
    post = order.accounting_posts.first
    assert_not_equal source.work_item, post.work_item
    assert_equal order.work_item, post.work_item
  end

  test 'PATCH update sets values' do
    order = orders(:puzzletime)
    patch :update, params: {
                     id: order.id,
                     order: {
                       work_item_attributes: {
                         name: 'New Order',
                         shortname: 'NEO'
                       },
                       crm_key: 'puzzletime-crm-key',
                       department_id: departments(:devtwo).id,
                       responsible_id: employees(:pascal).id,
                       kind_id: order_kinds(:projekt).id,
                       status_id: order_statuses(:bearbeitung).id,
                       order_team_members_attributes: {
                         '0' => { employee_id: employees(:half_year_maria).id, comment: 'rolle maria' },
                         '1' => { employee_id: employees(:next_year_pablo).id, comment: 'rolle pablo' }
                       },
                       order_contacts_attributes: {
                         '0' => { contact_id_or_crm: contacts(:puzzle_rava), comment: 'funktion 1' },
                         '1' => { contact_id_or_crm: contacts(:puzzle_hauswart), comment: 'funktion 2' }
                       }
                     }
                   }

    assert_redirected_to edit_order_path(order)

    order.reload
    item = order.work_item
    assert_equal 'New Order', item.name
    assert_equal 'NEO', item.shortname
    assert_equal clients(:puzzle).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id
    assert_equal 'puzzletime-crm-key', order.crm_key

    order_contacts = order.order_contacts.map { |oc| [oc.contact_id, oc.comment] }.sort
    assert_equal [[contacts(:puzzle_rava).id, 'funktion 1'], [contacts(:puzzle_hauswart).id, 'funktion 2']].sort, order_contacts

    order_team_members = order.order_team_members.map { |otm| [otm.employee.id, otm.comment] }.sort
    assert_equal [[employees(:half_year_maria).id, 'rolle maria'], [employees(:next_year_pablo).id, 'rolle pablo']].sort, order_team_members
  end

  test 'DELETE destroys order and work item' do
    order = orders(:puzzletime)
    order.worktimes.destroy_all
    assert_difference 'WorkItem.count', -1 do
      assert_difference 'Order.count', -1 do
        assert_difference 'AccountingPost.count', -1 do
          delete :destroy, params: { id: order.id }
        end
      end
    end
    assert_redirected_to orders_path(returning: true)
  end

  test 'DELETE destroys order and all accounting posts' do
    order = orders(:hitobito_demo)
    order.worktimes.destroy_all
    assert_difference 'WorkItem.count', -3 do
      assert_difference 'Order.count', -1 do
        assert_difference 'AccountingPost.count', -2 do
          delete :destroy, params: { id: order.id }
        end
      end
    end
    assert_redirected_to orders_path(returning: true)
  end

  test 'ajax GET #employees includes only those with worktimes in given period' do
    order = orders(:webauftritt)
    lucien = employees(:lucien)

    get :employees,
        xhr: true,
        params: { id: order.id, period_from: '11.12.2006', period_to: '01.03.2007' }

    empls = JSON.parse(response.body)
    assert_equal 1, empls.size
    empl = empls.first
    assert_equal lucien.id, empl['id']
    assert_equal lucien.lastname, empl['lastname']
    assert_equal lucien.firstname, empl['firstname']
  end

  test 'ajax GET #employees includes all with worktimes if no period specified' do
    order = orders(:webauftritt)
    lucien = employees(:lucien)
    mark = employees(:mark)

    get :employees, xhr: true, params: { id: order.id }

    empls = JSON.parse(response.body)
    assert_equal 2, empls.size
    assert empls.any? {|e| e['id'] == lucien.id }
    assert empls.any? {|e| e['id'] == mark.id }
  end

  test 'ajax GET #employees empty if no worktimes for given period' do
    order = orders(:webauftritt)

    get :employees,
        xhr: true,
        params: { id: order.id, period_from: '11.12.2007', period_to: '01.03.2008' }

    empls = JSON.parse(response.body)
    assert_equal 0, empls.size
  end

  test 'GET #edit redirects to #show if no write access on given order' do
    login_as(:lucien)

    order = orders(:webauftritt)

    get :edit, params: { id: order.id }

    assert_redirected_to order_path(order)
  end

  test 'GET #edit shows edit form if write access' do
    order = orders(:webauftritt)

    get :edit, params: { id: order.id }

    assert_template :edit
  end
end
