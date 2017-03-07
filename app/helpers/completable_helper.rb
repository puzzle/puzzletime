module CompletableHelper
  def completed_icon(date)
    if recently_completed(date)
      picon('disk', class: 'green')
    else
      picon('square', class: 'red')
    end
  end

  def recently_completed(date)
    date && date >= Time.zone.today.end_of_month - 1.month
  end

  def format_month(date)
    if date
      I18n.l(date, format: :month)
    end
  end
end
