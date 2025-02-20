# frozen_string_literal: true
require 'xmlrpc/client'

module Crm
  class Odoo
    class Api
      def initialize(**opts)
        @api_url = opts[:api_url] || Settings.odoo.api_url
        @base_url = opts[:base_url] || Settings.odoo.base_url
        @database = opts[:database] || Settings.odoo.database
        @user = opts[:user] || Settings.odoo.user
        @password = opts[:password] || Settings.odoo.password
      end

      def login
        @uid = common_endpoint.call('authenticate', @database, @user, @password, {})
      end

      def name_search(model, parameters: [], options: {})
        model_cmd(model, 'name_search', [parameters], options)
      end

      def search(model, parameters: [], options: {})
        model_cmd(model, 'search', [parameters], options)
      end

      def count(model, parameters: [], options: {})
        model_cmd(model, 'search_count', [parameters], options)
      end

      def read(model, ids, options: {})
        model_cmd(model, 'read', [ids].flatten, options)
      end

      def fields_get(model, options: {})
        model_cmd(model, 'fields_get', [], options)
      end

      def search_read(model, parameters: [], options: {})
        model_cmd(model, 'search_read', [parameters], options)
      end

      def models(select: nil)
        models = search_read('ir.model', options: {fields: [:name, :model, :state]})
          .sort_by { _1["id"] }

        models = models.select { _1["name"] =~ /#{select}/ } if select

        models
      end

      private

      def common_endpoint
        @common ||= XMLRPC::Client.new2("#{@api_url}/xmlrpc/2/common")
      end

      def models_endpoint
        @models ||= XMLRPC::Client.new2("#{@api_url}/xmlrpc/2/object").proxy
      end

      def model_cmd(model, cmd, parameters, options)
        login unless @uid

        models_endpoint.execute_kw(@database, @uid, @password, model, cmd, parameters, options)
      rescue XMLRPC::FaultException => e
        @uid=nil

        Rails.logger.error(<<~ERROR)
          Error:
            #{e.faultCode}
            #{e.faultString}
        ERROR

        raise
      end
    end
  end
end
