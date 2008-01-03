class AccountColorMapper 
  
  def initialize
    @map = Hash.new
  end
  
  def [](account)
    @map[account] ||= generate_color account
  end
  
  def accounts?(type)
    ! accounts(type).empty?
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
    '#FF' + randomColor(190) + randomColor(10)
  end
  
  def generateProjectColor(id)
    srand id
    '#' + randomColor(120) + randomColor + 'FF'
  end
  
  def randomColor(span = 170)
    lower = (255 - span) / 2
    (lower + rand(span)).to_s(16)
  end
  
  def accounts(type)
    @map.keys.select { |key| key.is_a? type }
  end
  
end