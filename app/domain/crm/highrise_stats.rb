#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Crm
  class HighriseStats < Base
    NO_CATEGORY = '(no category)'

    def stats
      # BIExportJob runs at 1 o'clock in the morning, collect data from last day.
      deals = fetch_deals(1.day.ago.utc)

      count_stats(deals) + volume_stats(deals)
    end

    private

    def fetch_deals(on)
      updated = ::Highrise::Deal.find(:all, params: { since: timestamp(on) })
      counted = relevant_change(updated, on)

      counted.group_by(&:status).transform_values do |deals|
        deals.group_by { |deal| deal.try(:category).try(:name) || NO_CATEGORY }
      end
    end

    def timestamp(time)
      # Highrise wants 'yyyymmddhhmmss'
      # see https://github.com/basecamp/highrise-api/blob/master/sections/deals.md
      time.strftime('%Y%m%d000000')
    end

    def count_stats(grouped_deals)
      map_deals(grouped_deals) do |status, category, deals|
        {
          name: 'highrise_deals_yesterday',
          fields: { count: deals.count },
          tags: { category: category, status: status }
        }
      end
    end

    def volume_stats(grouped_deals)
      map_deals(grouped_deals) do |status, category, deals|
        value = deals.map { |deal| volume(deal) }.sum

        {
          name: 'highrise_volume_yesterday',
          fields: { value: value },
          tags: { category: category, status: status }
        }
      end
    end

    def relevant_change(deals, day)
      deals.select do |deal|
        next true if on?(day, deal.created_at)
        next false if deal.status == 'pending'
        next false if deal.status_changed_on.nil?
        on?(day, deal.status_changed_on)
      end
    end

    def on?(day, time)
      from = day.beginning_of_day
      to = day.end_of_day

      time >= from && time <= to
    end

    def map_deals(grouped_deals)
      grouped_deals.flat_map do |status, deals_by_category|
        deals_by_category.map do |category, deals|
          yield(status, category, deals)
        end
      end.compact
    end

    def volume(deal)
      deal.price_type == 'fixed' ? deal.price : deal.price * deal.duration
    end
  end
end
