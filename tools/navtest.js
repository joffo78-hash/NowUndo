const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 420, height: 900 } });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message)); pg.on('console', m => { if (m.type()==='error') errs.push(m.text()); });
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', body:
    'window.SENT=[];function wwr_req(x){SENT.push(decodeURIComponent(x))};function wwr_start(){};function wwr_req_recur(){};' }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  const A="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let w=''; for(let k=0;k<100;k++) w+=A[Math.round(Math.abs(Math.sin(k*0.37))*Math.exp(-(k%25)/12)*61)];
  const fast='0,1,3,42.5,0.2,0.8,0.3,0.6,13,0.25,1.0,0.5,96000,1,0.8;1,1,2,10,0,1,0,0.2,0,0,1,0,48000,2,1;2,0,0,0,0,1,0,0,0,0,1,0,0,1,1;3,1,2,60,0,1,0.1,0.4,0,1,1,0,48000,1,1';
  await pg.evaluate(([f,wv]) => { wwr_onreply('EXTSTATE\tnowundo_tw\tlv_wave\t'+wv+'\n'); wwr_onreply('EXTSTATE\tnowundo_tw\tlv_fast\t'+f+'\n'); }, [fast,[w,w,'',w,'','','',''].join('|')]);
  console.log('nav visible on LP view:', await pg.isVisible('#nav2'));
  await pg.click('#lv-sel button >> nth=3');   // L4 depuis l'onglet Launchpad
  await pg.waitForTimeout(80);
  console.log('view loopers active:', await pg.isVisible('#view-loopers'), 'title', await pg.textContent('#lv-title'));
  await pg.click('#lv-sel button >> nth=0');
  await pg.waitForTimeout(80);
  await pg.screenshot({ path: 'lv2.png', fullPage: true });
  await pg.click('.lv-btn:text-is("REC / DUB")'); await pg.click('.lv-btn:text-is("BEAT REPEAT")');
  await pg.locator('.lv-sl input').nth(0).fill('1.2');
  await pg.click('#nav-tw button >> nth=4');   // Twister page 5
  await pg.waitForTimeout(150);
  console.log('view twister active:', await pg.isVisible('#view-twister'), 'nav sel:', await pg.textContent('#nav-tw button.sel'));
  await pg.screenshot({ path: 'tw3.png' });
  console.log((await pg.evaluate(() => SENT)).filter(x => x.includes('web_cmd')).join('\n'));
  console.log('errors', errs);
  await b.close();
})();
