# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class AccountingPostsControllerTest < ActionController::TestCase
  setup :login

  test 'GET index' do
    get :index, params: { order_id: orders(:hitobito_demo).id }

    assert_template 'index'
  end

  test 'GET edit' do
    get :edit, params: { order_id: orders(:puzzletime).id, id: accounting_posts(:puzzletime).id }

    assert_template 'edit'
  end

  test 'GET new presets some values' do
    get :new, params: { order_id: accounting_posts(:puzzletime).order.id }

    assert_equal accounting_posts(:puzzletime).order, assigns(:order)
  end

  test 'GET new form includes book_on_order fields when no accounting_post exists for order' do
    order = orders(:hitobito_demo)
    order.accounting_posts.delete_all
    get :new, params: { order_id: order.id }

    assert_match(/"book_on_order"/, @response.body)
  end

  test 'GET new form not includes book_on_order fields when accounting_post exists for order' do
    order = orders(:hitobito_demo)
    get :new, params: { order_id: order.id }

    assert_no_match(/"book_on_order"/, @response.body)
  end

  test 'GET edit form includes book_on_order fields when no accounting_post exists for order' do
    accounting_posts(:hitobito_demo_site).delete
    get :edit, params: { order_id: orders(:hitobito_demo).id, id: accounting_posts(:hitobito_demo_app) }

    assert_match(/"book_on_order"/, @response.body)
  end

  test 'GET edit form not includes book_on_order fields when accounting_post exists for order' do
    get :edit, params: { order_id: orders(:hitobito_demo).id, id: accounting_posts(:hitobito_demo_app) }

    assert_no_match(/"book_on_order"/, @response.body)
  end

  test 'CREATE with book_on_order true when accounting_post exists' do
    assert_no_difference 'AccountingPost.count' do
      post :create,
           params: {
             order_id: orders(:hitobito_demo).id,
             book_on_order: 'true',
             accounting_post: {
               portfolio_item_id: portfolio_items(:web).id,
               service_id: services(:software).id,
               offered_rate: 120
             }
           }

      assert_response :unprocessable_entity
      assert_template :new
      assert_match(/es existieren bereits/, assigns(:accounting_post).errors.full_messages.join)
    end
  end

  test 'CREATE with book_on_order true when no accounting_post exists on order sets work_item to order.work_item' do
    order = orders(:hitobito_demo)
    order.accounting_posts.destroy_all
    assert_difference 'AccountingPost.count', 1 do
      assert_no_difference 'WorkItem.count' do
        post :create,
             params: {
               book_on_order: 'true',
               order_id: order.id,
               accounting_post: {
                 reference: 'asdf',
                 portfolio_item_id: portfolio_items(:web).id,
                 service_id: services(:software).id,
                 closed: true,
                 offered_rate: 155
               }
             }
      end
    end
    assert_redirected_to order_accounting_posts_path(order)
    assert_match(/erfolgreich erstellt/, flash[:notice])
    assert AccountingPost.last.work_item_id = order.work_item_id
    assert order.work_item.reload.closed
  end

  test 'CREATE with new work_item with order.work_item as parent' do
    assert_difference 'AccountingPost.count', 1 do
      assert_difference 'WorkItem.count', 1 do
        post :create,
             params: {
               order_id: orders(:hitobito_demo).id,
               accounting_post: {
                 work_item_attributes: { name: 'TEST', shortname: 'TST' },
                 portfolio_item_id: portfolio_items(:web).id,
                 service_id: services(:software).id,
                 offered_rate: 120,
                 closed: true
               }
             }
      end
    end
    assert_redirected_to order_accounting_posts_path(orders(:hitobito_demo))
    assert_match(/erfolgreich erstellt/, flash[:notice])
    new_work_item = AccountingPost.last.work_item

    assert new_work_item.parent_id = orders(:hitobito_demo).work_item_id
    assert_equal({ 'name' => 'TEST', 'shortname' => 'TST', 'closed' => true },
                 new_work_item.attributes.slice('name', 'shortname', 'closed'))
  end

  test 'CREATE second accounting post moves existing post from order to own work item' do
    order = orders(:puzzletime)
    assert_difference 'AccountingPost.count', 1 do
      assert_difference 'WorkItem.count', 2 do
        post :create,
             params: {
               order_id: order.id,
               accounting_post: {
                 work_item_attributes: { name: 'TEST', shortname: 'TST' },
                 portfolio_item_id: portfolio_items(:web).id,
                 service_id: services(:software).id,
                 offered_rate: 150
               }
             }
      end
    end
    assert_redirected_to order_accounting_posts_path(order)
    assert_match(/erfolgreich erstellt/, flash[:notice])
    order.reload

    assert_nil order.work_item.accounting_post
    assert_equal 2, order.accounting_posts.size
    assert_equal accounting_posts(:puzzletime), order.accounting_posts.list.first
    assert_equal 'TEST', order.accounting_posts.list.last.name
    assert_equal work_items(:puzzletime), accounting_posts(:puzzletime).work_item.parent
    assert_equal work_items(:puzzletime).worktimes.order(:id),
                 accounting_posts(:puzzletime).work_item.worktimes.order(:id)
  end

  test 'CREATE second accounting post does not touch existing post on own work item' do
    order = orders(:hitobito_demo)
    assert_difference 'AccountingPost.count', 1 do
      assert_difference 'WorkItem.count', 1 do
        post :create,
             params: {
               order_id: order.id,
               accounting_post: {
                 work_item_attributes: { name: 'TEST', shortname: 'TST' },
                 portfolio_item_id: portfolio_items(:web).id,
                 service_id: services(:software).id,
                 offered_rate: 150
               }
             }
      end
    end
    assert_redirected_to order_accounting_posts_path(order)
    assert_match(/erfolgreich erstellt/, flash[:notice])
    order.reload

    assert_nil order.work_item.accounting_post
    assert_equal 3, order.accounting_posts.size
    assert_equal accounting_posts(:hitobito_demo_app), order.accounting_posts.list.first
    assert_equal 'TEST', order.accounting_posts.list.last.name
    assert_equal work_items(:hitobito_demo), accounting_posts(:hitobito_demo_app).work_item.parent
  end

  test 'CREATE sets the attributes' do
    attributes = {
      order_id: orders(:hitobito_demo).id,
      accounting_post: {
        work_item_attributes: { name: 'TEST', shortname: 'TST' },
        closed: 'true',
        offered_hours: 80.0,
        offered_rate: 42.0,
        portfolio_item_id: portfolio_items(:mobile).id,
        service_id: services(:software).id,
        billable: true,
        description_required: true,
        ticket_required: true
      }
    }

    assert_difference 'AccountingPost.count', +1 do
      post :create, params: attributes
    end
    accounting_post = assigns(:accounting_post)

    attributes[:accounting_post].except(:work_item_attributes).each do |k, v|
      assert_equal v.to_s, accounting_post.send(k).to_s, "accounting_post.#{k} should eq #{v}"
    end
    attributes[:accounting_post][:work_item_attributes].each do |k, v|
      assert_equal v.to_s, accounting_post.work_item.send(k).to_s, "accounting_post.work_item.#{k} should eq #{v}"
    end
  end

  test 'PATCH update changes all attributes' do
    accounting_post = accounting_posts(:hitobito_demo_app)
    params = {
      id: accounting_post.id,
      order_id: orders(:hitobito_demo).id,
      accounting_post: {
        work_item_attributes: { name: 'TEST', shortname: 'TST' },
        closed: 'true',
        offered_hours: 80.0,
        offered_rate: 42.0,
        offered_total: 10_000.0,
        portfolio_item_id: portfolio_items(:mobile).id,
        service_id: services(:software).id,
        billable: true,
        description_required: true,
        ticket_required: true,
        from_to_times_required: true
      }
    }

    patch(:update, params:)
    accounting_post.reload

    params[:accounting_post].except(:work_item_attributes).each do |k, v|
      assert_equal v.to_s, accounting_post.send(k).to_s, "accounting_post.#{k} should eq #{v}"
    end
  end

  test 'PATCH update with book_on_order true when other accounting_post exists' do
    assert_no_difference 'AccountingPost.count' do
      patch :update,
            params: {
              order_id: orders(:hitobito_demo).id,
              id: accounting_posts(:hitobito_demo_app),
              book_on_order: 'true',
              accounting_post: { description: 'asdf' }
            }

      assert_response :unprocessable_entity
      assert_template :edit
      assert_match(/es existieren bereits/, assigns(:accounting_post).errors.full_messages.join)
    end
  end

  test 'PATCH update with book_on_order changes work_item to order.work_item and moves worktimes' do
    accounting_posts(:hitobito_demo_site).delete
    worktime = Worktime.create!(work_item_id: accounting_posts(:hitobito_demo_app).work_item_id, employee_id: Employee.first.id,
                                work_date: Time.zone.today, hours: 4.2, report_type: 'absolute_day')
    assert_no_difference 'AccountingPost.count' do
      assert_difference 'WorkItem.count', -1 do
        assert_no_difference 'Worktime.count' do
          patch :update,
                params: {
                  order_id: orders(:hitobito_demo).id,
                  id: accounting_posts(:hitobito_demo_app),
                  book_on_order: 'true',
                  accounting_post: { reference: 'asdf' }
                }

          assert_redirected_to order_accounting_posts_path(orders(:hitobito_demo))
          assert_match(/erfolgreich aktualisiert/, flash[:notice])
        end
      end
    end
    assert_equal orders(:hitobito_demo).work_item_id, accounting_posts(:hitobito_demo_app).reload.work_item_id
    assert_equal orders(:hitobito_demo).work_item_id, worktime.reload.work_item_id
  end

  test 'PATCH update with new work_item sets parent_id to order.work_item_id and moves worktimes' do
    assert_no_difference 'AccountingPost.count' do
      assert_difference 'WorkItem.count', +1 do
        assert_no_difference 'Worktime.count' do
          patch :update,
                params: {
                  order_id: orders(:puzzletime).id,
                  id: accounting_posts(:puzzletime).id,
                  book_on_order: 'false',
                  accounting_post: { work_item_attributes: { name: 'Refactoring', shortname: 'RFT' } }
                }

          assert_redirected_to order_accounting_posts_path(orders(:puzzletime))
          assert_match(/erfolgreich aktualisiert/, flash[:notice])
        end
      end
    end
    assert_equal orders(:puzzletime).work_item_id, accounting_posts(:puzzletime).reload.work_item.parent_id
    assert_equal accounting_posts(:puzzletime).work_item_id, worktimes(:wt_pz_puzzletime).reload.work_item_id
  end

  test 'DESTROY does not remove reocrd when worktimes exist on workitem' do
    assert_no_difference 'AccountingPost.count' do
      delete :destroy,
             params: {
               id: accounting_posts(:puzzletime).id,
               order_id: orders(:puzzletime).id
             }
    end
    assert_redirected_to order_accounting_posts_path(orders(:puzzletime))
    assert_match(/kann nicht gelöscht werden/, flash[:alert])
  end

  test 'DESTROY removes record when no worktimes on workitem' do
    accounting_posts(:puzzletime).work_item.worktimes.clear
    assert_no_difference 'WorkItem.count' do
      assert_difference 'AccountingPost.count', -1 do
        delete :destroy,
               params: {
                 order_id: orders(:puzzletime).id,
                 id: accounting_posts(:puzzletime).id
               }
      end
    end
    assert_redirected_to order_accounting_posts_path(orders(:puzzletime))
    assert_predicate flash[:alert], :blank?
  end

  test 'DESTROY removes record and work item when no worktimes on workitem' do
    accounting_posts(:hitobito_demo_app).work_item.worktimes.clear
    assert_difference 'WorkItem.count', -1 do
      assert_difference 'AccountingPost.count', -1 do
        delete :destroy,
               params: {
                 order_id: orders(:hitobito_demo).id,
                 id: accounting_posts(:hitobito_demo_app).id
               }
      end
    end
    assert_redirected_to order_accounting_posts_path(orders(:hitobito_demo))
    assert_predicate flash[:alert], :blank?
  end

  test 'GET export csv simple' do
    get :export_csv, params: { order_id: orders(:puzzletime).id }

    # assert_csv_http_headers('puzzletime.csv')
    assert_match expected_csv_header, csv_header

    assert_equal 1, csv_data_lines.size
    assert_match 'PITC-PT,PuzzleTime,100.0,18.0,10.0,92.0,0', csv_data_lines.first
  end

  test 'GET export csv with timespan' do
    get :export_csv, params: { order_id: orders(:puzzletime).id, start_date: '2006-12-04', end_date: '2006-12-10' }

    assert_match expected_csv_header, csv_header

    assert_equal 1, csv_data_lines.size
    assert_match 'PITC-PT,PuzzleTime,100.0,6.0,0,92.0,0', csv_data_lines.first
  end

  test 'GET export csv with timespan including non-billable' do
    get :export_csv, params: { order_id: orders(:puzzletime).id, start_date: '2006-12-04' }

    assert_match expected_csv_header, csv_header

    assert_equal 1, csv_data_lines.size
    assert_match 'PITC-PT,PuzzleTime,100.0,16.0,10.0,92.0,0', csv_data_lines.first
  end

  private

  def expected_csv_header
    'Position,Name der Position,Budget,Geleistete Stunden,Nicht verrechenbar,Offenes Budget,Geplantes Budget'
  end

  def csv_header
    response.body.lines.first
  end

  def csv_data_lines
    _, *lines = response.body.lines.to_a
    lines
  end
end
