const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  for (const mode of ['old','new']) {
  const pg = await b.newPage({ viewport: { width: 420, height: 900 } });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message));
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', body:
    'window.SLOT="";function wwr_req(x){x=decodeURIComponent(x);var m=x.match(/^SET\\/EXTSTATE\\/nowundo_vl\\/web_cmd\\/(.*)$/);if(m)SLOT=m[1]};function wwr_start(){};function wwr_req_recur(){};' }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  await pg.evaluate((mode) => {
    window.DONE=[]; const acks={}; let last='';
    setInterval(() => {
      const raw=SLOT; if(!raw) return; SLOT="";
      if (mode==='old') { if(raw===last) return; last=raw; raw.split(';').forEach(it=>{ if(/^\w+,/.test(it)) DONE.push(it); }); return; }
      const sid=(raw.match(/^@(\w+);/)||[])[1];
      if(!sid){ raw.split(';').forEach(it=>DONE.push(it)); return; }
      let a=acks[sid]||0;
      raw.split(';').forEach(it=>{const m=it.match(/^#(\d+):(.*)$/); if(m&&+m[1]>a){a=+m[1];DONE.push(m[2]);}});
      acks[sid]=a; wwr_onreply('EXTSTATE\tnowundo_vl\tweb_ack\t'+sid+':'+a+'\n');
    },60);
  }, mode);
  const pads = pg.locator('.pad');
  for (let k=0;k<3;k++){ const p=pads.nth(10+k); await p.dispatchEvent('pointerdown',{pointerId:1,isPrimary:true,button:0}); await p.dispatchEvent('pointerup',{pointerId:1,isPrimary:true,button:0}); }
  await pg.waitForTimeout(2000);
  const p=pads.nth(30); await p.dispatchEvent('pointerdown',{pointerId:1,isPrimary:true,button:0}); await p.dispatchEvent('pointerup',{pointerId:1,isPrimary:true,button:0});
  await pg.waitForTimeout(500);
  console.log(mode, await pg.evaluate(()=>DONE.join(' ')), '| help:', await pg.textContent('#lp-help'), errs);
  await pg.close(); }
  await b.close();
})();
