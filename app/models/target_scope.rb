class TargetScope

  has_many :order_targets

  validates :name, :position, :icon, presence: true, uniqueness: true

  protect_if :order_targets, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Ziele zugeordnet sind'

  scope :list, -> { order(:position) }

  def to_s
    name
  end

end