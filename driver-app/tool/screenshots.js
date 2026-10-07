// Captures a screenshot of every screen listed in lib/routes.dart.
//
// Usage (from driver-app/):
//   flutter build web --release --no-web-resources-cdn --dart-define=SCREENSHOT_MODE=true
//   node tool/screenshots.js build/web ../screenshots/driver
//
// Needs Playwright with Chromium (npm i -D playwright && npx playwright install chromium).
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const [webDir = 'build/web', outDir = '../screenshots/driver', only] = process.argv.slice(2);

const routesSource = fs.readFileSync(path.join(__dirname, '..', 'lib', 'routes.dart'), 'utf8');
const screens = [...routesSource.matchAll(/ScreenEntry\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)'/g)]
  .map(([, id, title, route]) => ({ id, title, route }))
  .filter((s) => !only || s.id === only || s.route === only);

const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.css': 'text/css', '.bin': 'application/octet-stream',
};

function serve(root) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let file = path.join(root, decodeURIComponent(req.url.split('?')[0]));
      if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
      if (!fs.existsSync(file)) { res.writeHead(404); return res.end(); }
      res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

function fileName({ id, title }) {
  const [section, rest] = id.split('.');
  const num = rest.replace(/^(\d+)/, (n) => n.padStart(2, '0'));
  const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  return `${section.padStart(2, '0')}-${num}-${slug}.png`;
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const server = await serve(path.resolve(webDir));
  const base = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    locale: 'en-GB',
  });
  const failures = [];
  for (const s of screens) {
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
    await page.goto(`${base}/#${s.route}`);
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    await page.waitForTimeout(2500);
    const out = path.join(outDir, fileName(s));
    await page.screenshot({ path: out });
    if (errors.length) failures.push(`${s.id} ${s.route}: ${errors.join(' | ')}`);
    console.log(`${s.id.padEnd(6)} ${out}`);
    await page.close();
  }
  await browser.close();
  server.close();
  if (failures.length) {
    console.error('\nErrors while capturing:\n' + failures.join('\n'));
    process.exit(1);
  }
})();
