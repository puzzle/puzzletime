#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time query: hours per Member x Geschäftsjahr x billable for Dienstleistung "Projektleitung",
# fiscal years 2021/22 .. 2025/26 (01.07.2021 - 30.06.2026).
# Run with: bin/rails runner script/project_lead_export.rb
# Preview with fixture data instead of the DB: PREVIEW=1 bin/rails runner script/project_lead_export.rb
# ponytail: one-off report script, not a permanent feature. Delete after use.

exec('/usr/bin/env', 'rails', 'runner', $PROGRAM_NAME, *ARGV) unless defined?(Rails)

require 'json'

FROM    = '2021-07-01'
TO      = '2026-06-30'
SERVICE = 'Projektleitung'
HTML_PATH = ENV['PREVIEW'] ? 'project_lead_export_preview.html' : 'project_lead_export.html'

if ENV['PREVIEW']
  members = ['M. Keller', 'D. Frei', 'S. Huber', 'A. Meier', 'R. Lang', 'T. Burkhalter']
  data = %w[2021/22 2022/23 2023/24 2024/25 2025/26].flat_map do |fy|
    members.sample(rand(3..6)).flat_map do |member|
      [{ fiscal_year: fy, member: member, billable: true, hours: rand(50..900).to_f },
       { fiscal_year: fy, member: member, billable: false, hours: rand(5..200).to_f }]
    end
  end
else
  sql = <<~SQL.squish
    SELECT (EXTRACT(YEAR FROM w.work_date) + CASE WHEN EXTRACT(MONTH FROM w.work_date) >= 7 THEN 1 ELSE 0 END)::int AS fy_end,
           TRIM(COALESCE(e.firstname, '') || ' ' || COALESCE(e.lastname, '')) AS member,
           w.billable,
           SUM(w.hours) AS hours
    FROM worktimes w
    JOIN employees e ON e.id = w.employee_id
    JOIN work_items wi ON wi.id = w.work_item_id
    JOIN accounting_posts ap ON ap.work_item_id = wi.id
    JOIN services s ON s.id = ap.service_id
    WHERE w.work_date BETWEEN '#{FROM}' AND '#{TO}'
      AND s.name = '#{SERVICE}'
    GROUP BY fy_end, member, w.billable
    ORDER BY fy_end, member, w.billable
  SQL

  data = ActiveRecord::Base.connection.exec_query(sql).map do |r|
    { fiscal_year: "#{r['fy_end'] - 1}/#{r['fy_end'].to_s[2, 2]}", member: r['member'],
      billable: r['billable'], hours: r['hours'].to_f }
  end
end

File.write(HTML_PATH, <<~HTML)
  <!doctype html>
  <html lang="de">
  <head>
  <meta charset="utf-8">
  <title>Projektleitung – Geschäftsjahre #{FROM} – #{TO}</title>
  <style>
    @import url('https://fonts.googleapis.com/css?family=Roboto:300,400,500');
    :root {
      color-scheme: light dark;
      --bg: #ffffff; --surface: #ffffff; --text: #4a4a4a; --muted: #999999;
      --border: #d8d8d8; --header-bg: #f5f5f5; --hover-row: #e9f0f8;
      --accent: #238bca; --accent-dark: #1e5a96; --accent-contrast: #ffffff;
      --billable: #61b44b; --nonbillable: #f0ad4e;
      --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1b1f24; --surface: #22262c; --text: #e4e4e2; --muted: #9a9a9a;
        --border: #383d44; --header-bg: #282d34; --hover-row: #24344a;
        --accent: #3fa8e0; --accent-dark: #238bca; --accent-contrast: #0d1310;
        --billable: #7cc766; --nonbillable: #f4bd6e; --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
      }
    }
    :root[data-theme="dark"] {
      color-scheme: dark;
      --bg: #1b1f24; --surface: #22262c; --text: #e4e4e2; --muted: #9a9a9a;
      --border: #383d44; --header-bg: #282d34; --hover-row: #24344a;
      --accent: #3fa8e0; --accent-dark: #238bca; --accent-contrast: #0d1310;
      --billable: #7cc766; --nonbillable: #f4bd6e; --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
    }
    :root[data-theme="light"] {
      color-scheme: light;
      --bg: #ffffff; --surface: #ffffff; --text: #4a4a4a; --muted: #999999;
      --border: #d8d8d8; --header-bg: #f5f5f5; --hover-row: #e9f0f8;
      --accent: #238bca; --accent-dark: #1e5a96; --accent-contrast: #ffffff;
      --billable: #61b44b; --nonbillable: #f0ad4e; --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
    }
    * { box-sizing: border-box; }
    body {
      font-family: Roboto, Helvetica, Arial, sans-serif; font-weight: 300;
      background: var(--bg); color: var(--text); margin: 0; padding: 0 0 4rem;
      display: flex; flex-direction: column; gap: 1.75rem;
    }
    header {
      display: flex; flex-direction: column; gap: 0.35rem;
      padding: 1.1rem clamp(1rem, 4vw, 3.5rem) 1rem;
      border-bottom: 3px solid var(--accent); background: var(--surface);
    }
    .header-row { display: flex; align-items: center; justify-content: space-between; gap: 1.5rem; }
    .wordmark { font-size: 0.72rem; font-weight: 500; text-transform: uppercase; letter-spacing: 0.1em; color: var(--accent-dark); }
    h1 { font-size: 1.5rem; font-weight: 500; margin: 0; letter-spacing: -0.01em; }
    .period { color: var(--muted); font-size: 0.95rem; }
    .content { display: flex; flex-direction: column; gap: 1.75rem; padding: 0 clamp(1rem, 4vw, 3.5rem); }
    .switch-field { display: flex; align-items: center; gap: 0.6rem; font-size: 0.85rem; color: var(--muted); cursor: pointer; white-space: nowrap; }
    .switch { position: relative; display: inline-block; width: 2.4rem; height: 1.4rem; flex-shrink: 0; }
    .switch input { position: absolute; opacity: 0; width: 100%; height: 100%; margin: 0; cursor: pointer; }
    .switch-track { position: absolute; inset: 0; background: var(--border); border-radius: 999px; transition: background 0.15s; }
    .switch-track::before { content: ""; position: absolute; top: 2px; left: 2px; width: calc(1.4rem - 4px); height: calc(1.4rem - 4px); background: var(--surface); border-radius: 50%; transition: transform 0.15s; box-shadow: var(--shadow); }
    .switch input:checked + .switch-track { background: var(--accent); }
    .switch input:checked + .switch-track::before { transform: translateX(1rem); }
    .stats { display: flex; flex-wrap: wrap; gap: 1px; background: var(--border); border: 1px solid var(--border); overflow: hidden; }
    .stat { flex: 1 1 160px; background: var(--surface); padding: 0.9rem 1.1rem; }
    .stat .label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    .stat .value { font-size: 1.4rem; font-weight: 500; font-variant-numeric: tabular-nums; margin-top: 0.15rem; }
    .filters { display: flex; flex-wrap: wrap; align-items: end; gap: 1.25rem; background: var(--header-bg); border: 1px solid var(--border); padding: 0.9rem 1.1rem; }
    .field { display: flex; flex-direction: column; gap: 0.3rem; }
    .field label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    select { font: inherit; font-size: 0.9rem; color: var(--text); background: var(--surface); border: 1px solid var(--border); border-radius: 3px; padding: 0.4rem 0.6rem; min-width: 10rem; }
    .spacer { flex: 1; }
    button { font: inherit; font-size: 0.85rem; font-weight: 500; color: var(--accent-contrast); background: var(--accent); border: 1px solid var(--accent); border-radius: 3px; padding: 0.4rem 0.85rem; cursor: pointer; }
    button:hover { background: var(--accent-dark); border-color: var(--accent-dark); }
    button:focus-visible, select:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    section.card { background: var(--surface); border: 1px solid var(--border); padding: 1.1rem 1.25rem 1.4rem; }
    .card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.75rem; gap: 1rem; }
    .card-head h2 { font-size: 1rem; font-weight: 500; margin: 0; }
    .table-scroll { overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; font-size: 0.9rem; }
    th, td { padding: 10px 15px; text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
    th { font-weight: 400; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em; color: var(--muted); background: var(--header-bg); }
    td { border-bottom: 1px solid var(--border); }
    th:first-child, td:first-child { text-align: left; font-variant-numeric: normal; }
    tbody tr:nth-child(even) { background: color-mix(in srgb, var(--header-bg) 55%, var(--surface)); }
    tbody tr:hover { background: var(--hover-row); }
    tfoot td { font-weight: 500; border-top: 2px solid var(--border); }
    thead th { cursor: pointer; user-select: none; }
    thead th:hover { color: var(--text); }
    thead th:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    thead th[aria-sort="ascending"]::after { content: " ▲"; }
    thead th[aria-sort="descending"]::after { content: " ▼"; }
    .muted { color: var(--muted); }
    body.fixed-width header, body.fixed-width .content { max-width: 70rem; margin-left: auto; margin-right: auto; width: 100%; }
    .dot { display: inline-block; width: 0.55em; height: 0.55em; border-radius: 50%; margin-right: 0.4em; }
    .dot.billable { background: var(--billable); }
    .dot.nonbillable { background: var(--nonbillable); }
    .header-controls { display: flex; align-items: center; gap: 1.5rem; flex-wrap: wrap; justify-content: flex-end; }
    .theme-field { display: flex; align-items: center; gap: 0.6rem; border: 0; margin: 0; padding: 0; font-size: 0.85rem; color: var(--muted); }
    .theme-field legend { float: left; padding: 0; margin-right: 0.6rem; }
    .segmented { display: inline-flex; border: 1px solid var(--border); border-radius: 3px; overflow: hidden; }
    .segmented label { position: relative; padding: 0.2rem 0.65rem; cursor: pointer; color: var(--text); }
    .segmented label + label { border-left: 1px solid var(--border); }
    .segmented input { position: absolute; opacity: 0; inset: 0; margin: 0; cursor: pointer; }
    .segmented label:has(input:checked) { background: var(--accent); color: var(--accent-contrast); font-weight: 400; }
    .segmented label:has(input:focus-visible) { outline: 2px solid var(--accent); outline-offset: 1px; }
  </style>
  <script>
    // Apply the saved theme before first paint to avoid a flash of the wrong colours.
    try { const t = localStorage.getItem('ptime-report-theme'); if (t) document.documentElement.dataset.theme = t; } catch (e) {}
  </script>
  </head>
  <body class="fixed-width">
  <header>
    <div class="header-row">
      <div>
        <div class="wordmark">PuzzleTime</div>
        <h1>Dienstleistung Projektleitung</h1>
        <div class="period">#{FROM} bis #{TO} · 5 Geschäftsjahre (01.07.–30.06.) · Basis: geleistete Stunden</div>
      </div>
      <div class="header-controls">
        <fieldset class="theme-field">
          <legend>Darstellung</legend>
          <span class="segmented">
            <label><input type="radio" name="theme" value="light">Hell</label>
            <label><input type="radio" name="theme" value="dark">Dunkel</label>
            <label><input type="radio" name="theme" value="" checked>System</label>
          </span>
        </fieldset>
        <label class="switch-field">
          <span>Breite fixieren</span>
          <span class="switch">
            <input type="checkbox" id="fixed-width" checked>
            <span class="switch-track"></span>
          </span>
        </label>
      </div>
    </div>
  </header>

  <div class="content">
  <div class="stats" id="stats"></div>

  <div class="filters">
    <div class="field">
      <label for="fy">Geschäftsjahr</label>
      <select id="fy"><option value="">Alle</option></select>
    </div>
    <div class="field">
      <label for="member">Member</label>
      <select id="member"><option value="">Alle</option></select>
    </div>
    <div class="spacer"></div>
    <button id="download-source">Quelldaten (CSV)</button>
  </div>

  <section class="card">
    <div class="card-head">
      <h2>Total pro Geschäftsjahr</h2>
      <button id="download-years">CSV</button>
    </div>
    <div class="table-scroll">
      <table id="years">
        <thead><tr><th>Geschäftsjahr</th><th><span class="dot billable"></span>Verrechenbar (h)</th><th><span class="dot nonbillable"></span>Nicht verrechenbar (h)</th><th>Total (h)</th><th>Anteil verrechenbar</th><th>Members</th></tr></thead>
        <tbody></tbody>
        <tfoot></tfoot>
      </table>
    </div>
  </section>

  <section class="card">
    <div class="card-head">
      <h2>Pro Member und Geschäftsjahr</h2>
      <button id="download-members">CSV</button>
    </div>
    <div class="table-scroll">
      <table id="members">
        <thead><tr><th>Member</th><th>Geschäftsjahr</th><th><span class="dot billable"></span>Verrechenbar (h)</th><th><span class="dot nonbillable"></span>Nicht verrechenbar (h)</th><th>Total (h)</th><th>Anteil verrechenbar</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
  </section>
  </div>

  <script>
  const data = #{data.to_json};
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const $ = id => document.getElementById(id);

  function num(n) {
    const [int, dec] = n.toFixed(2).split('.');
    return int.replace(/\\B(?=(\\d{3})+(?!\\d))/g, "'") + '.' + dec;
  }

  function downloadCsv(rows, header, filename) {
    const csv = [header, ...rows].map(r => r.map(v => `"${String(v ?? '').replace(/"/g, '""')}"`).join(',')).join('\\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob(['\\ufeff' + csv], { type: 'text/csv' }));
    a.download = filename;
    a.click();
    URL.revokeObjectURL(a.href);
  }

  [...new Set(data.map(r => r.fiscal_year))].sort().forEach(fy => $('fy').add(new Option(fy, fy)));
  [...new Set(data.map(r => r.member))].sort((a, b) => a.localeCompare(b, 'de')).forEach(m => $('member').add(new Option(m, m)));

  // key -> { true: h, false: h }
  function group(rows, keyOf) {
    const acc = {};
    rows.forEach(r => {
      acc[keyOf(r)] ??= { true: 0, false: 0 };
      acc[keyOf(r)][r.billable] += r.hours;
    });
    return acc;
  }
  const ratio = (b, nb) => (b + nb) ? num(100 * b / (b + nb)) + '%' : '-';
  const cells = (b, nb) => `<td>${num(b)}</td><td>${num(nb)}</td><td>${num(b + nb)}</td><td>${ratio(b, nb)}</td>`;

  let currentYears = [], currentMembers = [];
  // column index + direction per table; first click on a text column sorts ascending, on a number column descending
  const sorts = { years: { col: 0, desc: false }, members: { col: 0, desc: false } };
  const numeric = v => typeof v === 'number' ? v : (/^-?[\\d.]+%?$/.test(v) ? parseFloat(v) : null);

  function sortRows(rows, id) {
    const { col, desc } = sorts[id];
    return rows.sort((a, b) => {
      const x = numeric(a[col]), y = numeric(b[col]);
      const cmp = x !== null && y !== null ? x - y : String(a[col]).localeCompare(String(b[col]), 'de');
      return desc ? -cmp : cmp;
    });
  }

  document.querySelectorAll('#years thead th, #members thead th').forEach(th => {
    const id = th.closest('table').id;
    th.tabIndex = 0;
    const toggle = () => {
      sorts[id] = sorts[id].col === th.cellIndex
        ? { col: th.cellIndex, desc: !sorts[id].desc }
        : { col: th.cellIndex, desc: th.cellIndex > 0 };
      render();
    };
    th.addEventListener('click', toggle);
    th.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
    });
  });

  function markSorted(id) {
    document.querySelectorAll(`#${id} thead th`).forEach(th => {
      if (th.cellIndex === sorts[id].col) th.setAttribute('aria-sort', sorts[id].desc ? 'descending' : 'ascending');
      else th.removeAttribute('aria-sort');
    });
  }

  function render() {
    const rows = data.filter(r => (!$('fy').value || r.fiscal_year === $('fy').value) &&
                                  (!$('member').value || r.member === $('member').value));

    const byYear = group(rows, r => r.fiscal_year);
    currentYears = sortRows(Object.keys(byYear).sort().map(fy => {
      const { true: b, false: nb } = byYear[fy];
      const members = new Set(rows.filter(r => r.fiscal_year === fy && r.hours > 0).map(r => r.member)).size;
      return [fy, b.toFixed(2), nb.toFixed(2), (b + nb).toFixed(2), ratio(b, nb), members];
    }), 'years');
    markSorted('years');
    $('years').tBodies[0].innerHTML = currentYears.length
      ? currentYears.map(r => `<tr><td>${esc(r[0])}</td>${cells(+r[1], +r[2])}<td>${r[5]}</td></tr>`).join('')
      : '<tr><td colspan="6" class="muted">Keine Daten für diese Filter.</td></tr>';

    const totalB = rows.filter(r => r.billable).reduce((s, r) => s + r.hours, 0);
    const totalNb = rows.filter(r => !r.billable).reduce((s, r) => s + r.hours, 0);
    const allMembers = new Set(rows.filter(r => r.hours > 0).map(r => r.member));
    $('years').tFoot.innerHTML = `<tr><td>Total</td>${cells(totalB, totalNb)}<td>${allMembers.size}</td></tr>`;

    const byMember = group(rows, r => r.member + '\\u0000' + r.fiscal_year);
    currentMembers = sortRows(Object.keys(byMember).sort((a, b) => a.localeCompare(b, 'de')).map(key => {
      const [member, fy] = key.split('\\u0000');
      const { true: b, false: nb } = byMember[key];
      return [member, fy, b.toFixed(2), nb.toFixed(2), (b + nb).toFixed(2), ratio(b, nb)];
    }), 'members');
    markSorted('members');
    $('members').tBodies[0].innerHTML = currentMembers.length
      ? currentMembers.map(r => `<tr><td>${esc(r[0])}</td><td>${esc(r[1])}</td>${cells(+r[2], +r[3])}</tr>`).join('')
      : '<tr><td colspan="6" class="muted">Keine Daten für diese Filter.</td></tr>';

    $('stats').innerHTML = `
      <div class="stat"><div class="label">Total Stunden</div><div class="value">${num(totalB + totalNb)}</div></div>
      <div class="stat"><div class="label"><span class="dot billable"></span>Verrechenbar</div><div class="value">${num(totalB)}</div></div>
      <div class="stat"><div class="label"><span class="dot nonbillable"></span>Nicht verrechenbar</div><div class="value">${num(totalNb)}</div></div>
      <div class="stat"><div class="label">Anteil verrechenbar</div><div class="value">${ratio(totalB, totalNb)}</div></div>
      <div class="stat"><div class="label">Members</div><div class="value">${allMembers.size}</div></div>
    `;
  }

  ['fy', 'member'].forEach(id => $(id).addEventListener('change', render));
  $('fixed-width').addEventListener('change', e => document.body.classList.toggle('fixed-width', e.target.checked));
  const themeInputs = document.querySelectorAll('input[name="theme"]');
  themeInputs.forEach(input => {
    input.checked = input.value === (document.documentElement.dataset.theme ?? '');
    input.addEventListener('change', () => {
      if (input.value) document.documentElement.dataset.theme = input.value;
      else delete document.documentElement.dataset.theme;
      try {
        if (input.value) localStorage.setItem('ptime-report-theme', input.value);
        else localStorage.removeItem('ptime-report-theme');
      } catch (e) {}
    });
  });
  $('download-source').addEventListener('click', () => downloadCsv(
    data.map(r => [r.fiscal_year, r.member, r.billable, r.hours.toFixed(2)]),
    ['geschaeftsjahr', 'member', 'verrechenbar', 'stunden'], 'projektleitung_quelldaten.csv'));
  $('download-years').addEventListener('click', () => downloadCsv(currentYears,
    ['geschaeftsjahr', 'verrechenbar_h', 'nicht_verrechenbar_h', 'total_h', 'anteil_verrechenbar', 'members'],
    'projektleitung_geschaeftsjahre.csv'));
  $('download-members').addEventListener('click', () => downloadCsv(currentMembers,
    ['member', 'geschaeftsjahr', 'verrechenbar_h', 'nicht_verrechenbar_h', 'total_h', 'anteil_verrechenbar'],
    'projektleitung_members.csv'));
  render();
  </script>
  </body>
  </html>
HTML

puts "Wrote #{HTML_PATH} (#{data.size} rows embedded)"
