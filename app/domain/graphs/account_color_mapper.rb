# encoding: utf-8

class AccountColorMapper

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
    account.is_a?(Absence) ?
        generate_absence_color(account.id) :
        generate_work_item_color(account.id)
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
