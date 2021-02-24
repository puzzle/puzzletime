module BI
  class InfluxEnsureBucket
    class OrgNotFound < StandardError; end

    def initialize(client, org)
      @client = client
      @api = InfluxDB2::API::Client.new(client)
      @org = find_org(org, @api)
    end

    def bucket(bucket)
      return if bucket_exists?(bucket, @org, @api)

      create_bucket(bucket, @org, @api)
    end

    private

    def find_org(name, api)
      org =
        api.create_organizations_api.get_orgs.orgs.select do |it|
          it.name == name
        end.first

      raise OrgNotFound, "No org with name #{name} present" if org.nil?
      org
    end

    def bucket_exists?(name, org, api)
      api.create_buckets_api.get_buckets(name: name).buckets.any?
    end

    def create_bucket(name, org, api)
      request =
        InfluxDB2::API::PostBucketRequest.new(org_id: org.id, name: name)
      api.create_buckets_api.post_buckets(request)
    end
  end
end
