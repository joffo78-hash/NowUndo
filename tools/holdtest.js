const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 420, height: 900 } });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message));
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', body:
    'window.SENT=[];function wwr_req(x){x=decodeURIComponent(x);var m=x.match(/web_cmd\\/(.*)$/);if(m)SENT.push(m[1])};function wwr_start(){};function wwr_req_recur(){};' }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  const tap = async (r,c) => { const p = pg.locator(`.pad[data-row="${r}"][data-col="${c}"]`); await p.dispatchEvent('pointerdown',{pointerId:1,isPrimary:true,button:0}); await p.dispatchEvent('pointerup',{pointerId:1,isPrimary:true,button:0}); await pg.waitForTimeout(60); };
  await pg.click('#btn-hold'); await pg.waitForTimeout(60);
  await tap(6,9); console.log('aide :', await pg.textContent('#lp-help'));
  await tap(0,3); await tap(0,5); await tap(6,9);
  await pg.waitForTimeout(200);
  const last = (await pg.evaluate(() => SENT)).pop();
  console.log(last.split(';').slice(1).map(x => x.split(':')[1]).join(' '));
  console.log('errors', errs);
  await b.close(); process.exit(0);
})();
