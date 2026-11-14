var g_wwr_timer_freq=100;
var g_wwr_req_list = "", g_wwr_req_recur = new Array(), g_wwr_req = null, g_wwr_timer = null, g_wwr_timer2 = null;
function wwr_run_update() {
  g_wwr_timer = null;
  if (!g_wwr_req) {
    var str = g_wwr_req_list;
    g_wwr_req_list = "";
    g_wwr_timer2 = null;
    var d = (new Date).getTime();
    for (var x = 0; x < g_wwr_req_recur.length; x++) {
      if (g_wwr_req_recur[x][2] < d) { g_wwr_req_recur[x][2] = d + g_wwr_req_recur[x][1]; str += g_wwr_req_recur[x][0] + ";"; }
    }
    if (str != "") {
      g_wwr_req = new XMLHttpRequest();
      g_wwr_req.onreadystatechange = function() {
        if (g_wwr_req.readyState == 4) {
          if (g_wwr_req.responseText != "") wwr_onreply(g_wwr_req.responseText, d);
          g_wwr_req = null;
        }
      };
      g_wwr_req.open("GET", "/_/" + str, true);
      g_wwr_req.send(null);
    }
  }
  if (g_wwr_timer2 != null) { clearTimeout(g_wwr_timer2); g_wwr_timer2 = null; }
  g_wwr_timer = window.setTimeout(wwr_run_update, g_wwr_timer_freq);
}
function wwr_start() { wwr_run_update(); }
function wwr_req(name) {
  g_wwr_req_list += name + ";";
  if (g_wwr_timer2 == null) {
    g_wwr_timer2 = window.setTimeout(function() { g_wwr_timer2 = null; if (g_wwr_timer != null) { clearTimeout(g_wwr_timer); g_wwr_timer = null; } wwr_run_update(); }, 0);
  }
}
function wwr_req_recur(name, interval) { g_wwr_req_recur.push([name, interval, 0]); }
