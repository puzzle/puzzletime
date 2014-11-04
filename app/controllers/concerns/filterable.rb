module Filterable

  private

  def filter_entries_by(entries, *keys)
    keys.inject(entries) do |filtered, key|
      if params[key].present?
        filtered.where(key => params[key])
      else
        filtered
      end
    end
  end

end