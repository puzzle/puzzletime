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

  def accountsLegend(type)
    accounts = accounts(type).sort
    accounts.collect { |p| [p.label_verbose, @map[p]] }
  end

  private

  def generate_color(account)
    return Timebox::ATTENDANCE_POS_COLOR if account.nil?
    account.is_a?(Absence) ?
        generateAbsenceColor(account.id) :
        generateProjectColor(account.id)
  end

  def generateAbsenceColor(id)
    srand id
    '#FF' + randomColor(230) + randomColor(140)
  end

  def generateProjectColor(id)
    srand id
    '#' + randomColor(170) + randomColor(240) + 'FF'
  end

  def randomColor(span = 170)
    lower = (255 - span) / 2
    hex = (lower + rand(span)).to_s(16)
    hex.size == 1 ? '0' + hex : hex
  end

  def accounts(type)
    @map.keys.select { |key| key.is_a? type }
  end

end
