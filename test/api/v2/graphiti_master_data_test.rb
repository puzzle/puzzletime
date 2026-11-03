# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # Plain master data resources of the Graphiti /api/v2: one table-driven CRUD test over all of them plus
    # the rules that differ (protected deletes, unique names, enums, decimals, relationships, per-role access).
    class GraphitiMasterDataTest < ActionDispatch::IntegrationTest
      include GraphitiApiHelper

      # path => [create attributes, attribute to change, new value]
      WRITABLE = {
        'absences' => [{ name: 'Militär', payed: true, vacation: false }, :name, 'Militärdienst'],
        'billing_addresses' => [{ client_id: 1, street: 'Weg 1', zip_code: '3000', town: 'Bern', country: 'CH' },
                                :town, 'Thun'],
        'contacts' => [{ client_id: 1, lastname: 'Muster', firstname: 'Max', email: 'max@example.com' },
                       :function, 'CTO'],
        'employment_role_categories' => [{ name: 'Neu' }, :name, 'Neuer'],
        'employment_role_levels' => [{ name: 'Lead' }, :name, 'Principal'],
        'employment_roles' => [{ name: 'Tester', billable: true, level: false }, :billable, false],
        'holidays' => [{ holiday_date: '2014-12-25', musthours_day: 0 }, :musthours_day, 4.2],
        'order_kinds' => [{ name: 'Wartung' }, :name, 'Support'],
        'order_statuses' => [{ name: 'Neu', style: 'warning', closed: false, position: 99, default: false },
                             :position, 98],
        'portfolio_items' => [{ name: 'Cloud', active: true }, :active, false],
        'sectors' => [{ name: 'Industrie', active: true }, :active, false],
        'services' => [{ name: 'Audit', active: true }, :name, 'Review'],
        'target_scopes' => [{ name: 'Termintreue', icon: 'clock', position: 9, rating_green_description: 'ok' },
                            :rating_red_description, 'spät'],
        'user_notifications' => [{ date_from: '2026-01-01', date_to: '2026-01-31', message: 'Hallo' },
                                 :date_to, '2026-02-28'],
        'working_conditions' => [{ valid_from: '2030-01-01', vacation_days_per_year: '27.5',
                                   must_hours_per_day: '8.25' }, :must_hours_per_day, '8.4'],
        'workplaces' => [{ name: 'Basel' }, :name, 'Luzern'],
        'departments' => [{ name: 'Neu', shortname: 'NEU' }, :shortname, 'NE2']
      }.freeze

      # ---- generic CRUD of every writable resource ----

      WRITABLE.each do |path, (attributes, change, value)|
        test "management creates, changes and deletes #{path}" do
          login_as(:mark)
          type = path

          post "/api/v2/#{path}", params: payload(type, attributes), headers: JSONAPI

          assert_response :created, response.body
          id = json_body.dig('data', 'id')
          model = path.classify.constantize.find(id)
          attributes.each { |attr, given| assert_equal given.to_s, model[attr].to_s, attr } unless path == 'holidays'

          patch "/api/v2/#{path}/#{id}", params: payload(type, { change => value }, id), headers: JSONAPI

          assert_response :ok, response.body
          assert_equal value.to_s, json_body.dig('data', 'attributes', change.to_s).to_s
          assert_equal value.to_s, model.reload[change].to_s

          get "/api/v2/#{path}/#{id}", headers: JSONAPI

          assert_response :ok
          assert_equal id, json_body.dig('data', 'id')
          assert_equal path, json_body.dig('data', 'type')

          delete "/api/v2/#{path}/#{id}", headers: JSONAPI

          assert_response :ok
          assert_not model.class.exists?(id)
        end

        test "regular employee and api client can not write #{path}" do
          model = path.classify.constantize
          [{}, basic_auth].each do |auth|
            login_as(:pascal) if auth.empty?
            assert_no_difference("#{model}.count") do
              post "/api/v2/#{path}", params: payload(path, attributes), headers: JSONAPI.merge(auth)
            end
            assert_response :forbidden, path
          end
          row = model.first
          login_as(:pascal)
          patch "/api/v2/#{path}/#{row.id}", params: payload(path, { change => value }, row.id), headers: JSONAPI

          assert_includes [403, 404], response.status, path
          login_as(:pascal)
          assert_no_difference("#{model}.count") { delete "/api/v2/#{path}/#{row.id}", headers: JSONAPI }
          assert_includes [403, 404], response.status, path
        end
      end

      test 'nobody but management reads the master data, employees are readable by everybody' do
        %w[departments workplaces order_statuses holidays working_conditions].each do |path|
          login_as(:pascal)

          assert_equal 403, status_of("/api/v2/#{path}"), path
          assert_equal 403, get("/api/v2/#{path}", headers: JSONAPI.merge(basic_auth)), path
        end
        login_as(:mark)

        assert_equal 200, status_of('/api/v2/holidays')
        assert_equal Holiday.count, json_body['data'].size
        assert_equal 200, get('/api/v2/employees', headers: JSONAPI.merge(basic_auth))
        assert_equal Employee.count, json_body['data'].size
      end

      test 'order responsibles manage clients addresses and contacts, nothing else' do
        login_as(:lucien)
        post '/api/v2/contacts', params: payload('contacts', client_id: 1, lastname: 'Neu', firstname: 'Neo'), headers: JSONAPI

        assert_response :created
        login_as(:lucien)
        post '/api/v2/billing_addresses', params: payload('billing_addresses', client_id: 1, street: 'Weg', zip_code: '3000', town: 'Bern'),
                                          headers: JSONAPI

        assert_response :created
        assert_equal 403, status_of('/api/v2/sectors')
        login_as(:lucien)
        post '/api/v2/sectors', params: payload('sectors', name: 'x', active: true), headers: JSONAPI

        assert_response :forbidden
      end

      # ---- validations, unique names, protected deletes ----

      test 'validation errors point at the attribute' do
        login_as(:mark)

        post '/api/v2/holidays', params: payload('holidays', holiday_date: '2014-06-09', musthours_day: 0),
                                 headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal '/data/attributes/holiday_date', json_body.dig('errors', 0, 'source', 'pointer')

        login_as(:mark)
        post '/api/v2/order_statuses', params: payload('order_statuses', name: 'Offeriert', style: 'info',
                                                                         position: 5),
                                       headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal %w[/data/attributes/name /data/attributes/position],
                     json_body['errors'].map { |e| e.dig('source', 'pointer') }.sort

        login_as(:mark)
        post '/api/v2/employment_roles', params: payload('employment_roles', name: 'System Engineer',
                                                                             billable: true, level: false),
                                         headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal '/data/attributes/name', json_body.dig('errors', 0, 'source', 'pointer')
      end

      test 'an enum value outside the allowed ones is rejected by the model' do
        login_as(:mark)

        assert_no_difference('OrderStatus.count') do
          post '/api/v2/order_statuses', params: payload('order_statuses', name: 'Neu', style: 'purple', position: 9),
                                         headers: JSONAPI
        end
        assert_response :unprocessable_content
        assert_equal '/data/attributes/style', json_body.dig('errors', 0, 'source', 'pointer')
      end

      test 'decimals and floats are written and read as the model has them' do
        login_as(:mark)
        condition = working_conditions(:default)

        get "/api/v2/working_conditions/#{condition.id}", headers: JSONAPI

        assert_equal %w[8.0 25.0], json_body.dig('data', 'attributes').values_at('must_hours_per_day',
                                                                                 'vacation_days_per_year')
        get "/api/v2/holidays/#{holidays(:zibelemaerit).id}", headers: JSONAPI

        assert_in_delta 6.0, json_body.dig('data', 'attributes', 'musthours_day')
      end

      {
        'order_kinds' => [:mandat, 'Aufträge'],
        'absences' => [:vacation, 'Arbeitszeiten'],
        'portfolio_items' => [:web, 'Budgetpositionen'],
        'order_statuses' => [:bearbeitung, 'Aufträge'],
        'billing_addresses' => [:swisstopo, 'Rechnungen']
      }.each do |path, (fixture, reason)|
        test "#{path} in use can not be deleted" do
          login_as(:mark)
          row = send(path, fixture)

          assert_no_difference("#{row.class}.count") { delete "/api/v2/#{path}/#{row.id}", headers: JSONAPI }

          assert_response :unprocessable_content
          assert_includes json_body.dig('errors', 0, 'detail'), reason
        end
      end

      test 'referenced employment roles and categories answer 409' do
        used = { 'employment_roles' => employment_roles(:software_developer),
                 'employment_role_levels' => employment_role_levels(:junior),
                 'employment_role_categories' => EmploymentRoleCategory.joins(:employment_roles).first }
        used.each do |path, row|
          login_as(:mark)

          assert_no_difference("#{row.class}.count") { delete "/api/v2/#{path}/#{row.id}", headers: JSONAPI }
          assert_response :conflict, path
        end
      end

      test 'deleting a sector keeps its clients' do
        login_as(:mark)
        sector = sectors(:verwaltung)
        client = Client.first.tap { |row| row.update_column(:sector_id, sector.id) }

        delete "/api/v2/sectors/#{sector.id}", headers: JSONAPI

        assert_response :ok
        assert_nil client.reload.sector_id
      end

      # ---- filter, sort, paginate ----

      test 'holidays filter by date range, sort and paginate' do
        login_as(:mark)

        get '/api/v2/holidays', params: { filter: { holiday_date: { gte: '2014-07-01' } } }, headers: JSONAPI

        assert_equal [holidays(:zibelemaerit).id.to_s], json_body['data'].pluck('id')

        get '/api/v2/holidays', params: { sort: 'holiday_date', page: { size: 1, number: 2 } }, headers: JSONAPI

        assert_equal [holidays(:zibelemaerit).id.to_s], json_body['data'].pluck('id')
        assert_equal 2, json_body.dig('meta', 'stats', 'total', 'count') if json_body.dig('meta', 'stats')
      end

      test 'order statuses sort by position and filter by flags and names' do
        login_as(:mark)

        assert_equal OrderStatus.order(:position).pluck(:id), ids('/api/v2/order_statuses', sort: 'position')
        assert_equal OrderStatus.order(position: :desc).pluck(:id), ids('/api/v2/order_statuses', sort: '-position')
        assert_equal [order_statuses(:abgeschlossen).id], ids('/api/v2/order_statuses', filter: { closed: true })
        assert_equal [order_statuses(:bearbeitung).id], ids('/api/v2/order_statuses', filter: { default: true })
        assert_equal [order_statuses(:offeriert).id],
                     ids('/api/v2/order_statuses', filter: { name: { prefix: 'offer' } })
      end

      test 'sectors filter by active' do
        login_as(:mark)

        assert_equal [sectors(:banken).id], ids('/api/v2/sectors', filter: { active: false })
        assert_equal Sector.where(active: true).pluck(:id).sort, ids('/api/v2/sectors', filter: { active: true }).sort
      end

      # ---- relationships ----

      test 'department includes its employees and employees their department and workplace' do
        login_as(:mark)
        department = departments(:devtwo)

        get "/api/v2/departments/#{department.id}", params: { include: 'employees' }, headers: JSONAPI

        assert_equal department.employees.pluck(:id).sort, json_body['included'].pluck('id').map(&:to_i).sort
        assert_equal ['employees'], json_body['included'].pluck('type').uniq
        related = json_body.dig('data', 'relationships', 'employees', 'links', 'related')

        assert_includes related, "department_id%5D=#{department.id}" if related.include?('%5D')

        employee = department.employees.where.not(workplace_id: nil).first
        login_as(:mark)
        get "/api/v2/employees/#{employee.id}", params: { include: 'department,workplace' }, headers: JSONAPI

        assert_equal %w[departments workplaces], json_body['included'].pluck('type').sort
        assert_equal employee.workplace.name,
                     json_body['included'].find { |item| item['type'] == 'workplaces' }.dig('attributes', 'name')

        assert_equal department.employees.pluck(:id).sort,
                     ids('/api/v2/employees', filter: { department_id: department.id }, page: { size: 100 }).sort
      end

      test 'employees show departments and workplaces only to those who may read them' do
        employee = employees(:pascal).tap { |e| e.update_columns(department_id: 1, workplace_id: 1) }
        login_as(:pascal)

        get "/api/v2/employees/#{employee.id}", params: { include: 'department,workplace' }, headers: JSONAPI

        assert_response :ok
        assert_empty json_body['included']
        assert_equal employee.department_id, json_body.dig('data', 'attributes', 'department_id')
      end

      test 'categories include roles, roles their category' do
        login_as(:mark)
        category = EmploymentRoleCategory.joins(:employment_roles).first

        get "/api/v2/employment_role_categories/#{category.id}", params: { include: 'employment_roles' },
                                                                 headers: JSONAPI

        assert_equal category.employment_roles.pluck(:id).sort, json_body['included'].pluck('id').map(&:to_i).sort
        role = category.employment_roles.first
        login_as(:mark)
        get "/api/v2/employment_roles/#{role.id}", params: { include: 'employment_role_category' }, headers: JSONAPI

        assert_equal category.id.to_s, json_body['included'].first['id']
        assert_equal [role.id], ids('/api/v2/employment_roles',
                                    filter: { employment_role_category_id: category.id, id: role.id })
      end

      test 'contacts and billing addresses relate to client and each other' do
        login_as(:mark)
        contact = contacts('swisstopo_1')
        address = billing_addresses(:swisstopo)

        get "/api/v2/contacts/#{contact.id}", params: { include: 'billing_addresses' }, headers: JSONAPI

        assert_equal [address.id.to_s], json_body['included'].pluck('id')
        get "/api/v2/billing_addresses/#{address.id}", params: { include: 'contact' }, headers: JSONAPI

        assert_equal [contact.id.to_s], json_body['included'].pluck('id')
        assert_equal [address.id, billing_addresses('swisstopo_2').id].sort,
                     ids('/api/v2/billing_addresses', filter: { client_id: contact.client_id }).sort
      end

      test 'contacts and billing addresses include their client and sectors their clients' do
        skip 'ClientResource comes from the orders group' unless Rails.root.join('app/resources/client_resource.rb').exist?
        login_as(:mark)
        contact = contacts('swisstopo_1')

        get "/api/v2/contacts/#{contact.id}", params: { include: 'client' }, headers: JSONAPI

        assert_equal [contact.client_id.to_s], json_body['included'].pluck('id')

        client = Client.first.tap { |row| row.update_column(:sector_id, sectors(:verwaltung).id) }
        login_as(:mark)
        get "/api/v2/sectors/#{client.sector_id}", params: { include: 'clients' }, headers: JSONAPI

        assert_equal [client.id.to_s], json_body['included'].pluck('id')
      end

      test 'employees include expenses, overtime vacations and employments of other groups' do
        %w[expense overtime_vacation employment].each do |name|
          skip "#{name} resource not there" unless Rails.root.join("app/resources/#{name}_resource.rb").exist?
        end
        login_as(:mark)

        get "/api/v2/employees/#{employees(:pascal).id}", params: { include: 'expenses,overtime_vacations,employments' },
                                                          headers: JSONAPI

        assert_response :ok, response.body
      end

      # ---- employees stay read-only ----

      test 'employees can not be written' do
        login_as(:mark)

        assert_raises(ActionController::RoutingError) do
          patch "/api/v2/employees/#{employees(:pascal).id}", params: payload('employees', { firstname: 'x' }, 1),
                                                              headers: JSONAPI
        end
      end
    end
  end
end
