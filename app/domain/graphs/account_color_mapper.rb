#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Graphs::AccountColorMapper
  def initialize
    @map = {}
  end

  def [](account)
    @map[account] ||= generate_color account
  end

  def accounts?(type)
    !accounts(type).empty?
  end

  def accounts_legend(type)
    accounts = accounts(type).sort
    accounts.collect { |p| [p.label_verbose, @map[p]] }
  end

  private

  def generate_color(account)
    if account.is_a?(Absence)
      generate_absence_color(account.id)
    else
      generate_work_item_color(account.id)
    end
  end

  def generate_absence_color(id)
    srand id
    '#FF' + random_color(230) + random_color(140)
  end

  def generate_work_item_color(id)
    srand id
    '#' + random_color(170) + random_color(240) + 'FF'
  end

  def random_color(span = 170)
    lower = (255 - span) / 2
    hex = (lower + rand(span)).to_s(16)
    hex.size == 1 ? '0' + hex : hex
  end

  def accounts(type)
    @map.keys.select { |key| key.is_a? type }
  end
end
