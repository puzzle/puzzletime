# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # Adds the `crud` macro to a Grape API:
    #
    #   crud Department, read: %i[id name shortname], write: %i[name shortname], relationships: %i[employees]
    #   generate_crud_routes # once, after all `crud` lines
    #
    # Plain models need only the first three options. Models whose rules live in controllers/Ability
    # use the extension points below; hooks and the `extra` block run in the Grape endpoint context
    # (`current_user`, `authorize!`, `error!`, `params`, `declared` are available).
    #
    # * `read`          - attributes rendered in responses. Always explicit. A Hash entry renders an association
    #                     through a nested entity: `{ roles: %i[id name] }`.
    # * `write`         - attributes accepted on create and update. Empty (default) = read-only resource.
    # * `create_only`   - attributes accepted on create only (e.g. a parent id).
    # * `nested`        - nested attributes, e.g. `{ items_attributes: %i[name] }`. Key `<assoc>_attributes`; the
    #                     association decides Array (collection) or Hash. `id` and `_destroy` are added.
    # * `relationships` - associations exposed as `GET /<resources>/:id/<association>`. The target model
    #                     must be registered with `crud` itself; it is listed through the target's own `scope`.
    # * `scope`         - `->(user) { relation }`: rows this user may see. Applies to index, show, update, delete
    #                     and relationship lists; anything outside is a 404. Default: all rows. `Ability` still
    #                     applies on top, but index only checks the class, so restrict here when rules are
    #                     per instance.
    # * `writable_by`   - `->(user) { attrs }`: the subset of `write` this user may set; others get 403.
    # * `prepare`       - `{ |entry| ... }` after attributes are assigned, before authorization and save
    #                     (set defaults/actors, run extra checks, call `error!`).
    # * `types`         - input type overrides for `write`/`create_only`, e.g. `{ hours: String }` where the model
    #                     setter parses richer formats than the column type (`"8:45"`).
    # * `destroy`       - `{ |entry| truthy }` replaces `entry.destroy` (soft deletes, side effects).
    # * `except`        - generic actions to leave out: `%i[index show create update destroy]`.
    # * block           - extra routes inside the resource namespace (`route_param :id do ... end`).
    #
    # Param and response types (and so the swagger docs) come from the column metadata. Presence,
    # formats and everything else stay with the model validations; failures render as
    # 422 `{ errors: { attr: [messages] } }`. Updates are authorized on the loaded row and again after the
    # attributes are assigned, creates after assignment.
    module Crud
      # A registered model: its crud options and the response entity built from `read`.
      Resource = Data.define(:model, :read, :write, :create_only, :nested, :relationships, :scope,
                             :writable_by, :types, :except, :prepare, :destroy, :extra, :entity) do
        def writable?
          (write + create_only).any? || nested.any?
        end

        def actions
          (%i[index show] + (writable? ? %i[create update destroy] : [])) - except
        end
      end

      # Anonymous classes can't be named for swagger, so response entities live here.
      module Entities; end

      TYPES = { integer: Integer, boolean: Grape::API::Boolean, decimal: BigDecimal,
                float: Float, date: Date, datetime: DateTime }.freeze

      RESOURCE_DEFAULTS = { write: [], create_only: [], nested: {}, relationships: [], scope: nil, writable_by: nil,
                            types: {}, except: [], prepare: nil, destroy: nil }.freeze

      class << self
        def resources
          @resources ||= {}
        end

        # Expose further associations of an already registered model (used by resource modules).
        def relate(model, *names)
          resource = resources.fetch(model)
          resources[model] = resource.with(relationships: resource.relationships | names)
        end

        # The rows `user` may see for `model`.
        def base(model, user)
          scope = resources.fetch(model).scope
          scope ? scope.call(user) : model.all
        end

        def param_options(model, attr)
          if (values = model.defined_enums[attr.to_s])
            return { type: String, values: values.keys }
          end

          column = model.columns_hash.fetch(attr.to_s) { raise ArgumentError, "#{model} has no column #{attr}" }
          type = TYPES.fetch(column.type, String)
          { type: column.try(:array) ? [type] : type }
        end

        # Declares params for `attrs` (and `nested`) of `model` on a Grape params scope.
        def declare(scope, model, attrs, nested = {}, types = {})
          attrs.each do |attr|
            options = param_options(model, attr)
            options[:type] = types[attr] if types.key?(attr)
            scope.optional attr, **options
          end
          nested.each do |key, nested_attrs|
            reflection = nested_reflection(model, key)
            scope.optional key, type: reflection.collection? ? Array : Hash do
              Crud.declare(self, reflection.klass, [:id, *nested_attrs])
              optional :_destroy, type: Grape::API::Boolean
            end
          end
        end

        def nested_reflection(model, key)
          name = key.to_s.delete_suffix('_attributes')
          model.reflect_on_association(name) || raise(ArgumentError, "#{model} has no association #{name}")
        end

        def relationship(model, name)
          reflection = model.reflect_on_association(name) || raise(ArgumentError, "#{model} has no association #{name}")
          target = resources.fetch(reflection.klass) do
            raise ArgumentError, "#{reflection.klass} must be registered with crud to expose #{model}##{name}"
          end
          [reflection, target]
        end
      end

      def crud(model, read:, **, &extra)
        Crud.resources[model] = Resource.new(**RESOURCE_DEFAULTS, **, model:, read:, extra:,
                                                                      entity: EntityBuilder.call(model, read))
      end

      def generate_crud_routes
        Crud.resources.each_value { |res| crud_routes(res) }
      end

      private

      # One flat route table: the Grape DSL blocks can't call helper methods on the API class, so splitting
      # this up would only scatter it.
      # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def crud_routes(res)
        model = res.model
        entity = res.entity
        actions = res.actions

        # rubocop:disable-next Metrics/BlockLength
        resource model.model_name.route_key do
          if actions.include?(:index)
            desc "List #{model.model_name.human(count: 2)}", success: entity, is_array: true
            params { use :pagination }
            get do
              authorize!(:index, model)
              base = Crud.base(model, current_user)
              present paginate(model.respond_to?(:list) ? base.list : base.order(:id)), with: entity
            end
          end

          if actions.include?(:create)
            desc "Create #{model.model_name.human}", success: entity
            params { Crud.declare(self, model, res.write + res.create_only, res.nested, res.types) }
            post do
              entry = model.new(writable(res, creating: true))
              instance_exec(entry, &res.prepare) if res.prepare
              authorize!(:create, entry)
              save!(entry)
              present entry, with: entity
            end
          end

          route_param :id, type: Integer do
            if actions.include?(:show)
              desc "Show #{model.model_name.human}", success: entity
              get do
                entry = Crud.base(model, current_user).find(params[:id])
                authorize!(:show, entry)
                present entry, with: entity
              end
            end

            if actions.include?(:update)
              desc "Update #{model.model_name.human}", success: entity
              params { Crud.declare(self, model, res.write, res.nested, res.types) }
              patch do
                entry = Crud.base(model, current_user).find(params[:id])
                authorize!(:update, entry)
                entry.assign_attributes(writable(res, creating: false))
                instance_exec(entry, &res.prepare) if res.prepare
                authorize!(:update, entry)
                save!(entry)
                present entry, with: entity
              end
            end

            if actions.include?(:destroy)
              desc "Delete #{model.model_name.human}"
              delete do
                entry = Crud.base(model, current_user).find(params[:id])
                authorize!(:destroy, entry)
                destroyed = res.destroy ? instance_exec(entry, &res.destroy) : entry.destroy
                error!({ errors: entry.errors.to_hash }, 422) unless destroyed
                status 204
                body false
              end
            end

            res.relationships.each do |name|
              reflection, target = Crud.relationship(model, name)

              if reflection.collection?
                desc "List #{name} of #{model.model_name.human}", success: target.entity, is_array: true
                params { use :pagination }
                get name.to_s do
                  parent = Crud.base(model, current_user).find(params[:id])
                  authorize!(:show, parent)
                  authorize!(:index, target.model)
                  # `merge` would drop a scope condition on the same column as the association's (e.g. a foreign key).
                  related = parent.public_send(name).unscope(:order).select(target.model.primary_key)
                  scope = Crud.base(target.model, current_user).where(target.model.primary_key => related)
                  present paginate(target.model.respond_to?(:list) ? scope.list : scope.order(:id)),
                          with: target.entity
                end
              else
                desc "Show #{name} of #{model.model_name.human}", success: target.entity
                get name.to_s do
                  parent = Crud.base(model, current_user).find(params[:id])
                  authorize!(:show, parent)
                  related = parent.public_send(name) || error!({ error: 'Not found' }, 404)
                  authorize!(:show, related)
                  present related, with: target.entity
                end
              end
            end
          end

          instance_exec(&res.extra) if res.extra
        end
      end
    end
  end
end
