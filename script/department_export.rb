#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time query: hours per Dienstleistung x billable, 2021-07-01..2026-06-30.
# Run with: bin/rails runner script/department_export.rb
# Preview with fixture data instead of the DB: PREVIEW=1 bin/rails runner script/department_export.rb
# If reused, it should be integrated into exports

exec('/usr/bin/env', 'rails', 'runner', $PROGRAM_NAME, *ARGV) unless defined?(Rails)

require 'json'

FROM = '2021-07-01'
TO   = '2026-06-30'
HTML_PATH = ENV['PREVIEW'] ? 'department_export_preview.html' : 'department_export.html'

if ENV['PREVIEW']
  services = %w[Projektleitung Entwicklung Support Beratung Testing Design Schulung Administration]
  data = (Date.parse(FROM)..Date.parse(TO)).select { |d| d.day == 1 }.flat_map do |month|
    services.map do |service|
      billable_h = rand(20..120).to_f
      non_billable_h = rand(5..30).to_f
      [{ month: month.to_s, service: service, billable: true, hours: billable_h },
       { month: month.to_s, service: service, billable: false, hours: non_billable_h }]
    end
  end.flatten
else
  sql = <<~SQL
    SELECT date_trunc('month', w.work_date)::date AS month,
           s.name AS service,
           w.billable,
           SUM(w.hours) AS hours
    FROM worktimes w
    JOIN work_items wi ON wi.id = w.work_item_id
    JOIN accounting_posts ap ON ap.work_item_id = wi.id
    JOIN services s ON s.id = ap.service_id
    WHERE w.work_date BETWEEN '#{FROM}' AND '#{TO}'
    GROUP BY month, s.name, w.billable
    ORDER BY month, s.name, w.billable
  SQL

  rows = ActiveRecord::Base.connection.exec_query(sql).to_a
  data = rows.map { |r| { month: r['month'], service: r['service'], billable: r['billable'], hours: r['hours'].to_f } }
end

File.write(HTML_PATH, <<~HTML)
  <!doctype html>
  <html lang="de">
  <head>
  <meta charset="utf-8">
  <title>Dienstleistungs-Auswertung #{FROM} – #{TO}</title>
  <style>
    @import url('https://fonts.googleapis.com/css?family=Roboto:300,400,500');
    :root {
      --bg: #ffffff;
      --surface: #ffffff;
      --text: #4a4a4a;
      --muted: #999999;
      --border: #d8d8d8;
      --header-bg: #f5f5f5;
      --hover-row: #e9f0f8;
      --accent: #238bca;
      --accent-dark: #1e5a96;
      --accent-contrast: #ffffff;
      --billable: #61b44b;
      --nonbillable: #f0ad4e;
      --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1b1f24;
        --surface: #22262c;
        --text: #e4e4e2;
        --muted: #9a9a9a;
        --border: #383d44;
        --header-bg: #282d34;
        --hover-row: #24344a;
        --accent: #3fa8e0;
        --accent-dark: #238bca;
        --accent-contrast: #0d1310;
        --billable: #7cc766;
        --nonbillable: #f4bd6e;
        --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
      }
    }
    :root[data-theme="dark"] {
      --bg: #1b1f24; --surface: #22262c; --text: #e4e4e2; --muted: #9a9a9a;
      --border: #383d44; --header-bg: #282d34; --hover-row: #24344a;
      --accent: #3fa8e0; --accent-dark: #238bca; --accent-contrast: #0d1310;
      --billable: #7cc766; --nonbillable: #f4bd6e; --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
    }
    :root[data-theme="light"] {
      --bg: #ffffff; --surface: #ffffff; --text: #4a4a4a; --muted: #999999;
      --border: #d8d8d8; --header-bg: #f5f5f5; --hover-row: #e9f0f8;
      --accent: #238bca; --accent-dark: #1e5a96; --accent-contrast: #ffffff;
      --billable: #61b44b; --nonbillable: #f0ad4e; --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
    }
    * { box-sizing: border-box; }
    body {
      font-family: Roboto, Helvetica, Arial, sans-serif;
      font-weight: 300;
      background: var(--bg);
      color: var(--text);
      margin: 0;
      padding: 0 0 4rem;
      display: flex;
      flex-direction: column;
      gap: 1.75rem;
    }
    header {
      display: flex; flex-direction: column; gap: 0.35rem;
      padding: 1.1rem clamp(1rem, 4vw, 3.5rem) 1rem;
      border-bottom: 3px solid var(--accent);
      background: var(--surface);
    }
    .header-row { display: flex; align-items: center; justify-content: space-between; gap: 1.5rem; }
    .wordmark { font-size: 0.72rem; font-weight: 500; text-transform: uppercase; letter-spacing: 0.1em; color: var(--accent-dark); }
    h1 { font-size: 1.5rem; font-weight: 500; margin: 0; text-wrap: balance; letter-spacing: -0.01em; }
    .period { color: var(--muted); font-size: 0.95rem; }
    .content { display: flex; flex-direction: column; gap: 1.75rem; padding: 0 clamp(1rem, 4vw, 3.5rem); }
    .switch-field { display: flex; align-items: center; gap: 0.6rem; font-size: 0.85rem; color: var(--muted); cursor: pointer; white-space: nowrap; }
    .switch { position: relative; display: inline-block; width: 2.4rem; height: 1.4rem; flex-shrink: 0; }
    .switch input { position: absolute; opacity: 0; width: 100%; height: 100%; margin: 0; cursor: pointer; }
    .switch-track { position: absolute; inset: 0; background: var(--border); border-radius: 999px; transition: background 0.15s; }
    .switch-track::before { content: ""; position: absolute; top: 2px; left: 2px; width: calc(1.4rem - 4px); height: calc(1.4rem - 4px); background: var(--surface); border-radius: 50%; transition: transform 0.15s; box-shadow: var(--shadow); }
    .switch input:checked + .switch-track { background: var(--accent); }
    .switch input:checked + .switch-track::before { transform: translateX(1rem); }
    .switch input:focus-visible + .switch-track { outline: 2px solid var(--accent); outline-offset: 2px; }
    .stats {
      display: flex; flex-wrap: wrap; gap: 1px;
      background: var(--border);
      border: 1px solid var(--border);
      overflow: hidden;
    }
    .stat { flex: 1 1 160px; background: var(--surface); padding: 0.9rem 1.1rem; }
    .stat .label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    .stat .value { font-size: 1.4rem; font-weight: 500; font-variant-numeric: tabular-nums; margin-top: 0.15rem; }
    .filters {
      display: flex; flex-wrap: wrap; align-items: end; gap: 1.25rem;
      background: var(--header-bg); border: 1px solid var(--border);
      padding: 0.9rem 1.1rem;
    }
    .field { display: flex; flex-direction: column; gap: 0.3rem; }
    .field label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    select {
      font: inherit; font-size: 0.9rem; color: var(--text); background: var(--surface);
      border: 1px solid var(--border); border-radius: 3px; padding: 0.4rem 0.6rem; min-width: 10rem;
    }
    .spacer { flex: 1; }
    button {
      font: inherit; font-size: 0.85rem; font-weight: 500; color: var(--accent-contrast);
      background: var(--accent); border: 1px solid var(--accent); border-radius: 3px;
      padding: 0.4rem 0.85rem; cursor: pointer;
    }
    button:hover { background: var(--accent-dark); border-color: var(--accent-dark); }
    button:focus-visible, select:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    section.card {
      background: var(--surface); border: 1px solid var(--border);
      padding: 1.1rem 1.25rem 1.4rem;
    }
    .card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.75rem; gap: 1rem; }
    .card-head h2 { font-size: 1rem; font-weight: 500; margin: 0; }
    .table-scroll { overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; font-size: 0.9rem; }
    th, td { padding: 10px 15px; text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
    th { font-weight: 400; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em; color: var(--muted); background: var(--header-bg); }
    td { border-bottom: 1px solid var(--border); }
    #totals th:first-child, #totals td:first-child { text-align: left; font-variant-numeric: normal; }
    #monthly th:nth-child(3), #monthly td:nth-child(3) { text-align: left; font-variant-numeric: normal; }
    #monthly th:nth-child(1), #monthly td:nth-child(1), #monthly th:nth-child(2), #monthly td:nth-child(2), #monthly th:nth-child(5), #monthly td:nth-child(5) { width: 1%; }
    body.fixed-width header, body.fixed-width .content { max-width: 70rem; margin-left: auto; margin-right: auto; width: 100%; }
    tbody tr:nth-child(even) { background: color-mix(in srgb, var(--header-bg) 55%, var(--surface)); }
    tbody tr:hover { background: var(--hover-row); }
    .dot { display: inline-block; width: 0.55em; height: 0.55em; border-radius: 50%; margin-right: 0.4em; }
    .dot.billable { background: var(--billable); }
    .dot.nonbillable { background: var(--nonbillable); }
  </style>
  </head>
  <body class="fixed-width">
  <header>
    <div class="header-row">
      <div>
        <div class="wordmark">PuzzleTime</div>
        <h1>Dienstleistungs-Auswertung</h1>
        <div class="period">#{FROM} bis #{TO} · Basis: geleistete Stunden pro Monat</div>
      </div>
      <label class="switch-field">
        <span>Breite fixieren</span>
        <span class="switch">
          <input type="checkbox" id="fixed-width" checked>
          <span class="switch-track"></span>
        </span>
      </label>
    </div>
  </header>

  <div class="content">
  <div class="stats" id="stats"></div>

  <div class="filters">
    <div class="field">
      <label for="service">Dienstleistung</label>
      <select id="service"><option value="">Alle</option></select>
    </div>
    <div class="field">
      <label for="billable">Verrechenbar</label>
      <select id="billable">
        <option value="">Alle</option>
        <option value="true">Verrechenbar</option>
        <option value="false">Nicht verrechenbar</option>
      </select>
    </div>
    <div class="spacer"></div>
    <button id="download-source">Quelldaten (CSV)</button>
  </div>

  <section class="card">
    <div class="card-head">
      <h2>Total pro Dienstleistung</h2>
      <button id="download-totals">CSV</button>
    </div>
    <div class="table-scroll">
      <table id="totals">
        <thead><tr><th><span class="dot billable"></span>Dienstleistung</th><th>Verrechenbar (h)</th><th>Nicht verrechenbar (h)</th><th>Anteil verrechenbar</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
  </section>

  <section class="card">
    <div class="card-head">
      <h2>Pro Monat</h2>
      <button id="download-monthly">CSV</button>
    </div>
    <div class="table-scroll">
      <table id="monthly">
        <thead><tr><th>Jahr</th><th>Monat</th><th>Dienstleistung</th><th>Stunden</th><th>$</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
  </section>
  </div>

  <script>
  const data = #{data.to_json};

  function downloadCsv(rows, header, filename) {
    const csv = [header, ...rows].map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    a.download = filename;
    a.click();
    URL.revokeObjectURL(a.href);
  }

  const serviceSelect = document.getElementById('service');
  [...new Set(data.map(r => r.service))].sort().forEach(s => {
    const opt = document.createElement('option');
    opt.value = s; opt.textContent = s;
    serviceSelect.appendChild(opt);
  });

  function chf(n) {
    const [int, dec] = n.toFixed(2).split('.');
    return int.replace(/\\B(?=(\\d{3})+(?!\\d))/g, "'") + '.' + dec;
  }

  function filtered() {
    const service = serviceSelect.value;
    const billable = document.getElementById('billable').value;
    return data.filter(r =>
      (!service || r.service === service) &&
      (!billable || String(r.billable) === billable)
    ).sort((a, b) => a.month.localeCompare(b.month) || a.service.localeCompare(b.service) || (b.billable - a.billable));
  }

  let currentTotals = [];
  let currentMonthly = [];

  function render() {
    const rows = filtered();

    const totals = {};
    rows.forEach(r => {
      totals[r.service] ??= { true: 0, false: 0 };
      totals[r.service][r.billable] += r.hours;
    });
    currentTotals = Object.keys(totals).sort().map(service => {
      const { true: b, false: nb } = totals[service];
      const ratio = (b + nb) ? (100 * b / (b + nb)).toFixed(2) : '';
      return [service, b.toFixed(2), nb.toFixed(2), ratio];
    });
    document.querySelector('#totals tbody').innerHTML = currentTotals
      .map(r => `<tr><td>${r[0]}</td><td>${chf(+r[1])}</td><td>${chf(+r[2])}</td><td>${r[3] ? chf(+r[3]) + '%' : '-'}</td></tr>`)
      .join('');

    currentMonthly = rows.map(r => [r.month.slice(0, 4), r.month.slice(5, 7), r.service, r.hours.toFixed(2), r.billable]);
    document.querySelector('#monthly tbody').innerHTML = currentMonthly
      .map(r => `<tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td><td>${chf(+r[3])}</td><td>${r[4] ? '$' : ''}</td></tr>`)
      .join('');

    const billableTotal = rows.filter(r => r.billable).reduce((s, r) => s + r.hours, 0);
    const nonBillableTotal = rows.filter(r => !r.billable).reduce((s, r) => s + r.hours, 0);
    const overallRatio = (billableTotal + nonBillableTotal) ? chf(100 * billableTotal / (billableTotal + nonBillableTotal)) + '%' : '-';
    document.getElementById('stats').innerHTML = `
      <div class="stat"><div class="label">Total Stunden</div><div class="value">${chf(billableTotal + nonBillableTotal)}</div></div>
      <div class="stat"><div class="label"><span class="dot billable"></span>Verrechenbar</div><div class="value">${chf(billableTotal)}</div></div>
      <div class="stat"><div class="label"><span class="dot nonbillable"></span>Nicht verrechenbar</div><div class="value">${chf(nonBillableTotal)}</div></div>
      <div class="stat"><div class="label">Anteil verrechenbar</div><div class="value">${overallRatio}</div></div>
      <div class="stat"><div class="label">Dienstleistungen</div><div class="value">${new Set(rows.map(r => r.service)).size}</div></div>
    `;
  }

  serviceSelect.addEventListener('change', render);
  document.getElementById('billable').addEventListener('change', render);
  document.getElementById('fixed-width').addEventListener('change', e =>
    document.body.classList.toggle('fixed-width', e.target.checked));
  document.getElementById('download-source').addEventListener('click', () =>
    downloadCsv(data.map(r => [r.month, r.service, r.billable, r.hours]), ['month', 'service', 'billable', 'hours'], 'department_export_source.csv'));
  document.getElementById('download-totals').addEventListener('click', () =>
    downloadCsv(currentTotals, ['service', 'billable_h', 'non_billable_h', 'billable_ratio'], 'department_export_totals.csv'));
  document.getElementById('download-monthly').addEventListener('click', () =>
    downloadCsv(currentMonthly, ['year', 'month', 'service', 'hours', 'billable'], 'department_export_monthly.csv'));
  render();
  </script>
  </body>
  </html>
HTML

puts "Wrote #{HTML_PATH} (#{data.size} rows embedded)"
