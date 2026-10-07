# One-time export: Chancen & Risiken across all orders as a self-contained HTML file.
# Run with: bin/rails runner script/order_uncertainty_export.rb
# Preview with fixture data instead of the DB: PREVIEW=1 bin/rails runner script/order_uncertainty_export.rb
# ponytail: one-off report script, not a permanent feature. Delete after use.

require 'json'

STAND = Time.zone.today.strftime('%d.%m.%Y')
HTML_PATH = ENV['PREVIEW'] ? 'order_uncertainty_export_preview.html' : 'order_uncertainty_export.html'

if ENV['PREVIEW']
  statuses = [['Bearbeitung', false], ['Abschluss', false], ['Abgeschlossen', true]]
  people = ['M. Keller', 'D. Frei', 'S. Huber', 'A. Meier']
  departments = ['/dev/one', '/dev/two', '/sys']
  names = ['Kundenportal Relaunch', 'Migration Java 21', 'Betrieb Kubernetes', 'Data Platform', 'Mobile App',
           'Identity Provider', 'Archivlösung', 'Schnittstelle ERP', 'Monitoring', 'Website Redesign']
  risks = ['Schnittstelle zum Kernsystem ist nicht dokumentiert; Integrationsaufwand schwer abschätzbar.',
           'Veraltete Drittbibliotheken sind nicht kompatibel und müssen ersetzt werden.',
           'Schlüsselperson beim Kunden fällt längere Zeit aus.',
           'Fixpreis bei unklaren Anforderungen.']
  chances = ['Folgeauftrag für Betrieb wahrscheinlich.', 'Wiederverwendung der Komponenten in weiteren Projekten.']
  measures = ["Technischen Spike vor Sprint 3 durchführen\nChange Request für Mehraufwand vorbereiten",
              'Abhängigkeitsanalyse erstellen', 'Stellvertretung definieren', nil, '']

  orders = names.each_with_index.map do |name, i|
    status = statuses[i % 4 == 3 ? 2 : i % 2]
    { id: i + 1, label: "#{%w[KPR MIG OPS DAT MOB IDP ARC ERP MON WEB][i]}-#{100 + i}: #{name}",
      client: %w[Kunde\ A Kunde\ B Kunde\ C][i % 3], responsible: people[i % people.size],
      department: departments[i % departments.size], status: status[0], closed: status[1] }
  end
  uncertainties = orders.first(8).flat_map do |order|
    Array.new(rand(1..3)) do
      chance = rand < 0.3
      { order_id: order[:id], type: chance ? 'chance' : 'risk', name: (chance ? chances : risks).sample,
        probability: rand(1..4), impact: rand(1..4), measure: measures.sample, updated_at: '2026-09-15' }
    end
  end
else
  conn = ActiveRecord::Base.connection
  orders = conn.exec_query(<<~SQL).map do |r|
    SELECT o.id,
           wi.path_shortnames || ': ' || wi.name AS label,
           split_part(wi.path_names, E'\\n', 1) AS client,
           TRIM(COALESCE(e.firstname, '') || ' ' || COALESCE(e.lastname, '')) AS responsible,
           d.name AS department,
           s.name AS status,
           COALESCE(s.closed, false) AS closed
    FROM orders o
    JOIN work_items wi ON wi.id = o.work_item_id
    LEFT JOIN employees e ON e.id = o.responsible_id
    LEFT JOIN departments d ON d.id = o.department_id
    LEFT JOIN order_statuses s ON s.id = o.status_id
    ORDER BY wi.path_shortnames
  SQL
    r.symbolize_keys
  end

  uncertainties = OrderUncertainty.order(:order_id, :id).map do |u|
    { order_id: u.order_id, type: u.is_a?(OrderChance) ? 'chance' : 'risk', name: u.name,
      probability: u.probability_value, impact: u.impact_value, measure: u.measure,
      updated_at: u.updated_at.to_date.to_s }
  end
end

data = { orders: orders, uncertainties: uncertainties,
         thresholds: { medium: OrderUncertainty::MEDIUM_THRESHOLD, high: OrderUncertainty::HIGH_THRESHOLD } }

File.write(HTML_PATH, <<~HTML)
  <!doctype html>
  <html lang="de">
  <head>
  <meta charset="utf-8">
  <title>Chancen &amp; Risiken – Stand #{STAND}</title>
  <style>
    @import url('https://fonts.googleapis.com/css?family=Roboto:300,400,500');
    :root {
      --bg: #ffffff; --surface: #ffffff; --text: #4a4a4a; --muted: #6b6b6b;
      --border: #d8d8d8; --header-bg: #f5f5f5; --hover-row: #e9f0f8;
      --accent: #1a73a8; --accent-dark: #1e5a96; --accent-contrast: #ffffff; --wordmark: #1e5a96;
      --risk: #f0ad4e; --chance: #61b44b; --high: #a82824; --high-bg: #fbe3e2;
      --medium-bg: #fcf0dc; --low-bg: #e6f2e2; --empty: #e2e2e2;
      --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1b1f24; --surface: #22262c; --text: #e4e4e2; --muted: #9a9a9a;
        --border: #383d44; --header-bg: #282d34; --hover-row: #24344a;
        --accent: #3fa8e0; --accent-dark: #238bca; --accent-contrast: #0d1310; --wordmark: #3fa8e0;
        --risk: #f4bd6e; --chance: #7cc766; --high: #f08a86; --high-bg: #4a2624;
        --medium-bg: #47391f; --low-bg: #26391f; --empty: #3a3f46;
        --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
      }
    }
    :root[data-theme="dark"] {
      --bg: #1b1f24; --surface: #22262c; --text: #e4e4e2; --muted: #9a9a9a;
      --border: #383d44; --header-bg: #282d34; --hover-row: #24344a;
      --accent: #3fa8e0; --accent-dark: #238bca; --accent-contrast: #0d1310; --wordmark: #3fa8e0;
      --risk: #f4bd6e; --chance: #7cc766; --high: #f08a86; --high-bg: #4a2624;
      --medium-bg: #47391f; --low-bg: #26391f; --empty: #3a3f46;
      --shadow: 0 1px 2px rgba(0, 0, 0, 0.35);
    }
    :root[data-theme="light"] {
      --bg: #ffffff; --surface: #ffffff; --text: #4a4a4a; --muted: #6b6b6b;
      --border: #d8d8d8; --header-bg: #f5f5f5; --hover-row: #e9f0f8;
      --accent: #1a73a8; --accent-dark: #1e5a96; --accent-contrast: #ffffff; --wordmark: #1e5a96;
      --risk: #f0ad4e; --chance: #61b44b; --high: #a82824; --high-bg: #fbe3e2;
      --medium-bg: #fcf0dc; --low-bg: #e6f2e2; --empty: #e2e2e2;
      --shadow: 0 1px 2px rgba(74, 74, 74, 0.08);
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
    .wordmark { font-size: 0.72rem; font-weight: 500; text-transform: uppercase; letter-spacing: 0.1em; color: var(--wordmark); }
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
    .stats { display: flex; flex-wrap: wrap; gap: 1px; background: var(--border); border: 1px solid var(--border); overflow: hidden; }
    .stat { flex: 1 1 160px; background: var(--surface); padding: 0.9rem 1.1rem; }
    .stat .label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    .stat .value { font-size: 1.4rem; font-weight: 500; font-variant-numeric: tabular-nums; margin-top: 0.15rem; }
    .stat .value small { font-size: 0.9rem; font-weight: 300; color: var(--muted); }
    .filters {
      display: flex; flex-wrap: wrap; align-items: end; gap: 1.25rem;
      background: var(--header-bg); border: 1px solid var(--border); padding: 0.9rem 1.1rem;
    }
    .field { display: flex; flex-direction: column; gap: 0.3rem; }
    .field label { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
    select {
      font: inherit; font-size: 0.9rem; color: var(--text); background: var(--surface);
      border: 1px solid var(--border); border-radius: 3px; padding: 0.4rem 0.6rem; min-width: 10rem;
    }
    #order { max-width: 22rem; }
    .spacer { flex: 1; }
    button {
      font: inherit; font-size: 0.85rem; font-weight: 500; color: var(--accent-contrast);
      background: var(--accent); border: 1px solid var(--accent); border-radius: 3px;
      padding: 0.4rem 0.85rem; cursor: pointer;
    }
    button:hover { background: var(--accent-dark); border-color: var(--accent-dark); }
    button:focus-visible, select:focus-visible, .table-scroll:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    section.card { background: var(--surface); border: 1px solid var(--border); padding: 1.1rem 1.25rem 1.4rem; }
    .card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.75rem; gap: 1rem; }
    .card-head h2 { font-size: 1rem; font-weight: 500; margin: 0; }
    .card-head .hint { font-size: 0.8rem; color: var(--muted); margin-top: 0.2rem; }
    .table-scroll { overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; font-size: 0.9rem; }
    th, td { padding: 10px 15px; text-align: left; vertical-align: top; }
    th { font-weight: 400; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em; color: var(--muted); background: var(--header-bg); vertical-align: middle; }
    th[data-sort] { cursor: pointer; user-select: none; }
    th[data-sort]:hover { color: var(--text); }
    th[data-sort]:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    th[aria-sort="ascending"]::after { content: " ▲"; }
    th[aria-sort="descending"]::after { content: " ▼"; }
    td { border-bottom: 1px solid var(--border); }
    td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }
    td.nowrap { white-space: nowrap; }
    td.measure, td.desc { white-space: pre-line; min-width: 14rem; }
    .muted { color: var(--muted); }
    .sub { display: block; font-size: 0.78rem; color: var(--muted); margin-top: 0.15rem; }
    body.fixed-width header, body.fixed-width .content { max-width: 80rem; margin-left: auto; margin-right: auto; width: 100%; }
    tbody tr:hover { background: var(--hover-row); }
    .dot { display: inline-block; width: 0.55em; height: 0.55em; border-radius: 50%; margin-right: 0.4em; }
    .dot.risk { background: var(--risk); }
    .dot.chance { background: var(--chance); }
    .bar { display: inline-flex; gap: 3px; margin-bottom: 0.2rem; }
    .bar i { display: block; width: 14px; height: 5px; background: var(--empty); }
    .bar.risk i.on { background: var(--risk); }
    .bar.chance i.on { background: var(--chance); }
    .badge { display: inline-block; padding: 0.1rem 0.45rem; border-radius: 3px; font-size: 0.82rem; font-weight: 400; white-space: nowrap; font-variant-numeric: tabular-nums; }
    .badge.high { background: var(--high-bg); color: var(--high); }
    .badge.medium { background: var(--medium-bg); }
    .badge.low { background: var(--low-bg); }
    .gap { color: var(--high); font-weight: 400; }
  </style>
  </head>
  <body class="fixed-width">
  <header>
    <div class="header-row">
      <div>
        <div class="wordmark">PuzzleTime</div>
        <h1>Chancen &amp; Risiken</h1>
        <div class="period">Auftragsübergreifende Übersicht · Stand #{STAND} · Stärke = Eintrittswahrscheinlichkeit × Auswirkung</div>
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

  <main class="content">
  <div class="stats" id="stats"></div>

  <div class="filters">
    <div class="field">
      <label for="status">Auftragsstatus</label>
      <select id="status">
        <option value="open">Offene Aufträge</option>
        <option value="">Alle</option>
      </select>
    </div>
    <div class="field">
      <label for="order">Auftrag</label>
      <select id="order"><option value="">Alle</option></select>
    </div>
    <div class="field">
      <label for="type">Typ</label>
      <select id="type">
        <option value="">Alle</option>
        <option value="risk">Risiken</option>
        <option value="chance">Chancen</option>
      </select>
    </div>
    <div class="field">
      <label for="strength">Stärke</label>
      <select id="strength">
        <option value="">Alle</option>
        <option value="high">gross</option>
        <option value="medium">mittel</option>
        <option value="low">gering</option>
      </select>
    </div>
    <div class="field">
      <label for="measure">Massnahmen</label>
      <select id="measure">
        <option value="">Alle</option>
        <option value="with">Mit Massnahmen</option>
        <option value="without">Ohne Massnahmen</option>
      </select>
    </div>
    <div class="spacer"></div>
    <button id="download-source">Quelldaten (CSV)</button>
  </div>

  <section class="card">
    <div class="card-head">
      <div>
        <h2 id="entries-title">Chancen und Risiken pro Auftrag</h2>
        <div class="hint">Klick auf eine Spaltenüberschrift sortiert die Tabelle.</div>
      </div>
      <button id="download-entries">CSV</button>
    </div>
    <div class="table-scroll" tabindex="0" role="region" aria-labelledby="entries-title">
      <table id="entries">
        <thead><tr>
          <th data-sort="order">Auftrag</th>
          <th data-sort="type">Typ</th>
          <th data-sort="name">Beschreibung</th>
          <th data-sort="probability">Eintritts&shy;wahrscheinlichkeit</th>
          <th data-sort="impact">Auswirkung</th>
          <th data-sort="strength">Stärke</th>
          <th data-sort="measure">Massnahmen</th>
          <th data-sort="updated_at">Geändert</th>
        </tr></thead>
        <tbody></tbody>
      </table>
    </div>
  </section>

  <section class="card">
    <div class="card-head">
      <div>
        <h2 id="coverage-title">Abdeckung pro Auftrag</h2>
        <div class="hint">Aufträge ohne erfasste Chancen/Risiken oder ohne Massnahmen. Klick auf eine Spaltenüberschrift sortiert die Tabelle.</div>
      </div>
      <div class="field">
        <select id="coverage" aria-label="Abdeckung">
          <option value="">Alle Aufträge</option>
          <option value="gaps">Nur Lücken</option>
          <option value="none">Ohne Chancen/Risiken</option>
          <option value="unmeasured">Mit Einträgen ohne Massnahmen</option>
        </select>
      </div>
      <button id="download-coverage">CSV</button>
    </div>
    <div class="table-scroll" tabindex="0" role="region" aria-labelledby="coverage-title">
      <table id="coverage-table">
        <thead><tr>
          <th data-sort="order">Auftrag</th><th data-sort="responsible">Verantwortlich</th>
          <th data-sort="department">Organisationseinheit</th><th data-sort="status">Status</th>
          <th class="num" data-sort="risks">Risiken</th><th class="num" data-sort="chances">Chancen</th>
          <th class="num" data-sort="unmeasured">Ohne Massnahmen</th><th data-sort="finding">Befund</th>
        </tr></thead>
        <tbody></tbody>
      </table>
    </div>
  </section>
  </main>

  <script>
  const data = #{data.to_json};
  const PROBABILITY = { 1: 'unwahrscheinlich', 2: 'gering', 3: 'mittel', 4: 'gross' };
  const IMPACT = { 1: 'keine', 2: 'gering', 3: 'mittel', 4: 'gross' };
  const STRENGTH = { low: 'gering', medium: 'mittel', high: 'gross' };
  const TYPE = { risk: 'Risiko', chance: 'Chance' };

  const ordersById = Object.fromEntries(data.orders.map(o => [o.id, o]));
  const entries = data.uncertainties.map(u => {
    const value = u.probability * u.impact;
    const strength = value < data.thresholds.medium ? 'low' : value < data.thresholds.high ? 'medium' : 'high';
    return { ...u, order: ordersById[u.order_id], value, strength, hasMeasure: !!(u.measure && u.measure.trim()) };
  }).filter(e => e.order);

  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const bar = (n, type) => `<span class="bar ${type}">${[1, 2, 3, 4].map(i => `<i class="${i <= n ? 'on' : ''}"></i>`).join('')}</span>`;

  function downloadCsv(rows, header, filename) {
    const csv = [header, ...rows].map(r => r.map(v => `"${String(v ?? '').replace(/"/g, '""')}"`).join(',')).join('\\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob(['\\ufeff' + csv], { type: 'text/csv' }));
    a.download = filename;
    a.click();
    URL.revokeObjectURL(a.href);
  }

  const $ = id => document.getElementById(id);
  const orderSelect = $('order');

  function visibleOrders() {
    return data.orders.filter(o => !$('status').value || !o.closed);
  }

  function fillOrderSelect() {
    const current = orderSelect.value;
    orderSelect.innerHTML = '<option value="">Alle</option>' + visibleOrders()
      .map(o => `<option value="${o.id}">${esc(o.label)}</option>`).join('');
    if ([...orderSelect.options].some(opt => opt.value === current)) orderSelect.value = current;
  }

  // Per table: column key -> [value getter, sort descending on first click]
  const sorters = {
    entries: {
      order: [e => e.order.label], type: [e => TYPE[e.type]], name: [e => e.name],
      probability: [e => e.probability, true], impact: [e => e.impact, true], strength: [e => e.value, true],
      measure: [e => e.hasMeasure ? e.measure.trim() : ''], updated_at: [e => e.updated_at, true]
    },
    coverage: {
      order: [c => c.o.label], responsible: [c => c.o.responsible], department: [c => c.o.department],
      status: [c => c.o.status], risks: [c => c.risks, true], chances: [c => c.chances, true],
      unmeasured: [c => c.unmeasured, true],
      // orders without any entries first, then by number of entries without measures
      finding: [c => (c.total === 0 ? 1e6 : 0) + c.unmeasured, true]
    }
  };
  const sorts = { entries: { key: 'strength', desc: true }, coverage: { key: 'finding', desc: true } };

  function sortRows(rows, table, tiebreak) {
    const { key, desc } = sorts[table];
    const get = sorters[table][key][0];
    return rows.sort((a, b) => {
      const x = get(a), y = get(b);
      const cmp = typeof x === 'number' ? x - y : String(x ?? '').localeCompare(String(y ?? ''), 'de');
      return (desc ? -cmp : cmp) || tiebreak(a, b);
    });
  }

  function markSorted(tableId, table) {
    document.querySelectorAll(`#${tableId} th[data-sort]`).forEach(th => {
      if (th.dataset.sort === sorts[table].key) th.setAttribute('aria-sort', sorts[table].desc ? 'descending' : 'ascending');
      else th.removeAttribute('aria-sort');
    });
  }

  let currentEntries = [];
  let currentCoverage = [];

  function render() {
    const orders = visibleOrders().filter(o => !orderSelect.value || String(o.id) === orderSelect.value);
    const orderIds = new Set(orders.map(o => o.id));
    const inScope = entries.filter(e => orderIds.has(e.order_id));

    const rows = inScope.filter(e =>
      (!$('type').value || e.type === $('type').value) &&
      (!$('strength').value || e.strength === $('strength').value) &&
      (!$('measure').value || e.hasMeasure === ($('measure').value === 'with'))
    );
    currentEntries = sortRows(rows, 'entries', (a, b) => a.order.label.localeCompare(b.order.label, 'de') || b.value - a.value);
    markSorted('entries', 'entries');

    document.querySelector('#entries tbody').innerHTML = rows.length ? rows.map(e => `<tr>
        <td>${esc(e.order.label)}<span class="sub">${esc(e.order.client)} · ${esc(e.order.responsible)}</span></td>
        <td class="nowrap"><span class="dot ${e.type}"></span>${TYPE[e.type]}</td>
        <td class="desc">${esc(e.name)}</td>
        <td class="nowrap">${bar(e.probability, e.type)}<span class="sub">${e.probability} · ${PROBABILITY[e.probability]}</span></td>
        <td class="nowrap">${bar(e.impact, e.type)}<span class="sub">${e.impact} · ${IMPACT[e.impact]}</span></td>
        <td><span class="badge ${e.strength}">${e.value} · ${STRENGTH[e.strength]}</span></td>
        <td class="measure">${e.hasMeasure ? esc(e.measure.trim()) : '<span class="gap">keine Massnahme erfasst</span>'}</td>
        <td class="nowrap muted">${esc(e.updated_at)}</td>
      </tr>`).join('') : '<tr><td colspan="8" class="muted">Keine Einträge für diese Filter.</td></tr>';

    const coverage = orders.map(o => {
      const own = inScope.filter(e => e.order_id === o.id);
      const risks = own.filter(e => e.type === 'risk').length;
      const chances = own.filter(e => e.type === 'chance').length;
      const unmeasured = own.filter(e => !e.hasMeasure).length;
      const finding = own.length === 0 ? 'keine Chancen/Risiken erfasst'
        : unmeasured ? `${unmeasured} von ${own.length} ohne Massnahme` : '';
      return { o, risks, chances, unmeasured, total: own.length, finding };
    });
    const cov = $('coverage').value;
    currentCoverage = sortRows(coverage.filter(c =>
      cov === '' ||
      (cov === 'gaps' && c.finding) ||
      (cov === 'none' && c.total === 0) ||
      (cov === 'unmeasured' && c.total > 0 && c.unmeasured > 0)
    ), 'coverage', (a, b) => a.o.label.localeCompare(b.o.label, 'de'));
    markSorted('coverage-table', 'coverage');
    document.querySelector('#coverage-table tbody').innerHTML = currentCoverage.length ? currentCoverage.map(c => `<tr>
        <td>${esc(c.o.label)}<span class="sub">${esc(c.o.client)}</span></td>
        <td>${esc(c.o.responsible)}</td>
        <td>${esc(c.o.department)}</td>
        <td>${esc(c.o.status)}</td>
        <td class="num">${c.risks}</td>
        <td class="num">${c.chances}</td>
        <td class="num">${c.unmeasured}</td>
        <td>${c.finding ? `<span class="gap">${esc(c.finding)}</span>` : '<span class="muted">vollständig</span>'}</td>
      </tr>`).join('') : '<tr><td colspan="8" class="muted">Keine Aufträge für diese Filter.</td></tr>';

    const risks = inScope.filter(e => e.type === 'risk').length;
    const withMeasure = inScope.filter(e => e.hasMeasure).length;
    const ordersWithout = coverage.filter(c => c.total === 0).length;
    $('stats').innerHTML = `
      <div class="stat"><div class="label">Aufträge</div><div class="value">${orders.length}</div></div>
      <div class="stat"><div class="label">Einträge</div><div class="value">${inScope.length}</div></div>
      <div class="stat"><div class="label"><span class="dot risk"></span>Risiken</div><div class="value">${risks}</div></div>
      <div class="stat"><div class="label"><span class="dot chance"></span>Chancen</div><div class="value">${inScope.length - risks}</div></div>
      <div class="stat"><div class="label">Stärke gross</div><div class="value">${inScope.filter(e => e.strength === 'high').length}</div></div>
      <div class="stat"><div class="label">Mit Massnahmen</div><div class="value">${withMeasure} <small>/ ${inScope.length}</small></div></div>
      <div class="stat"><div class="label">Aufträge ohne C/R</div><div class="value">${ordersWithout} <small>/ ${orders.length}</small></div></div>
    `;
  }

  $('status').addEventListener('change', () => { fillOrderSelect(); render(); });
  ['order', 'type', 'strength', 'measure', 'coverage'].forEach(id => $(id).addEventListener('change', render));
  [['entries', 'entries'], ['coverage-table', 'coverage']].forEach(([tableId, table]) => {
    document.querySelectorAll(`#${tableId} th[data-sort]`).forEach(th => {
      th.tabIndex = 0;
      const toggle = () => {
        const key = th.dataset.sort;
        sorts[table] = sorts[table].key === key ? { key, desc: !sorts[table].desc } : { key, desc: !!sorters[table][key][1] };
        render();
      };
      th.addEventListener('click', toggle);
      th.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
      });
    });
  });
  $('fixed-width').addEventListener('change', e => document.body.classList.toggle('fixed-width', e.target.checked));

  $('download-source').addEventListener('click', () => downloadCsv(
    entries.map(e => [e.order.label, e.order.client, e.order.responsible, e.order.department, e.order.status,
                      TYPE[e.type], e.name, e.probability, e.impact, e.value, STRENGTH[e.strength], e.measure, e.updated_at]),
    ['auftrag', 'kunde', 'verantwortlich', 'organisationseinheit', 'status', 'typ', 'beschreibung',
     'eintrittswahrscheinlichkeit', 'auswirkung', 'staerke_wert', 'staerke', 'massnahmen', 'geaendert'],
    'chancen_risiken_quelldaten.csv'));
  $('download-entries').addEventListener('click', () => downloadCsv(
    currentEntries.map(e => [e.order.label, TYPE[e.type], e.name, PROBABILITY[e.probability], IMPACT[e.impact],
                             e.value, STRENGTH[e.strength], e.measure, e.updated_at]),
    ['auftrag', 'typ', 'beschreibung', 'eintrittswahrscheinlichkeit', 'auswirkung', 'staerke_wert', 'staerke', 'massnahmen', 'geaendert'],
    'chancen_risiken.csv'));
  $('download-coverage').addEventListener('click', () => downloadCsv(
    currentCoverage.map(c => [c.o.label, c.o.responsible, c.o.department, c.o.status, c.risks, c.chances, c.unmeasured, c.finding]),
    ['auftrag', 'verantwortlich', 'organisationseinheit', 'status', 'risiken', 'chancen', 'ohne_massnahmen', 'befund'],
    'chancen_risiken_abdeckung.csv'));

  fillOrderSelect();
  render();
  </script>
  </body>
  </html>
HTML

puts "Wrote #{HTML_PATH} (#{orders.size} orders, #{uncertainties.size} chances/risks embedded)"
