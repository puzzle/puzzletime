# encoding: utf-8
require 'test_helper'

class AccountingPostsControllerTest < ActionController::TestCase

  setup :login

  test 'GET edit' do
    get :edit, id: accounting_posts(:puzzletime).id
    assert_template 'edit'
  end

  test 'GET new requires param order_id' do
    err = assert_raises(ActionController::ParameterMissing){ get :new }
    assert_match /\border_id\b/, err.message
  end

  test 'GET new presets some values' do
    get :new, order_id: accounting_posts(:puzzletime).order.id
    assert_equal accounting_posts(:puzzletime).order, assigns(:order)
  end

  test 'GET new form includes book_on_order fields when no accounting_post exists for order' do
    order = orders(:hitobito_demo)
    order.accounting_posts.delete_all
    get :new, order_id: order.id
    assert_match(/"book_on_order"/, @response.body)
  end

  test 'GET new form not includes book_on_order fields when accounting_post exists for order' do
    order = orders(:hitobito_demo)
    get :new, order_id: order.id
    assert_no_match(/"book_on_order"/, @response.body)
  end

  test 'GET edit form includes book_on_order fields when no accounting_post exists for order' do
    accounting_posts(:hitobito_demo_site).delete
    get :edit, id: accounting_posts(:hitobito_demo_app)
    assert_match(/"book_on_order"/, @response.body)
  end

  test 'GET edit form not includes book_on_order fields when accounting_post exists for order' do
    get :edit, id: accounting_posts(:hitobito_demo_app)
    assert_no_match(/"book_on_order"/, @response.body)
  end

  test 'DESTROY does not remove reocrd when worktimes exist on workitem' do
    assert_no_difference "AccountingPost.count" do
      delete :destroy, id: accounting_posts(:puzzletime).id
    end
    assert_redirected_to controller: :orders, action: :cockpit, id: orders(:puzzletime)
    assert_match(/kann nicht gelöscht werden/, flash[:alert])
  end

  test 'DESTROY removes record when no worktimes on workitem' do
    accounting_posts(:puzzletime).work_item.worktimes.clear
    assert_difference "AccountingPost.count", -1 do
      delete :destroy, id: accounting_posts(:puzzletime).id
    end
    assert_redirected_to controller: :orders, action: :cockpit, id: orders(:puzzletime)
    assert flash[:alert].blank?
  end

  test 'CREATE with book_on_order true when accounting_post exists' do
    assert_no_difference "AccountingPost.count" do
      post :create, book_on_order: 'true', order_id: orders(:hitobito_demo),
           accounting_post: { reference: 'asdf', portfolio_item_id: portfolio_items(:web).id }
      assert_response :success
      assert_template :new
      assert_match(/es existieren bereits/, flash[:alert])
    end
  end

  test 'CREATE with book_on_order true when no accounting_post exists on order sets work_item to order.work_item' do
    orders(:hitobito_demo).accounting_posts.delete_all
    assert_difference "AccountingPost.count", +1 do
      assert_no_difference "WorkItem.count" do
        post :create, book_on_order: 'true', order_id: orders(:hitobito_demo),
             accounting_post: { reference: 'asdf', portfolio_item_id: portfolio_items(:web).id }
      end
    end
    assert_redirected_to controller: :orders, action: :cockpit, id: orders(:hitobito_demo)
    assert_match(/erfolgreich erstellt/, flash[:notice])
    assert AccountingPost.last.work_item_id = orders(:hitobito_demo).work_item_id
  end

  test 'CREATE with new work_item with order.work_item as parent' do
    assert_difference "AccountingPost.count", +1 do
      assert_difference "WorkItem.count", +1 do
        post :create, order_id: orders(:hitobito_demo),
             accounting_post: { work_item_attributes: { name: 'TEST', shortname: 'TST' }, portfolio_item_id: portfolio_items(:web).id}
      end
    end
    assert_redirected_to controller: :orders, action: :cockpit, id: orders(:hitobito_demo)
    assert_match(/erfolgreich erstellt/, flash[:notice])
    new_work_item = AccountingPost.last.work_item
    assert new_work_item.parent_id = orders(:hitobito_demo).work_item_id
    assert_equal new_work_item.attributes.slice('name', 'shortname'), {'name' => 'TEST', 'shortname' => 'TST'}
  end

  test 'CREATE sets the attributes' do
    attributes = {
        order_id: orders(:hitobito_demo),
        discount: 'percent',
        accounting_post: {
              work_item_attributes: { name: 'TEST', shortname: 'TST' },
              closed: 'true',
              offered_hours: 80,
              offered_rate: 42,
              discount_percent: 11,
              portfolio_item_id: portfolio_items(:mobile).id,
              reference: 'dummy-reference',
              billable: true,
              description_required: true,
              ticket_required: true
        }
    }

    assert_difference "AccountingPost.count", +1 do
      post :create, attributes
    end
    accounting_post = assigns(:accounting_post)
    attributes[:accounting_post].except(:work_item_attributes).each do |k,v|
      assert_equal v.to_s, accounting_post.send(k).to_s, "accounting_post.#{k} should eq #{v}"
    end
    attributes[:accounting_post][:work_item_attributes].each do |k,v|
      assert_equal v.to_s, accounting_post.work_item.send(k).to_s, "accounting_post.work_item.#{k} should eq #{v}"
    end

  end

  test 'PATCH update with book_on_order true when other accounting_post exists' do
    assert_no_difference "AccountingPost.count" do
      patch :update, book_on_order: 'true', id: accounting_posts(:hitobito_demo_app), accounting_post: { reference: 'asdf' }
      assert_response :success
      assert_template :edit
      assert_match(/es existieren bereits/, flash[:alert])
    end
  end

  test 'PATCH update with book_on_order changes work_item to order.work_item and moves worktimes' do
    accounting_posts(:hitobito_demo_site).delete
    worktime = Worktime.create!(work_item_id: accounting_posts(:hitobito_demo_app).work_item_id, employee_id: Employee.first.id,
                                work_date: Date.today, hours: 4.2, report_type: 'absolute_day')
    assert_no_difference "AccountingPost.count" do
      assert_difference "WorkItem.count", -1 do
        assert_no_difference "Worktime.count" do
          patch :update, book_on_order: 'true', id: accounting_posts(:hitobito_demo_app), accounting_post: { reference: 'asdf' }
          assert_redirected_to controller: :orders, action: :cockpit, id: orders(:hitobito_demo)
          assert_match(/erfolgreich aktualisiert/, flash[:notice])
        end
      end
    end
    assert_equal orders(:hitobito_demo).work_item_id, accounting_posts(:hitobito_demo_app).reload.work_item_id
    assert_equal orders(:hitobito_demo).work_item_id, worktime.reload.work_item_id
  end

  test 'PATCH update with new work_item sets parent_id to order.work_item_id and moves worktimes' do
    assert_no_difference "AccountingPost.count" do
      assert_difference "WorkItem.count", +1 do
        assert_no_difference "Worktime.count" do
          patch :update, book_on_order: 'false', id: accounting_posts(:puzzletime),
                accounting_post: { work_item_attributes: { name: 'Refactoring', shortname: 'RFT' } }
          assert_redirected_to controller: :orders, action: :cockpit, id: orders(:puzzletime)
          assert_match(/erfolgreich aktualisiert/, flash[:notice])
        end
      end
    end
    assert_equal orders(:puzzletime).work_item_id, accounting_posts(:puzzletime).reload.work_item.parent_id
    assert_equal accounting_posts(:puzzletime).work_item_id, worktimes(:wt_pz_puzzletime).reload.work_item_id
  end

  test 'PATCH update with discount fixed removes discount percent' do
    post = accounting_posts(:hitobito_demo_app)
    post.update!(discount_percent: 5)
    patch :update,
          id: post,
          book_on_order: false,
          discount: 'fixed',
          accounting_post:
            { reference: 123,
              discount_fixed: 100 }
    assert_redirected_to cockpit_order_path(orders(:hitobito_demo))
    assert_equal 100, post.reload.discount_fixed
    assert_equal nil, post.discount_percent
  end

  test 'PATCH update with discount percent removes discount fixed' do
    post = accounting_posts(:hitobito_demo_app)
    post.update!(discount_fixed: 100)
    patch :update,
          id: post,
          book_on_order: false,
          discount: 'percent',
          accounting_post:
            { reference: 123,
              discount_percent: 5,
              discount_fixed: 100 }
    assert_redirected_to cockpit_order_path(orders(:hitobito_demo))
    assert_equal nil, post.reload.discount_fixed
    assert_equal 5, post.discount_percent
  end

  test 'PATCH update with discount none removes discount fixed' do
    post = accounting_posts(:hitobito_demo_app)
    post.update!(discount_fixed: 100)
    patch :update,
          id: post,
          book_on_order: false,
          discount: 'none',
          accounting_post:
            { reference: 123 }
    assert_redirected_to cockpit_order_path(orders(:hitobito_demo))
    assert_equal nil, post.reload.discount_fixed
    assert_equal nil, post.discount_percent
  end
end