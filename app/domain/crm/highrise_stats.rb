#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Crm
  class HighriseStats < Base
    NO_CATEGORY = '(no category)'.freeze

    def stats
      # Job runs at 1 in the morning, collect data from yesterday
      month_from = 1.day.ago.beginning_of_month.utc
      month_deals = fetch_deals(modified_since: month_from)
      pending_deals = fetch_deals(status: 'pending')

      month_stats(month_deals, month_from) + stale_stats(pending_deals)
    end

    private

    def fetch_deals(modified_since: nil, status: nil)
      # This ignores paging. If we ever get more than 500 deals we'll have to do multiple requests.

      params = {}
      params[:since] = timestamp(modified_since) unless modified_since.nil?
      params[:status] = status unless status.nil?

      ::Highrise::Deal.find(:all, params: params).yield_self do |deals|
        modified_since.nil? ? deals : status_changed(deals, modified_since)
      end
    end

    def group(deals)
      deals.group_by(&:status).transform_values do |deals|
        deals.group_by { |deal| deal.try(:category).try(:name) || NO_CATEGORY }
      end
    end

    def timestamp(time)
      # Highrise wants 'yyyymmddhhmmss'
      # see https://github.com/basecamp/highrise-api/blob/master/sections/deals.md
      time.strftime('%Y%m%d000000')
    end

    def month_stats(deals, month)
      build_stats(
        group(deals).except('pending'),
        month: month.strftime('%Y-%m')
      )
    end

    def stale_stats(deals)
      deals.partition { |deal| deal.updated_at <= 3.months.ago.utc }.zip(
        [true, false]
      )
        .flat_map { |deals, stale| build_stats(group(deals), stale: stale) }
    end

    def build_stats(deals, tags = {})
      count_stats(deals, tags) + volume_stats(deals, tags)
    end

    def count_stats(grouped_deals, tags)
      map_deals(grouped_deals) do |status, category, deals|
        {
          name: 'highrise_deals',
          fields: { count: deals.count },
          tags: { category: category, status: status }.merge(tags)
        }
      end
    end

    def volume_stats(grouped_deals, tags)
      map_deals(grouped_deals) do |status, category, deals|
        value = deals.map { |deal| volume(deal) }.sum

        {
          name: 'highrise_volume',
          fields: { value: value },
          tags: { category: category, status: status }.merge(tags)
        }
      end
    end

    def status_changed(deals, since)
      deals.select do |deal|
        next deal.created_at >= since if deal.status_changed_on.nil?
        deal.status_changed_on >= since
      end
    end

    def map_deals(grouped_deals)
      grouped_deals.flat_map do |status, deals_by_category|
        deals_by_category.map do |category, deals|
          yield(status, category, deals)
        end
      end.compact
    end

    def volume(deal)
      return 0 if deal.price.nil?
      deal.price_type == 'fixed' ? deal.price : deal.price * deal.duration
    end
  end
end
