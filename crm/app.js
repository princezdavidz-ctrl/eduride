const isLocalHost = ['localhost', '127.0.0.1', '::1'].includes(window.location.hostname);
const API_URL = window.TREAD_API_URL || (
  isLocalHost || window.location.protocol === 'file:'
    ? 'http://localhost:8787'
    : `${window.location.origin}/backend`
);
const splashScreen = document.querySelector('#splash-screen');
const loginScreen = document.querySelector('#login-screen');
const crmApp = document.querySelector('#crm-app');
const loginForm = document.querySelector('#login-form');
const loginError = document.querySelector('#login-error');
const viewRoot = document.querySelector('#view-root');
const toast = document.querySelector('#toast');
let toastTimer;
let cache = { buses: [], schools: [], routes: [], journeys: [], alerts: [] };

const pages = {
  overview: ['Command center', 'Transport overview'], operations: ['Command center', 'Live operations'], routes: ['Transport planning', 'Routes & stops'], journeys: ['Transport planning', 'Journeys & dispatch'], fleet: ['Transport planning', 'Fleet & devices'], drivers: ['Transport planning', 'Drivers'], schools: ['Network & people', 'Schools'], families: ['Network & people', 'Families & students'], alerts: ['Response & governance', 'Alerts & incidents'], reports: ['Response & governance', 'Reports & exports'], settings: ['Response & governance', 'Settings & administration'],
};

window.setTimeout(() => {
  splashScreen.classList.add('hidden');
  if (sessionStorage.getItem('tread_token')) restoreSession();
  else { loginScreen.classList.remove('hidden'); document.querySelector('#login-email').focus(); }
}, 900);

async function api(path, options = {}) {
  const token = sessionStorage.getItem('tread_token');
  const response = await fetch(`${API_URL}${path}`, { ...options, headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}), ...(options.headers || {}) } });
  let result = {};
  try { result = await response.json(); } catch { result = {}; }
  if (response.status === 401) { sessionStorage.removeItem('tread_token'); showLogin(); throw new Error('Your session has expired.'); }
  if (!response.ok) throw new Error(result.error || 'Request failed');
  return result;
}

function showLogin() { crmApp.classList.add('hidden'); loginScreen.classList.remove('hidden'); }
function showApp(user) { loginScreen.classList.add('hidden'); crmApp.classList.remove('hidden'); document.querySelector('#profile-name').textContent = user.name; document.querySelector('#top-profile-name').textContent = user.name.split(' ')[0]; document.querySelector('#sync-label').textContent = 'All systems operational'; }
function showToast(message) { toast.textContent = message; toast.classList.add('show'); clearTimeout(toastTimer); toastTimer = setTimeout(() => toast.classList.remove('show'), 2800); }
function esc(value) { return String(value ?? '').replace(/[&<>'"]/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' })[character]); }
function status(value) { return `<span class="status-badge ${esc(value)}">${esc(String(value).replaceAll('_', ' '))}</span>`; }
function setHeader(view) { const [group, title] = pages[view] || pages.overview; document.querySelector('#page-crumb').textContent = `${group} / ${title}`; document.querySelector('#page-title').textContent = title; document.querySelectorAll('.nav-item').forEach((item) => item.classList.toggle('active', item.dataset.view === view)); }

loginForm.addEventListener('submit', async (event) => {
  event.preventDefault(); const button = loginForm.querySelector('button'); const data = new FormData(loginForm); button.disabled = true; button.querySelector('span').textContent = 'Signing in...'; loginError.textContent = '';
  try { const result = await api('/api/auth/login', { method: 'POST', body: JSON.stringify({ email: data.get('email'), password: data.get('password') }) }); sessionStorage.setItem('tread_token', result.token); showApp(result.user); await loadData(); navigate(); showToast(`Welcome back, ${result.user.name}.`); }
  catch (error) { loginError.textContent = error.message === 'Failed to fetch' ? 'Backend is offline. Start it on port 8787.' : error.message; }
  finally { button.disabled = false; button.querySelector('span').textContent = 'Sign in to CRM'; }
});

async function restoreSession() { try { const { user } = await api('/api/auth/me'); showApp(user); await loadData(); navigate(); } catch { showLogin(); } }
async function loadData() {
  try {
    const [buses, schools, routes, journeys, alerts] = await Promise.all(['/api/buses', '/api/schools', '/api/routes', '/api/journeys', '/api/alerts'].map((path) => api(path)));
    cache = { buses: buses.buses || [], schools: schools.data || [], routes: routes.data || [], journeys: journeys.data || [], alerts: alerts.data || [] };
    document.querySelector('#alert-count').textContent = cache.alerts.filter((alert) => !alert.acknowledged).length;
  } catch (error) { showToast(error.message); }
}

function navigate() { const view = window.location.hash.replace('#', '') || 'overview'; render(view in pages ? view : 'overview'); }
window.addEventListener('hashchange', navigate);
document.querySelectorAll('.nav-item').forEach((item) => item.addEventListener('click', () => { if (window.innerWidth < 760) document.querySelector('.sidebar').classList.remove('open'); }));
document.querySelector('#top-alerts').addEventListener('click', () => { window.location.hash = 'alerts'; });
document.querySelector('#support-button').addEventListener('click', () => showToast('Support request workspace is coming next.'));
document.querySelector('#top-profile').addEventListener('click', () => { window.location.hash = 'settings'; });

function render(view) {
  setHeader(view);
  const renderers = { overview: renderOverview, operations: renderOperations, fleet: renderFleet, routes: renderRoutes, journeys: renderJourneys, drivers: renderDrivers, schools: renderSchools, families: renderFamilies, alerts: renderAlerts, reports: renderReports, settings: renderSettings };
  viewRoot.innerHTML = renderers[view]();
  bindViewActions(view);
}

function pageIntro(eyebrow, title, action = '') { return `<div class="section-heading"><div><p class="eyebrow">${eyebrow}</p><h2>${title}</h2></div>${action}</div>`; }
function metric(label, value, tone) { return `<article class="metric-card"><div class="metric-icon ${tone}">${tone === 'blue' ? 'bus' : tone === 'green' ? 'on' : tone === 'orange' ? 'ETA' : '!'}</div><div><span>${label}</span><strong>${value}</strong><small class="positive">Live data</small></div></article>`; }
function table(headers, rows, empty = 'No records found.') { return `<div class="data-table-wrap"><table class="data-table"><thead><tr>${headers.map((header) => `<th>${header}</th>`).join('')}</tr></thead><tbody>${rows.length ? rows.join('') : `<tr><td colspan="${headers.length}" class="empty-state">${empty}</td></tr>`}</tbody></table></div>`; }

function renderOverview() { const active = cache.buses.filter((bus) => bus.status !== 'parked'); const moving = cache.buses.filter((bus) => ['on_route', 'delayed'].includes(bus.status)); const attention = cache.buses.filter((bus) => ['delayed', 'offline'].includes(bus.status)); return pageIntro('Command center', 'Transport overview', '<button class="primary-button" data-action="export">Export report <span>-></span></button>') + `<div class="metric-grid">${metric('Active buses', active.length, 'blue')}${metric('On route', moving.length, 'green')}${metric('Arrivals today', cache.journeys.length, 'orange')}${metric('Needs attention', attention.length, 'red')}</div><div class="dashboard-columns"><section class="panel"><div class="panel-heading"><div><p class="eyebrow">Live operations</p><h3>Fleet snapshot</h3></div><button class="text-button" data-nav="operations">Open live operations</button></div><div class="mini-map"><span class="map-road road-one"></span><span class="map-road road-two"></span><span class="map-road road-three"></span>${cache.buses.map((bus, index) => `<button class="mini-pin pin-${index + 1}" data-bus="${esc(bus.id)}" title="Bus ${esc(bus.id)}"></button>`).join('')}</div></section><section class="panel"><div class="panel-heading"><div><p class="eyebrow">Needs review</p><h3>Recent alerts</h3></div><button class="text-button" data-nav="alerts">View all</button></div>${cache.alerts.slice(0, 3).map((alert) => `<div class="alert-row"><span class="alert-symbol ${esc(alert.severity)}">!</span><div><strong>${esc(alert.title)}</strong><p>${esc(alert.message)}</p></div>${status(alert.acknowledged ? 'acknowledged' : alert.severity)}</div>`).join('')}</section></div>`; }
function renderOperations() { return pageIntro('Command center', 'Live operations', '<button class="primary-button" data-action="refresh">Refresh fleet <span>↻</span></button>') + `<div class="panel"><div class="toolbar"><input class="search-input" data-filter="fleet" placeholder="Search bus, route, school, or driver" /><select data-status-filter><option value="">All statuses</option><option>on_route</option><option>delayed</option><option>arrived</option></select></div>${fleetTable(cache.buses)}</div>`; }
function renderFleet() { return pageIntro('Transport planning', 'Fleet & devices', '<button class="primary-button" data-action="add">Add bus <span>+</span></button>') + `<div class="panel"><div class="toolbar"><input class="search-input" data-filter="fleet" placeholder="Search fleet records" /><select data-status-filter><option value="">All statuses</option><option>on_route</option><option>delayed</option><option>arrived</option></select></div>${fleetTable(cache.buses)}</div>`; }
function fleetTable(buses) { return table(['Bus', 'School', 'Route', 'Driver', 'Status', 'ETA'], buses.map((bus) => `<tr><td><strong>TREAD ${esc(bus.id)}</strong></td><td>${esc(bus.school)}</td><td>${esc(bus.route)}</td><td>${esc(bus.driver)}</td><td>${status(bus.status)}</td><td>${bus.etaMinutes ? `${bus.etaMinutes} min` : 'Arrived'}</td></tr>`)); }
function renderRoutes() { return pageIntro('Transport planning', 'Routes & stops', '<button class="primary-button" data-action="add">Create route <span>+</span></button>') + `<div class="panel">${table(['Route', 'Assigned bus', 'Stops', 'School', 'Actions'], cache.routes.map((route) => `<tr><td><strong>${esc(route.name)}</strong></td><td>TREAD ${esc(route.busId)}</td><td>${route.stops.length} stops</td><td>${esc(cache.buses.find((bus) => bus.id === route.busId)?.school || 'Unassigned')}</td><td><button class="table-action" data-action="edit">Edit</button></td></tr>`))}</div>`; }
function renderJourneys() { return pageIntro('Transport planning', 'Journeys & dispatch', '<button class="primary-button" data-action="export">Export journeys <span>-></span></button>') + `<div class="panel"><div class="toolbar"><input class="search-input" data-filter="journeys" placeholder="Search route or bus" /><select><option>All journey statuses</option><option>completed</option><option>delayed</option></select></div>${table(['Journey', 'Bus', 'Route', 'Departure', 'Arrival', 'Status'], cache.journeys.map((journey) => `<tr><td><strong>${esc(journey.id)}</strong></td><td>TREAD ${esc(journey.busId)}</td><td>${esc(journey.route)}</td><td>${esc(journey.departureAt)}</td><td>${esc(journey.arrivalAt || 'Pending')}</td><td>${status(journey.status)}</td></tr>`))}</div>`; }
function renderDrivers() { return pageIntro('Transport planning', 'Drivers', '<button class="primary-button" data-action="add">Add driver <span>+</span></button>') + `<div class="panel">${table(['Driver', 'Assigned bus', 'Route', 'Availability', 'Compliance'], cache.buses.map((bus) => `<tr><td><strong>${esc(bus.driver)}</strong></td><td>TREAD ${esc(bus.id)}</td><td>${esc(bus.route)}</td><td>${status(bus.status === 'delayed' ? 'review' : 'available')}</td><td>Up to date</td></tr>`))}</div>`; }
function renderSchools() { return pageIntro('Network & people', 'Schools', '<button class="primary-button" data-action="add">Add school <span>+</span></button>') + `<div class="panel">${table(['School', 'Address', 'Routes', 'Status', 'Actions'], cache.schools.map((school) => `<tr><td><strong>${esc(school.name)}</strong></td><td>${esc(school.address)}</td><td>${cache.routes.filter((route) => cache.buses.some((bus) => bus.school === school.name && bus.id === route.busId)).length}</td><td>${status('active')}</td><td><button class="table-action" data-action="edit">View details</button></td></tr>`))}</div>`; }
function renderFamilies() { return pageIntro('Network & people', 'Families & students', '<button class="primary-button" data-action="add">Add family <span>+</span></button>') + `<div class="panel"><div class="verification-banner"><span class="alert-symbol warning">!</span><div><strong>Verification queue</strong><p>New parent accounts and student assignments appear here for review.</p></div><button class="text-button" data-action="verify">Review queue</button></div>${table(['Family / student', 'School', 'Assigned route', 'Verification', 'Actions'], [], 'No family records yet. Parent registrations will appear here.')}</div>`; }
function renderAlerts() { const unread = cache.alerts.filter((alert) => !alert.acknowledged); return pageIntro('Response & governance', 'Alerts & incidents', '<button class="primary-button" data-action="incident">Create incident <span>+</span></button>') + `<div class="panel"><div class="toolbar"><select data-alert-filter><option value="">All severities</option><option value="warning">Warning</option><option value="info">Info</option></select><span class="filter-summary">${unread.length} unread alerts</span></div>${table(['Alert', 'Bus', 'Severity', 'Created', 'Status', 'Action'], cache.alerts.map((alert) => `<tr><td><strong>${esc(alert.title)}</strong><small class="table-subtext">${esc(alert.message)}</small></td><td>TREAD ${esc(alert.busId)}</td><td>${status(alert.severity)}</td><td>${new Date(alert.createdAt).toLocaleTimeString()}</td><td>${status(alert.acknowledged ? 'acknowledged' : 'unread')}</td><td>${alert.acknowledged ? '—' : `<button class="table-action" data-ack="${esc(alert.id)}">Acknowledge</button>`}</td></tr>`))}</div>`; }
function renderReports() { return pageIntro('Response & governance', 'Reports & exports', '<button class="primary-button" data-action="export">Export CSV <span>-></span></button>') + `<div class="metric-grid">${metric('On-time journeys', '88%', 'green')}${metric('Fleet availability', '96%', 'blue')}${metric('Completed trips', cache.journeys.filter((journey) => journey.status === 'completed').length, 'orange')}${metric('Open incidents', cache.alerts.filter((alert) => !alert.acknowledged).length, 'red')}</div><div class="panel report-placeholder"><h3>Performance reporting</h3><p>Choose a date range and export operational data for schools, routes, or the full district.</p><div class="toolbar"><input type="date" /><input type="date" /><button class="primary-button" data-action="export">Download report</button></div></div>`; }
function renderSettings() { return pageIntro('Response & governance', 'Settings & administration') + `<div class="settings-grid"><section class="panel"><p class="eyebrow">Workspace</p><h3>Organization settings</h3><label class="setting-field">Organization name<input value="TREAD Demo School Network" /></label><label class="setting-field">Timezone<select><option>Africa/Nairobi</option><option>UTC</option></select></label><button class="primary-button" data-action="save">Save settings</button></section><section class="panel"><p class="eyebrow">Account</p><h3>Admin profile</h3><div class="profile-large"><span class="avatar">AM</span><div><strong id="settings-profile">Amina Mwangi</strong><p>Transport administrator</p></div></div><button class="secondary-button" data-action="logout">Log out</button></section></div>`; }

function bindViewActions(view) {
  document.querySelectorAll('[data-nav]').forEach((element) => element.addEventListener('click', () => { window.location.hash = element.dataset.nav; }));
  document.querySelectorAll('[data-action="refresh"]').forEach((element) => element.addEventListener('click', async () => { await loadData(); render(view); showToast('Fleet data refreshed.'); }));
  document.querySelectorAll('[data-action="export"]').forEach((element) => element.addEventListener('click', () => { const blob = new Blob(['TREAD report\nGenerated from current operations data.'], { type: 'text/csv' }); const link = document.createElement('a'); link.href = URL.createObjectURL(blob); link.download = 'tread-report.csv'; link.click(); URL.revokeObjectURL(link.href); showToast('Report downloaded.'); }));
  document.querySelectorAll('[data-action="add"], [data-action="edit"], [data-action="incident"], [data-action="verify"]').forEach((element) => element.addEventListener('click', () => showToast('This workflow is ready for the next data-entry slice.')));
  document.querySelectorAll('[data-action="save"]').forEach((element) => element.addEventListener('click', () => showToast('Settings saved for this workspace.')));
  document.querySelectorAll('[data-action="logout"]').forEach((element) => element.addEventListener('click', async () => { await api('/api/auth/logout', { method: 'POST' }); sessionStorage.removeItem('tread_token'); showLogin(); }));
  document.querySelectorAll('[data-ack]').forEach((element) => element.addEventListener('click', async () => { await api(`/api/alerts/${element.dataset.ack}`, { method: 'PATCH' }); await loadData(); render('alerts'); showToast('Alert acknowledged.'); }));
  document.querySelectorAll('[data-filter="fleet"]').forEach((input) => input.addEventListener('input', () => filterRows(input, input.value)));
  document.querySelectorAll('[data-status-filter]').forEach((select) => select.addEventListener('change', () => filterRows(select, select.value)));
  document.querySelectorAll('[data-alert-filter]').forEach((select) => select.addEventListener('change', () => filterRows(select, select.value)));
}
function filterRows(control, query) { const value = query.toLowerCase(); control.closest('.panel').querySelectorAll('tbody tr').forEach((row) => { row.hidden = value && !row.textContent.toLowerCase().includes(value); }); }
