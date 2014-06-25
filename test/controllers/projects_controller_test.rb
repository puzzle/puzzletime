# encoding: UTF-8

require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_index_in_department
    get :index, department_id: departments(:devone).id
    assert_equal assigns(:projects).size, 2
  end

  def test_index_in_client
    get :index, client_id: clients(:swisstopo).id
    assert_equal [projects(:webauftritt)], assigns(:projects)
  end

  def test_index_in_project
    get :index, project_id: projects(:hitobito).id
    assert_equal [projects(:hitobito_demo)], assigns(:projects)
  end

  def test_subprojects_in_department
    get :index, department_id: departments(:devtwo).id, project_id: projects(:hitobito).id
    assert_equal [projects(:hitobito_demo)], assigns(:projects)
  end

  def test_subprojects_in_client
    get :index, client_id: clients(:puzzle).id, project_id: projects(:hitobito).id
    assert_equal [projects(:hitobito_demo)], assigns(:projects)
  end

  def test_subprojects_in_project
    get :index, project_id: projects(:hitobito_demo).id
    assert_equal [projects(:hitobito_demo_app), projects(:hitobito_demo_site)], assigns(:projects)
  end

  def test_index_search
    # not supported here
  end

  def test_destroy
    @test_entry = Fabricate(:project)
    super
  end

  def test_destroy_json
    @test_entry = Fabricate(:project)
    super
  end

  def test_destroy_protected
    assert_no_difference("#{model_class.name}.count") do
      delete :destroy, test_params(id: test_entry.id)
    end
    assert_redirected_to_index
  end

  private

  # Test object used in several tests.
  def test_entry
    @test_entry ||= projects(:webauftritt)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'My Project',
      shortname: 'mpr',
      client_id: test_entry.client_id,
      description: 'bla bla',
      report_type: HoursWeekType::INSTANCE,
      offered_hours: 500,
      offered_rate: 200,
      discount: 5,
      reference: 'abc',
      closed: false,
      portfolio_item_id: 1,
      billable: true,
      freeze_until: Date.today - 1.year,
      description_required: false,
      ticket_required: false }
  end
end
