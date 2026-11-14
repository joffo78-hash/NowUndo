const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 420, height: 900 }, deviceScaleFactor: 1 });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message));
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', body:
    'window.SENT=[];function wwr_req(x){SENT.push(decodeURIComponent(x))};function wwr_start(){};function wwr_req_recur(){};' }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  await pg.click('button[data-view=loopers]');
  const A="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let w=''; for(let k=0;k<100;k++) w+=A[Math.round(Math.abs(Math.sin(k*0.37))*Math.exp(-(k%25)/12)*61)];
  const waves=[w,w,'','','','','',''].join('|');
  const fast='0,1,3,42.5,0.2,0.8,0.3,0.6,13,0.25,1.0,0.5,96000,1;1,1,2,10,0,1,0,0.2,0,0,1,0,48000,2;2,0,0,0,0,1,0,0,0,0,1,0,0,1';
  await pg.evaluate(([f,wv]) => { window.wwr_onreply('EXTSTATE\tnowundo_tw\tlv_wave\t'+wv+'\n'); window.wwr_onreply('EXTSTATE\tnowundo_tw\tlv_fast\t'+f+'\n'); }, [fast,waves]);
  await pg.waitForTimeout(100);
  await pg.screenshot({ path: 'lv1.png', fullPage: true });
  const c = await pg.locator('#lv-wave').boundingBox();
  await pg.mouse.move(c.x + c.width*0.2, c.y + c.height/2); await pg.mouse.down();
  await pg.mouse.move(c.x + c.width*0.35, c.y + c.height/2, {steps:5}); await pg.mouse.up();
  await pg.mouse.move(c.x + c.width*0.6, c.y + c.height/2); await pg.mouse.down();
  await pg.mouse.move(c.x + c.width*0.5, c.y + c.height/2, {steps:5}); await pg.mouse.up();
  await pg.click('.lv-btn:text-is("REVERSE")'); await pg.click('.lv-btn:text-is("CLOUD")');
  await pg.locator('.lv-sl input').nth(1).fill('1.5');
  await pg.waitForTimeout(150);
  console.log((await pg.evaluate(() => SENT)).filter(x => x.includes('web_cmd')).join('\n'));
  console.log('errors', errs);
  await b.close();
})();
