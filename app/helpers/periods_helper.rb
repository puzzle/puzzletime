# frozen_string_literal: true

module PeriodsHelper
  def period_link(label, shortcut, options = {})
    link_to(label,
            periods_path(period_shortcut: shortcut, back_url: params[:back_url]),
            options.merge(data: { method: :patch }))
  end
end
