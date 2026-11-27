const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 420, height: 900 } });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message));
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', body:
    'window.SENT=[];function wwr_req(x){SENT.push(decodeURIComponent(x))};function wwr_start(){};function wwr_req_recur(){};' }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  let fr=[]; for(let r=0;r<=8;r++)for(let c=1;c<=9;c++){ if(r==0&&c==9)continue; fr.push(r+','+c+':'+(r*20+c*9).toString(16).padStart(2,'0')+'8040:i'); }
  await pg.evaluate(f => { wwr_onreply('EXTSTATE\tnowundo_vl\tweb_frame\t'+f+'\nEXTSTATE\tnowundo_vl\tweb_tick\t12.3\nEXTSTATE\tnowundo_vl\tweb_meta\tpage=4;layer=rp1;hold=0;layers=rp1=a Rushes;band=1,2g.1,3t\nEXTSTATE\tnowundo_vl\tweb_status\tOK\n'); }, fr.join('|'));
  await pg.waitForTimeout(200);
  await pg.screenshot({ path: 'tools/bands.png' });
  console.log('bands', JSON.stringify(await pg.evaluate(() => [...document.querySelectorAll('.pad.band-t,.pad.band-g')].map(e => e.className))));
  const p = pg.locator('.pad').nth(20);
  await p.dispatchEvent('pointerdown',{pointerId:1,isPrimary:true,button:0}); await p.dispatchEvent('pointerup',{pointerId:1,isPrimary:true,button:0});
  await pg.waitForTimeout(100);
  console.log((await pg.evaluate(() => SENT)).filter(x => x.includes('web_cmd')).join('\n'));
  console.log('grid', JSON.stringify(await pg.locator('#lp-grid').boundingBox()), 'errors', errs);
  await b.close();
})();
