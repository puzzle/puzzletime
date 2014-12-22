Fabricator(:ordertime) do
  work_date { Date.today }
  hours 2
  report_type 'absolute_day'
end

Fabricator(:absencetime) do
  work_date { Date.today }
  hours 2
  report_type 'absolute_day'
end
