module Closable
  extend ActiveSupport::Concern

  included do
    before_update :remember_closed_change
    after_update :propagate_closed_change
  end

  def propagate_closed!
    work_item.propagate_closed!(closed?)
  end

  private

  def remember_closed_change
    if closed_changed?
      @closed_changed = true
    end
  end

  def propagate_closed_change
    if @closed_changed
      propagate_closed!
    end
    @closed_changed = nil
  end

end