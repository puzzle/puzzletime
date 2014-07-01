# encoding: UTF-8

require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found,
               :test_new,
               :test_create,
               :test_create_json,
               :test_destroy,
               :test_destroy_json

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

  private

  # Test object used in several tests.
  def test_entry
    projects(:webauftritt)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { description: 'bla bla',
      report_type: HoursWeekType::INSTANCE,
      offered_hours: 500,
      billable: true,
      freeze_until: Date.today - 1.year,
      description_required: false,
      ticket_required: false }
  end
end
