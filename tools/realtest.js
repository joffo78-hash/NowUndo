const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 420, height: 900 } });
  const errs=[]; pg.on('pageerror', e => errs.push(e.message));
  const ES = {}; const got = []; let acks = {};
  const A="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let w=''; for(let k=0;k<100;k++) w+=A[k%62];
  let fr=[]; for(let r=0;r<=8;r++)for(let c=1;c<=9;c++){ if(r==0&&c==9)continue; fr.push(r+','+c+':FF0000:i'); }
  Object.assign(ES, {'nowundo_vl/web_frame': fr.join('|'), 'nowundo_vl/web_meta':'page=1;layer=fx;hold=0;layers=fx=FX', 'nowundo_vl/web_status':'ok',
    'nowundo_tw/lv_fast':'0,1,2,40,0,1,0.1,0.2,0,1,1,0,48000,1,1;1,0,0,0,0,1,0,0,0,1,1,0,0,1,1', 'nowundo_tw/lv_wave':[w,'','','','','','',''].join('|'),
    'nowundo_tw/tw_page':'3', 'nowundo_tw/tw_state':'', 'nowundo_tw/tw_knobs':''});
  // "Lua" : lit web_cmd toutes les 50 ms
  setInterval(() => {
    const raw = ES['nowundo_vl/web_cmd']; if (!raw) return; ES['nowundo_vl/web_cmd'] = '';
    const sid=(raw.match(/^@(\w+);/)||[])[1];
    let a = sid ? (acks[sid]||0) : 0;
    raw.split(';').forEach(it => { if (sid) { const m=it.match(/^#(\d+):(.*)$/); if(m&&+m[1]>a){a=+m[1]; got.push(m[2]);} } else if (/^\w+,/.test(it)) got.push(it); });
    if (sid) { acks[sid]=a; ES['nowundo_vl/web_ack']=sid+':'+a; }
    const t = ES['nowundo_tw/web_cmd']; if (t) { got.push('TW:'+t); ES['nowundo_tw/web_cmd']=''; }
  }, 50);
  setInterval(() => { const t = ES['nowundo_tw/web_cmd']; if (t) { got.push('TW:'+t); ES['nowundo_tw/web_cmd']=''; } }, 30);
  await pg.route('http://x/_/**', r => {
    const path = decodeURI(new URL(r.request().url()).pathname.slice(3));
    let out = '';
    path.split(';').forEach(q => {
      if (!q) return;
      const p = q.split('/');
      if (p[0]==='SET' && p[1]==='EXTSTATE') ES[p[2]+'/'+p[3]] = decodeURIComponent(p.slice(4).join('/'));
      else if (p[0]==='GET' && p[1]==='EXTSTATE') { const v = ES[p[2]+'/'+p[3]] || ''; out += 'EXTSTATE\t'+p[2]+'\t'+p[3]+'\t'+v+'\n'; }
    });
    r.fulfill({ contentType: 'text/plain', body: out });
  });
  await pg.route('**/main.js', r => r.fulfill({ contentType: 'text/javascript', path: require('path').join(__dirname, 'reaper_main.js') }));
  await pg.route('http://x/NowUndo.html', r => r.fulfill({ contentType: 'text/html', path: require('path').join(__dirname, '../NowUndo/Scripts/V3.21/NowUndo.html') }));
  await pg.goto('http://x/NowUndo.html');
  await pg.waitForTimeout(800);
  const p = pg.locator('.pad').nth(20);
  await p.dispatchEvent('pointerdown',{pointerId:1,isPrimary:true,button:0}); await p.dispatchEvent('pointerup',{pointerId:1,isPrimary:true,button:0});
  await pg.click('#lv-sel button >> nth=0'); await pg.waitForTimeout(400);
  await pg.click('.lv-btn:text-is("REVERSE")'); await pg.waitForTimeout(300);
  await pg.click('#nav-tw button >> nth=4'); await pg.waitForTimeout(500);
  console.log(got.join('\n')); console.log('errors', errs);
  await b.close(); process.exit(0);
})();
