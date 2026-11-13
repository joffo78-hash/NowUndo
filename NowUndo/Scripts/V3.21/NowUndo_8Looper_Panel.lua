-- @description NowUndo 8 Looper Panel - compact dashboard
-- @version 1.3
-- @author OpenAI
-- Base: DashBoard_slices_test.lua / NowUndo V3.7

local MAX_INST = 8
local HEADER_H = 42
local ROW_BASE_H = 150
local CARD_FONT_LABEL = 9
local CARD_FONT_VALUE = 14
local CARD_H = 32
local CARD_GAP = 3
local last_mouse_down = false
local clr_all_press_time = 0
local clr_all_long_pressed = 0
local DASH_BASE = 6000
local SLICE_GMEM_BASE = 100000
local SLICE_GMEM_STRIDE = 259
local SLICE_GMEM_MAX = 256
local PARAM_GMEM_BASE = 110000
local PARAM_GMEM_STRIDE = 60
local PARAM_DEFAULTS = {
  [1]=1,
  [2]=0,
  [3]=1,
  [4]=80,
  [5]=10,
  [6]=0,
  [7]=0,
  [8]=2,
  [9]=0,
  [10]=0.15,
  [11]=120,
  [12]=25,
  [13]=5,
  [14]=3,
  [15]=150,
  [16]=0,
  [17]=0,
  [18]=1,
  [19]=1,
  [20]=0,
  [21]=1,
  [22]=0,
  [23]=0,
  [24]=0,
  [25]=0.5,
  [26]=0,
  [27]=0.1,
  [28]=100,
  [29]=2,
  [30]=0,
  [31]=0,
  [32]=3,
  [33]=0,
  [34]=0,
  [35]=1,
  [36]=1,
  [37]=50,
  [38]=0,
  [39]=1,
  [40]=0,
  [41]=0,
  [42]=48,
  [43]=0,
  [44]=0,
  [45]=0,
  [46]=0,
  [47]=8,
  [48]=16,
  [49]=1,
  [50]=0.002,
  [51]=120,
  [52]=25,
  [53]=6,
  [54]=6,
  [57]=0
}
local PARAMS = {
 {1,"Speed","%.2f","pink"},{2,"Pitch","%+.1f st","pink"},
 {3,"Mix","%.0f%%","red",function(v)return v*100 end},
 {4,"Grain","%.0f ms","pink"},{5,"Fade","%.0f ms","green"},
 {6,"Play mode","%s","pink",function(v)return ({[0]="Normal",[1]="Slicer",[2]="One-shot"})[math.floor(v+0.5)] or tostring(v) end},
 {7,"Link P/S","%s","pink",function(v)return v>0.5 and "ON" or "OFF" end},
 {10,"Auto seuil","%.2f","yellow"},{11,"Auto maintien","%.0f ms","yellow"},
 {12,"Grain fade","%.0f%%","pink"},{13,"Mode slicer","%.0f","yellow"},
 {14,"Slicer rate","%.0f","yellow"},{15,"Decay slice","%.0f ms","yellow"},
 {16,"Reverse","%s","pink",function(v)return v>0.5 and "ON" or "OFF" end},
 {17,"Ping-pong","%s","pink",function(v)return v>0.5 and "ON" or "OFF" end},
 {18,"Feedback","%.2f","red"},{19,"Degrade","%.0f%%","red",function(v)return v*100 end},
 {20,"Largeur stéréo","%.0f%%","red",function(v)return v*100 end},
 {21,"Output vol","%.0f%%","red",function(v)return v*100 end},
 {23,"Cloud","%s","blue",function(v)return v>0.5 and "ON" or "OFF" end},
 {24,"Loop quant","%.0f","green"},{25,"Density","%.0f%%","blue",function(v)return v*100 end},
 {26,"Chaos","%.0f%%","blue",function(v)return v*100 end},{27,"Spread","%.0f%%","blue",function(v)return v*100 end},
 {28,"Densité REC","%.0f%%","green"},{29,"Durée densité","%.0f","green"},{30,"Loop beats","%.0f","green"},
 {31,"Slice source","%.0f","yellow"},{32,"Grid sub","%.0f","yellow"},
 {33,"Pitch slicer","%.0f%%","yellow"},{34,"Pitch cloud","%.0f%%","blue"},
 {35,"Cloud mix","%.0f%%","blue",function(v)return v*100 end},{36,"Mode pos cloud","%.0f","blue"},
 {37,"Cloud pos","%.0f%%","blue"},{38,"LFO shape","%.0f","blue"},
 {39,"Vitesse LFO","%.2f Hz","blue"},{40,"Profondeur LFO","%.0f%%","blue"},
 {42,"Root note","%.0f","neutral"},{43,"Pitch mode","%.0f","neutral"},
 {44,"Release sampler","%.0f ms","neutral"},{46,"Slicer clock","%.0f","yellow"},
 {47,"Steps","%.0f","yellow"},{48,"Max slices","%.0f","yellow"},
 {49,"Slice preset","%.0f","yellow"},{50,"Seuil détection","%.3f","yellow"},
 {51,"Maintien détec.","%.0f ms","yellow"},{52,"Dub grain","%.1f ms","red"},
 {53,"Dub align","%.1f ms","red"},{54,"Read align","%.1f ms","red"},
 {57,"Slicer link","%s","yellow",function(v)return v>0.5 and "ON" or "OFF" end}
}
-- Code couleur : playback = rose, slicer = jaune, region in/out = vert,
-- cloud = bleu, output = rouge.
local COLOR_OF = {}
for _,id in ipairs{1,2,4,6,7,12,16,17,42,43,44,54} do COLOR_OF[id]="pink" end
for _,id in ipairs{3,18,19,20,21,52,53} do COLOR_OF[id]="red" end
for _,id in ipairs{5,24,28,29,30} do COLOR_OF[id]="green" end
for _,id in ipairs{10,11,13,14,15,31,32,33,46,47,48,49,50,51,57} do COLOR_OF[id]="yellow" end
for _,id in ipairs{23,25,26,27,34,35,36,37,38,39,40} do COLOR_OF[id]="blue" end
for _,d in ipairs(PARAMS) do d[4]=COLOR_OF[d[1]] or d[4] end
local COLORS = {
 pink={0.48,0.20,0.40,1, 0.95,0.55,0.82},
 red={0.46,0.16,0.16,1, 0.95,0.40,0.38},
 yellow={0.43,0.36,0.10,1, 0.98,0.83,0.22},
 blue={0.12,0.30,0.45,1, 0.35,0.70,1.00},
 green={0.12,0.36,0.23,1, 0.32,0.88,0.52},
 neutral={0.25,0.27,0.30,1, 0.75,0.78,0.82}
}
local GROUP_RGB = {{1,.25,.25},{.23,.48,1},{.19,.88,.38},{.88,.25,1}}

-- Same docking/position persistence system as the existing Dashboard.
local NDDOCK={}
function NDDOCK.init(title,ext,dw,dh)
  local function ld(k,d) return tonumber(reaper.GetExtState(ext,k)) or d end
  NDDOCK.ext,NDDOCK.last_t,NDDOCK.sig=ext,0,""
  local w,h=ld("w",dw),ld("h",dh)
  if w<300 then w=dw end; if h<250 then h=dh end
  gfx.init(title,w,h,ld("dock",0),ld("x",100),ld("y",100))
end
function NDDOCK.tick()
  local t=reaper.time_precise(); if t-NDDOCK.last_t<1 then return end; NDDOCK.last_t=t
  local d,x,y,w,h=gfx.dock(-1,0,0,0,0); d=math.floor(d or 0)
  local sig=d..","..x..","..y..","..w..","..h; if sig==NDDOCK.sig then return end; NDDOCK.sig=sig
  local e=NDDOCK.ext; reaper.SetExtState(e,"dock",tostring(d),true)
  if (d & 1)==0 then
    reaper.SetExtState(e,"x",tostring(math.floor(x)),true); reaper.SetExtState(e,"y",tostring(math.floor(y)),true)
    reaper.SetExtState(e,"w",tostring(math.floor(w)),true); reaper.SetExtState(e,"h",tostring(math.floor(h)),true)
  end
end

-- Reference values ("BASE"): per-looper snapshot saved in ExtState. A parameter card
-- is shown only when its value differs from the BASE (or from the factory default
-- when no BASE was stored).
local EXT_NS="NowUndo_8Looper_Panel"
local BASE={}
local BASE_VERSION="3.9"   -- change si les valeurs par defaut du JSFX changent : purge les anciennes bases memorisees
local function load_base()
  local purge=(reaper.GetExtState(EXT_NS,"base_ver")~=BASE_VERSION)
  if purge then reaper.SetExtState(EXT_NS,"base_ver",BASE_VERSION,true) end
  for i=0,MAX_INST-1 do
    if purge then reaper.SetExtState(EXT_NS,"base"..i,"",true) end
    BASE[i]={}
    local str=reaper.GetExtState(EXT_NS,"base"..i)
    for id,v in str:gmatch("(%d+)=([%-%d%.eE%+]+)") do BASE[i][tonumber(id)]=tonumber(v) end
  end
end
local function save_base(i)
  local t={}
  for id,v in pairs(BASE[i]) do t[#t+1]=id.."="..string.format("%.6g",v) end
  reaper.SetExtState(EXT_NS,"base"..i,table.concat(t,";"),true)
end
local function default_of(inst,id) return (BASE[inst] and BASE[inst][id]) or PARAM_DEFAULTS[id] or 0 end

local function read(base,off) return reaper.gmem_read(base+off) or 0 end
-- PERF : une police = un slot cree une seule fois (gfx.setfont avec nom/taille recree la police a chaque appel = tres lent)
local FONT_SLOT,FONT_N,CUR_FONT={},9,nil
local function setfont(sz,bold)
  local key=sz*2+(bold and 1 or 0); local slot=FONT_SLOT[key]
  if not slot then
    FONT_N=FONT_N+1; if FONT_N>120 then FONT_N=10; FONT_SLOT={}; CUR_FONT=nil end
    slot=FONT_N; FONT_SLOT[key]=slot; gfx.setfont(slot,"Arial",sz,bold and "b" or ""); CUR_FONT=slot
  elseif CUR_FONT~=slot then gfx.setfont(slot); CUR_FONT=slot end
end
-- PERF : caches (rafraichis ~10-20 Hz au lieu de chaque frame)
local FIT_CACHE,FIT_N={},0      -- resultat de l'ajustement de texte (taille / troncature / largeur)
local CH_CACHE,SL_CACHE,WV_CACHE={},{},{}
local function setc(r,g,b,a) gfx.set(r,g,b,a or 1) end
local function text(x,y,str,size,r,g,b,bold)
  setfont(math.max(7,math.floor(size)),bold)
  setc(r or .88,g or .88,b or .90,1); gfx.x=x; gfx.y=y; gfx.drawstr(tostring(str))
end
local function rect(x,y,w,h,r,g,b,a,fill)
  setc(r,g,b,a); gfx.rect(x,y,w,h,fill==nil and 1 or fill)
end
local function meter(x,y,w,h,val,label,s)
  text(x,y-10*s,label,8*s,.65,.68,.72)
  rect(x,y,w,h,.055,.06,.07,1,1)
  local db=20*math.log(math.max(0.00001,val),10)
  local ratio=math.max(0,math.min(1,(db+48)/48))
  if ratio>0 then
    local mr,mg,mb=.20,.82,.42
    if ratio>.82 then mr,mg,mb=.95,.30,.20 elseif ratio>.62 then mr,mg,mb=.95,.70,.20 end
    rect(x+1,y+1,(w-2)*ratio,h-2,mr,mg,mb,.95,1)
  end
end
local function ftext(x,y,maxw,str,size,r,g,b,bold,minsize,align)
  str=tostring(str); minsize=minsize or 6
  local key=str.."\0"..math.floor(size).."\0"..string.format("%.1f",maxw).."\0"..minsize.."\0"..(bold and 1 or 0)
  local e=FIT_CACHE[key]
  if not e then
    local sz=math.floor(size); setfont(sz,bold)
    while sz>minsize and gfx.measurestr(str)>maxw do sz=sz-1; setfont(sz,bold) end
    local s2=str
    if gfx.measurestr(s2)>maxw then
      while #s2>1 and gfx.measurestr(s2.."..")>maxw do
        s2=s2:sub(1,(utf8.offset(s2,-1) or 2)-1)
      end
      s2=s2..".."
    end
    e={sz,s2,gfx.measurestr(s2)}
    FIT_N=FIT_N+1; if FIT_N>3000 then FIT_CACHE={}; FIT_N=0 end
    FIT_CACHE[key]=e
  end
  setfont(e[1],bold)
  local tw=e[3]
  if align=="center" then x=x+(maxw-tw)*.5 elseif align=="right" then x=x+maxw-tw end
  setc(r or .88,g or .88,b or .90,1); gfx.x=x; gfx.y=y; gfx.drawstr(e[2])
  return e[1],tw
end
local function draw_button(x,y,w,h,label,active,cr,cg,cb,hover,click,base,cmd)
  local hov=gfx.mouse_x>=x and gfx.mouse_x<=x+w and gfx.mouse_y>=y and gfx.mouse_y<=y+h
  if hov and click then reaper.gmem_write(base+48,cmd) end
  rect(x,y,w,h,active and cr or .13,active and cg or .14,active and cb or .17,1,1)
  rect(x,y,w,h,hov and .65 or .28,hov and .68 or .30,hov and .72 or .34,1,0)
  ftext(x+1,y+math.max(2,(h-10)/2),w-2,label,9,.92,.92,.94,true,6,"center")
end
local function fmt_param(def,v)
  if def[5] then return def[5](v) end
  return string.format(def[3],v)
end
-- Parametres deja visibles autrement : plus de carte.
--  7 Link (bouton LNK), 16 Reverse (bouton REV + forme d'onde), 17 Ping-pong (bouton P-P),
--  23 Cloud ON (encart bleu + bouton CLD), Play mode = Slicer (encart jaune + bouton SLI).
local HIDDEN_PARAM={[7]=true,[16]=true,[17]=true,[23]=true}
local function is_hidden(def,v)
  if HIDDEN_PARAM[def[1]] then return true end
  if def[1]==6 and math.floor(v+.5)==1 then return true end
  return false
end
local function is_default(def,v,d)
  if v~=v then return true end                 -- NaN / unpublished
  if math.abs(v-d)<=0.0005 then return true end
  -- Same text on screen as the default => not a visible change (float noise).
  return fmt_param(def,v)==fmt_param(def,d)
end
local function get_changed_params(param_base,inst)
  local out={}
  -- Snapshot valid only if the JSFX published the matching instance / Song Part.
  if read(param_base,59)<0.5 then return out end
  local expected_part = math.floor((param_base-PARAM_GMEM_BASE)/PARAM_GMEM_STRIDE)%3 + 1
  local expected_instance = math.floor((param_base-PARAM_GMEM_BASE)/(3*PARAM_GMEM_STRIDE)) + 1
  if math.floor(read(param_base,57)+0.5) ~= expected_instance then return out end
  if math.floor(read(param_base,58)+0.5) ~= expected_part then return out end
  for _,def in ipairs(PARAMS) do
    local v=read(param_base,def[1]-1)
    local d=default_of(inst,def[1])
    if not is_default(def,v,d) and not is_hidden(def,v) then out[#out+1]={def=def,value=v} end
  end
  return out
end

local SHORT_LABELS={ [3]="MIX",[6]="PLAY MODE",[7]="LINK P/S",[10]="AUTO THR",[11]="AUTO HOLD",[12]="GRAIN FADE",[13]="SLI MODE",[14]="SLI RATE",[15]="SLI DECAY",[18]="FEEDBACK",[19]="DEGRADE",[20]="ST. WIDTH",[21]="OUT VOL",[24]="LOOP QUANT",[25]="DENSITY",[26]="CHAOS",[27]="SPREAD",[28]="REC DENS",[29]="DENS LEN",[30]="LOOP BEATS",[31]="SLI SRC",[32]="GRID SUB",[33]="SLI PITCH",[34]="CLD PITCH",[35]="CLD MIX",[36]="CLD POS MODE",[37]="CLD POS",[38]="LFO SHAPE",[39]="LFO RATE",[40]="LFO DEPTH",[42]="ROOT NOTE",[43]="PITCH MODE",[44]="SMP REL",[46]="SLI CLOCK",[47]="STEPS",[48]="MAX SLICES",[49]="SLI PRESET",[50]="DET THR",[57]="SLI LINK",[51]="DET HOLD",[52]="DUB GRAIN",[53]="DUB ALIGN",[54]="READ ALIGN" }
local function draw_card(x,y,w,h,item)
  local def,v=item.def,item.value; local c=COLORS[def[4]] or COLORS.neutral
  rect(x,y,w,h,c[1]*.55,c[2]*.55,c[3]*.55,1,1)
  rect(x,y,w,h,c[5],c[6],c[7],.75,0)
  rect(x,y,2,h,c[5],c[6],c[7],1,1)
  local label=SHORT_LABELS[def[1]] or string.upper(def[2])
  local tx=x+5; local tw=w-8
  -- Name in the colour of its family, value in bright white to stand out.
  ftext(tx,y+3,tw,label,CARD_FONT_LABEL,c[5],c[6],c[7],true,6)
  ftext(tx,y+14,tw,fmt_param(def,v),CARD_FONT_VALUE,1,1,1,true,8)
end
local function snapshot_base(reset)
  local now_t=reaper.time_precise()
  for i=0,MAX_INST-1 do
    CH_CACHE={}
    if reset then BASE[i]={}; save_base(i)
    else
      local b0=1000+i*600; local ap=math.floor(read(b0,42)+.5)
      if read(b0,0)>0 and (now_t-read(130,i))<=3.0 and ap>=1 and ap<=3 then
        local pb=PARAM_GMEM_BASE+((i*3)+ap-1)*PARAM_GMEM_STRIDE
        if read(pb,59)>=0.5 then
          BASE[i]={}
          for _,def in ipairs(PARAMS) do BASE[i][def[1]]=read(pb,def[1]-1) end
          save_base(i)
        end
      end
    end
  end
end
local HUES={{.82,.22,.22},{.88,.48,.15},{.85,.78,.18},{.22,.78,.34},{.18,.72,.78},{.22,.42,.92},{.68,.30,.88},{.88,.35,.68}}
local DIM=.42   -- looper inactif / stoppe : meme couleur, eteinte
local SEL_LOOPER=0   -- looper selectionne sur le Launchpad (ExtState nowundo_vl/sel_looper)
local function draw_column(inst_idx,x,top,cw,ch,now_t,mouse_click,mouse_down)
  local base0=1000+inst_idx*600
  local active_p=math.floor(read(base0,42)+.5)
  local hb_ok=(now_t-read(130,inst_idx))<=3.0
  local instance_id=read(base0,0)
  local active=instance_id>0 and hb_ok and active_p>=1 and active_p<=3
  rect(x,top,cw,ch-.5,.105,.11,.13,1,1)
  rect(x,top,cw,ch-.5,.25,.27,.30,1,0)
  if not active then
    local hi=math.floor(read(160,inst_idx)+.5); if hi<1 or hi>8 then hi=(inst_idx%8)+1 end
    local c=HUES[hi]
    rect(x,top,cw,ch-.5,.06+c[1]*.07,.06+c[2]*.07,.07+c[3]*.07,1,1)
    rect(x,top,cw,ch-.5,c[1]*.30+.08,c[2]*.30+.08,c[3]*.30+.09,1,0)
    rect(x+4,top+19,cw-8,2,c[1]*DIM,c[2]*DIM,c[3]*DIM,1,1)
    ftext(x+5,top+7,cw-10,"LOOPER "..(inst_idx+1),10,c[1]*.60+.10,c[2]*.60+.10,c[3]*.60+.10,true,6)
    ftext(x+5,top+25,cw-10,"INACTIF",8,c[1]*.45+.10,c[2]*.45+.10,c[3]*.45+.10,false,6)
    return
  end
  local p=active_p-1; local gbase=base0+p*200
  local inst_alias=read(gbase,1); if inst_alias<1 then inst_alias=inst_idx+1 end
  local state=math.floor(read(gbase,2)+.5)
  local length=read(gbase,46); local loop_start=read(gbase,44); local loop_width=read(gbase,45)
  -- V3.10 : sync point exporte par le looper (+182 pos, +183 id ref (9=HOST), +184 longueur ref, +185 ref encore active)
  local sy_pos=read(gbase,182); local sy_id=math.floor(read(gbase,183)+.5); local sy_len=read(gbase,184); local sy_live=read(gbase,185)>.5; local sy_master=read(gbase,187)>.5
  if length<=0 then sy_pos=-1 end
  local hue=math.floor(read(160,inst_idx)+.5); if hue<1 or hue>8 then hue=(inst_idx%8)+1 end
  local part=({"MAIN","CHORUS","BRIDGE"})[p+1]
  local state_name=({[1]="REC",[2]="PLAY",[3]="OVERDUB",[4]="REPLACE",[5]="AUTO-REP",[6]="MULTIPLY",[7]="WAIT",[8]="SYNC"})[state] or "STOP"
  local state_col=({[1]={.92,.20,.22},[2]={.95,.55,.82},[3]={.96,.56,.16},[4]={.80,.80,.86},[5]={.82,.70,.50},[6]={.68,.30,.88},[7]={.95,.58,.18},[8]={.95,.58,.18}})[state] or {.035,.035,.04}
  setfont(8,true); local snw=gfx.measurestr(state_name)
  ftext(x+cw-5-snw,top+6,snw+2,state_name,8,state_col[1],state_col[2],state_col[3],true,8)
  ftext(x+5,top+5,cw-14-snw,"L"..math.floor(inst_alias+.5).." / "..part,9,.94,.94,.96,true,6)
  local hc=HUES[hue] or {.55,.55,.58}
  -- STOP : la waveform reste noire, donc toute la colonne est grisee (sinon elle se confond avec le fond)
  local is_stop=({[1]=1,[2]=1,[3]=1,[4]=1,[5]=1,[6]=1,[7]=1,[8]=1})[state]==nil
  if is_stop then rect(x,top,cw,ch-.5,.07+hc[1]*.07,.07+hc[2]*.07,.08+hc[3]*.07,1,1)
  else rect(x,top,cw,ch-.5,.075+hc[1]*.13,.075+hc[2]*.13,.085+hc[3]*.13,1,1) end     -- fond teinte a la couleur du looper
  rect(x,top,cw,ch-.5,.25,.27,.30,1,0)
  if is_stop then rect(x+4,top+19,cw-8,2,hc[1]*DIM,hc[2]*DIM,hc[3]*DIM,1,1) else rect(x+4,top+19,cw-8,2,hc[1],hc[2],hc[3],1,1) end

  -- Each looper owns a compact horizontal waveform in its own column.
  local wx=x+5; local wy=top+26; local ww=cw-10; local wh=86
  if is_stop then rect(wx,wy,ww,wh,.05+hc[1]*.10,.05+hc[2]*.10,.06+hc[3]*.10,1,1) else rect(wx,wy,ww,wh,.025,.027,.035,1,1) end   -- STOP : fond de forme d'onde gris clair
  local slicer_on=read(gbase,8)==1; local cloud_on=read(gbase,24)>0.5
  if slicer_on then rect(wx-1,wy-1,ww+2,wh+2,.96,.78,.12,1,0) end
  if cloud_on then rect(wx-2,wy-2,ww+4,wh+4,.35,.70,1,1,0) end
  local mid=wy+wh*.5; local step=ww/100
  local wc=(state==2) and {.20,.82,.38} or state_col      -- forme d'onde verte en lecture
  if is_stop then wc={hc[1]*.55,hc[2]*.55,hc[3]*.55} end   -- STOP : couleur du looper, eteinte
  setc(wc[1],wc[2],wc[3],.95)
  local wv=WV_CACHE[inst_idx]
  if not wv or wv.g~=gbase or now_t-wv.t>0.05 then
    wv=wv or {a={}}; wv.t=now_t; wv.g=gbase
    for wi=0,99 do wv.a[wi]=math.min(1,read(gbase,50+wi)) end
    WV_CACHE[inst_idx]=wv
  end
  local wa=wv.a
  for wi=0,99 do
    local hh=wa[wi]*wh*.44
    if hh>=.5 then gfx.line(wx+wi*step,mid-hh,wx+wi*step,mid+hh) end
  end
  if length>0 and loop_width>0 then
    local sb=SLICE_GMEM_BASE+((inst_idx*3)+p)*SLICE_GMEM_STRIDE
    local sc=SL_CACHE[inst_idx]
    if not sc or sc.sb~=sb or now_t-sc.t>0.1 then
      sc=sc or {r={}}; sc.t=now_t; sc.sb=sb
      sc.n=math.max(0,math.min(SLICE_GMEM_MAX,math.floor(read(sb,0)+.5))); sc.es=read(sb,1); sc.ew=read(sb,2)
      for si=0,sc.n-1 do sc.r[si]=read(sb,3+si) end
      SL_CACHE[inst_idx]=sc
    end
    if sc.n>0 and sc.ew>0 and math.abs(sc.es-loop_start)<2 and math.abs(sc.ew-loop_width)<2 then
      setc(1,.83,.12,.40)
      for si=0,sc.n-1 do
        local rel=sc.r[si]; local abspos=loop_start+rel
        if rel>=0 and rel<=loop_width and abspos>=0 and abspos<=length then
          local sx=wx+(abspos/length)*ww; gfx.line(sx,wy+1,sx,wy+wh-1)
        end
      end
    end
    -- V3.10 : SYNC POINT (marqueur rouge pointille) ; repete tous les M samples quand la boucle est plus longue que la reference
    if sy_pos>=0 and sy_id>0 then
      local a=sy_live and 1 or .45; local k=0
      while k<64 and (k==0 or (sy_len>1 and sy_pos+k*sy_len<length)) do
        local sx=wx+((sy_pos+k*sy_len)/length)*ww
        setc(1,.10,.10,k==0 and a or a*.5)
        for yy=wy,wy+wh-1,6 do gfx.line(sx,yy,sx,math.min(yy+3,wy+wh)) end
        if k==0 then gfx.triangle(sx,wy+wh,sx+6,wy+wh,sx,wy+wh-8) end
        k=k+1
      end
    end
    local endpos=math.min(loop_start+loop_width,length)
    setc(.32,.88,.52,1); local ix=wx+(loop_start/length)*ww; gfx.line(ix,wy,ix,wy+wh)
    setc(.55,1,.68,1); local ox=wx+(endpos/length)*ww; gfx.line(ox,wy,ox,wy+wh)
  end
  local pospct=read(gbase,47); local px=wx+math.max(0,math.min(100,pospct))*.01*ww
  setc(.95,.55,.82,1); gfx.line(px,wy,px,wy+wh)

  -- Compact input/output meters immediately below the waveform.
  local my=top+116
  meter(x+5,my,cw-10,5,read(gbase,172),"IN",.75)
  meter(x+5,my+17,cw-10,5,read(gbase,173),"OUT",.75)

  -- Controls in two compact rows; command IDs remain unchanged.
  local labels={{"REC",1,state==1 or state==3 or state==8,.70,.12,.13},{"PLAY",3,state==2,.48,.20,.40},{"CLR",2,false,.35,.10,.12},{"REV",4,read(gbase,17)>0,.48,.20,.40},{"P-P",5,read(gbase,18)>0,.48,.20,.40},
    {"SLI",6,slicer_on,.45,.36,.08},{"CLD",7,cloud_on,.12,.32,.48},{"REP",9,state==4,.38,.38,.44},{"AUT",10,state==5,.45,.36,.22},{"LNK",8,read(gbase,9)>0,.48,.20,.40}}
  local gap=3; local bw=(cw-14)/5; local bh=18
  for k,item in ipairs(labels) do
    local row=math.floor((k-1)/5); local col=(k-1)%5
    draw_button(x+5+col*(bw+1),top+143+row*(bh+3),bw,bh,item[1],item[3],item[4],item[5],item[6],nil,mouse_click,gbase,item[2])
  end

  -- Source and synchronization information stay visible above the parameter cards.
  local ds_i=math.floor(inst_alias+.5); if ds_i<1 or ds_i>8 then ds_i=inst_idx+1 end
  local ds_grp=math.floor(read(DASH_BASE,ds_i)+.5)
  local ds_inm=math.floor(read(DASH_BASE,10+ds_i)+.5); local ds_lm=math.floor(read(DASH_BASE,20+ds_i)+.5)
  local sync_txt,sr,sg,sb2
  if sy_id>0 and sy_master and sy_pos==0 and sy_id%10==inst_idx+1 then
    sync_txt="MASTER  (sync 0.00s)"; sr,sg,sb2=1,.82,.30
  elseif sy_id>0 and sy_pos>=0 then
    local who=(sy_id%10==9) and "HOST" or ("L"..(sy_id%10))
    sync_txt=(sy_master and "MASTER of " or "SLAVE of ")..who
    if sy_len>0 and length>0 then sync_txt=sync_txt.."  x"..string.format("%.2f",length/sy_len) end
    local sy_sr=read(gbase,186); if sy_sr<=0 then sy_sr=44100 end
    sync_txt=sync_txt.."  sync "..string.format("%.2f",sy_pos/sy_sr).."s"
    if sy_live then sr,sg,sb2=.48,.68,.95 else sr,sg,sb2=.90,.62,.25; sync_txt=sync_txt.." (ref changed)" end
  else
    sync_txt="FREE"; sr,sg,sb2=.55,.57,.62
  end
  ftext(x+5,top+187,cw-10,sync_txt,8,sr,sg,sb2,true,6)
  local gc=GROUP_RGB[ds_grp]; if gc then local gw=math.min(cw-10,52); rect(x+5,top+200,gw,12,gc[1]*.35,gc[2]*.35,gc[3]*.35,1,1); ftext(x+7,top+202,gw-4,"GROUP "..ds_grp,8,1,1,1,true,6,"center") end
  local sources={}
  for k=0,7 do if ((ds_inm>>k)&1)==1 then sources[#sources+1]="I"..(k+1) end; if ((ds_lm>>k)&1)==1 then sources[#sources+1]="L"..(k+1) end end
  ftext(x+5,top+216,cw-10,#sources>0 and table.concat(sources," ") or "No source",8,.72,.75,.79,false,6)

  -- Modified parameters are full-width cards stacked vertically so the large
  -- text remains readable in each of the eight looper columns.
  local pb=PARAM_GMEM_BASE+((inst_idx*3)+p)*PARAM_GMEM_STRIDE
  local cc=CH_CACHE[inst_idx]
  if not cc or cc.pb~=pb or now_t-cc.t>0.12 then cc={t=now_t,pb=pb,list=get_changed_params(pb,inst_idx)}; CH_CACHE[inst_idx]=cc end
  local changed=cc.list
  local card_top=top+234; local card_h=CARD_H; local gap=CARD_GAP
  local card_w=(cw-10-gap)/2
  local rows=math.max(0,math.floor((top+ch-4-card_top+gap)/(card_h+gap)))
  local cap=rows*2; local n=#changed
  local shown=n>cap and math.max(0,cap-1) or n
  for i=1,shown do
    local col=(i-1)%2; local row=math.floor((i-1)/2)
    draw_card(x+5+col*(card_w+gap),card_top+row*(card_h+gap),card_w,card_h,changed[i])
  end
  if n>shown and cap>0 then
    local i=cap-1; local col=i%2; local row=math.floor(i/2)
    local mx=x+5+col*(card_w+gap); local my2=card_top+row*(card_h+gap)
    rect(mx,my2,card_w,card_h,.16,.17,.20,1,1); rect(mx,my2,card_w,card_h,.45,.47,.52,1,0)
    ftext(mx+3,my2+9,card_w-6,"+"..(n-shown).." ...",12,.85,.87,.90,true,7,"center")
  end

  -- Contour de colonne (meme code que le Launchpad) :
  --   selectionne = jaune ; membre d'un groupe = couleur du groupe ;
  --   looper selectionne ET groupe = couleur du groupe clignotante (2 Hz, niveau 1.0 / 0.45).
  local is_sel=(SEL_LOOPER==ds_i)
  local ol,thick=nil,2
  if gc then
    local lvl=.85
    if is_sel then lvl=(math.floor(now_t*4)%2==0) and 1.0 or .45; thick=3 end
    ol={gc[1]*lvl,gc[2]*lvl,gc[3]*lvl}
  elseif is_sel then ol={.98,.83,.22}; thick=3 end
  if ol then
    for k=0,thick-1 do rect(x+k,top+k,cw-2*k,ch-.5-2*k,ol[1],ol[2],ol[3],1,0) end
  end
end

-- ===== V3.11 : CHARGEMENT D'UN FICHIER AUDIO (glisser-deposer sur une colonne de looper) =====
-- Le fichier est decode par REAPER (tous formats lisibles), reechantillonne a la frequence du looper, depose dans gmem,
-- puis copie par le looper dans sa boucle ; le looper reste a l'ARRET. S'il n'y a pas de maitre il le devient (comme un 1er REC).
-- Si une synchro est active ET qu'une boucle tourne dans un autre looper, la preference (menu a cote de CLEAR ALL) s'applique :
--   1 ADAPTER (longueur arrondie au multiple du maitre) | 2 INDEPENDANT (longueur d'origine, sans synchro) | 3 ETIRER (reechantillonne a la bonne longueur)
local LD_BASE,LD_MAXN=1000000,3500000
local LD_CHUNK=16384                    -- frames lues par appel a l'accessor
local ENABLE_FILE_DROP=true             -- mettre false pour desactiver completement le glisser-deposer
local LOAD_MODE=math.max(1,math.min(3,math.floor(tonumber(reaper.GetExtState("NowUndo_8Looper_Panel","load_mode")) or 1)))
local LOAD_MODE_NAME={"ADAPTER","INDEPENDANT","ETIRER"}
local LOAD,LOAD_MSG,LOAD_MSG_T=nil,"",0
local COLRECT={}
local function load_msg(m) LOAD_MSG=m; LOAD_MSG_T=reaper.time_precise() end
local function inst_alive(i,now_t) return read(100,i)>0 and (now_t-read(130,i))<=3.0 end
local function inst_block(i)               -- base gmem de la part ACTIVE de l'instance i
  local b0=1000+i*600; local ap=math.floor(read(b0,42)+.5); local pp=(ap>=1 and ap<=3) and (ap-1) or 0
  return b0+pp*200
end
local function load_cleanup(J)
  if J.acc then pcall(reaper.DestroyAudioAccessor,J.acc); J.acc=nil end
  if J.tr then pcall(reaper.DeleteTrack,J.tr); J.tr=nil; J.src=nil
  elseif J.src then pcall(reaper.PCM_Source_Destroy,J.src); J.src=nil end
end
local function start_load(i,path,now_t)
  if LOAD then load_msg("Chargement deja en cours"); return end
  if not inst_alive(i,now_t) then load_msg("Looper "..(i+1).." absent : fichier ignore"); return end
  local src=reaper.PCM_Source_CreateFromFile(path)
  if not src then load_msg("Fichier illisible"); return end
  local D,isqn=reaper.GetMediaSourceLength(src)
  if isqn or not D or D<=0.01 then reaper.PCM_Source_Destroy(src); load_msg("Fichier audio invalide"); return end
  local gb=inst_block(i)
  local sr=read(gb,186); if sr<=0 then sr=reaper.GetSetProjectInfo(0,"PROJECT_SRATE",0,false); if sr<=0 then sr=44100 end end
  local N=math.floor(D*sr+.5)
  local qid=math.floor(reaper.time_precise()*1000)%1000000+1
  LOAD={i=i,gb=gb,src=src,D=D,sr=sr,N=N,qid=qid,phase="query",t0=now_t,name=path:match("[^/\\]+$") or path}
  reaper.gmem_write(LD_BASE+1,N); reaper.gmem_write(LD_BASE+2,qid); reaper.gmem_write(LD_BASE+3,0)
  reaper.gmem_write(gb+49,0); reaper.gmem_write(gb+48,32)          -- cmd 32 : requete de longueur
end
local function load_step(now_t)
  local J=LOAD; if not J then return end
  if J.phase=="query" then
    if read(LD_BASE,3)==J.qid then
      local has_ref=read(LD_BASE,4)>.5; local Nad=math.floor(read(LD_BASE,5)+.5); local cap=math.floor(read(LD_BASE,7)+.5)
      local running=false
      for j=0,MAX_INST-1 do
        if j~=J.i and inst_alive(j,now_t) then
          local jb=inst_block(j); local st=math.floor(read(jb,2)+.5)
          if read(jb,46)>0 and st>=2 and st<=6 then running=true; break end
        end
      end
      local mode=(has_ref and running) and LOAD_MODE or 0       -- 0 = natif (pas de boucle qui tourne en synchro)
      local Nf,refm,stretch=J.N,0,false
      if mode==1 then Nf=Nad; refm=1 elseif mode==3 then Nf=Nad; refm=1; stretch=true end
      if cap>0 and Nf>cap then Nf=cap; load_msg("Fichier tronque a la capacite du looper") end
      J.Nf=Nf; J.ref=refm; J.stretch=stretch; J.mode=mode
      J.nread=stretch and Nf or math.min(J.N,Nf)
      J.phase="read"
    elseif now_t-J.t0>2.0 then
      load_msg("Looper "..(J.i+1).." ne repond pas (JSFX a jour ?)"); load_cleanup(J); LOAD=nil
    end
  elseif J.phase=="read" then
    -- 1) cree la piste / l'item / l'accessor temporaires (rien d'autre dans cette image)
    local ok=pcall(function()
      reaper.PreventUIRefresh(1)
      local n=reaper.CountTracks(0); reaper.InsertTrackAtIndex(n,false); local tr=reaper.GetTrack(0,n); J.tr=tr
      local item=reaper.AddMediaItemToTrack(tr); local take=reaper.AddTakeToMediaItem(item)
      reaper.SetMediaItemTake_Source(take,J.src)               -- la source appartient desormais a la piste temporaire
      reaper.SetMediaItemInfo_Value(item,"D_POSITION",0); reaper.SetMediaItemInfo_Value(item,"D_LENGTH",J.D)
      J.acc=reaper.CreateTakeAudioAccessor(take)
      J.t0=reaper.GetAudioAccessorStartTime(J.acc)
      J.sr_req=J.stretch and (J.Nf/J.D) or J.sr
      J.buf=reaper.new_array(LD_CHUNK*2)
    end)
    pcall(reaper.PreventUIRefresh,-1)
    if not ok or not J.acc or not J.buf then load_cleanup(J); load_msg("Lecture du fichier impossible"); LOAD=nil; return end
    J.k=0; J.phase="stream"
  elseif J.phase=="stream" then
    -- 2) lecture PAR PETITS BLOCS (jamais tout le fichier d'un coup) et ecriture dans gmem
    local t_end=reaper.time_precise()+0.008
    local Lb,Rb=LD_BASE+16,LD_BASE+16+LD_MAXN
    local ok=pcall(function()
      while J.k<J.Nf and reaper.time_precise()<t_end do
        local k=J.k; local n=math.min(LD_CHUNK,J.Nf-k)
        local nr=0
        if k<J.nread then
          nr=math.min(n,J.nread-k)
          reaper.GetAudioAccessorSamples(J.acc,J.sr_req,2,J.t0+k/J.sr_req,nr,J.buf)
        end
        local buf=J.buf
        for f=0,nr-1 do
          reaper.gmem_write(Lb+k+f,buf[2*f+1]); reaper.gmem_write(Rb+k+f,buf[2*f+2])
        end
        for f=nr,n-1 do reaper.gmem_write(Lb+k+f,0); reaper.gmem_write(Rb+k+f,0) end
        J.k=k+n
      end
    end)
    if not ok then load_cleanup(J); load_msg("Lecture du fichier interrompue"); LOAD=nil; return end
    if J.k>=J.Nf then J.buf=nil; J.phase="free_acc" end
  elseif J.phase=="free_acc" then
    -- 3) l'accessor est detruit seul, dans sa propre image
    if J.acc then pcall(reaper.DestroyAudioAccessor,J.acc); J.acc=nil end
    J.phase="free_track"
  elseif J.phase=="free_track" then
    -- 4) puis la piste temporaire (elle detruit aussi la source) dans une autre image
    if J.tr then pcall(reaper.DeleteTrack,J.tr); J.tr=nil; J.src=nil end
    reaper.gmem_write(LD_BASE+8,J.Nf); reaper.gmem_write(LD_BASE+9,J.ref); reaper.gmem_write(LD_BASE+10,0)
    reaper.gmem_write(J.gb+49,0); reaper.gmem_write(J.gb+48,31)   -- cmd 31 : copie dans la boucle
    J.phase="wait"; J.t1=now_t
  elseif J.phase=="wait" then
    if read(LD_BASE,10)==J.qid then
      local how=(J.mode==1) and " (adapte)" or (J.mode==3 and " (etire)" or (J.mode==2 and " (independant)" or ""))
      load_msg(string.format("Looper %d : %s charge, %.2f s%s",J.i+1,J.name,J.Nf/J.sr,how)); LOAD=nil
    elseif now_t-J.t1>30 then
      load_msg("Looper "..(J.i+1).." : chargement non termine"); LOAD=nil
    end
  end
end

local function init()
  reaper.gmem_attach("nowundo_sync")
  NDDOCK.init("NowUndo 8 Looper Panel","NowUndo_8Looper_Panel",1920,1080)
  gfx.clear=0x0D0D11
  load_base()
end

function main()
  local ch=gfx.getchar(); if ch<0 then return end
  NDDOCK.tick()
  local w,h=gfx.w,gfx.h
  local s=math.max(.55,math.min(1.0,w/1180))
  local now_t=reaper.time_precise()
  SEL_LOOPER=math.floor(tonumber(reaper.GetExtState("nowundo_vl","sel_looper")) or 0)
  local mouse_down=(gfx.mouse_cap&1)==1
  local mouse_click=mouse_down and not last_mouse_down
  last_mouse_down=mouse_down
  gfx.mouse_wheel=0 -- navigation by scrolling is deliberately disabled
  rect(0,0,w,h,.055,.06,.075,1,1)
  text(10*s,8*s,"NOWUNDO  /  8 LOOPERS",14*s,.90,.38,.43,true)
  text(10*s,25*s,"Compact control surface  •  3 Song Parts  •  GMEM live",8*s,.53,.55,.60,false)

  -- BASE: store current parameter values as the reference (shift+click = back to factory defaults).
  do
    local bw2=96*s; local bx2=w-124*s-12*s-bw2-8*s; local by2=7*s; local bh2=27*s
    local hv=gfx.mouse_x>=bx2 and gfx.mouse_x<=bx2+bw2 and gfx.mouse_y>=by2 and gfx.mouse_y<=by2+bh2
    rect(bx2,by2,bw2,bh2,hv and .22 or .14,hv and .24 or .15,hv and .30 or .19,1,1)
    rect(bx2,by2,bw2,bh2,.55,.58,.66,1,0)
    ftext(bx2+2,by2+3*s,bw2-4,"SET BASE",11*s,.92,.93,.96,true,7,"center")
    ftext(bx2+2,by2+bh2-10*s,bw2-4,"shift+clic = reset",7*s,.60,.62,.68,false,6,"center")
    if mouse_click and hv then snapshot_base((gfx.mouse_cap&8)==8) end
  end

  -- Global CLEAR ALL, outside every looper; identical short/long press behavior to Dashboard.
  local cw=124*s; local chh=27*s; local cx=w-cw-12*s; local cy=7*s
  local hov=gfx.mouse_x>=cx and gfx.mouse_x<=cx+cw and gfx.mouse_y>=cy and gfx.mouse_y<=cy+chh
  local progress=0
  if clr_all_press_time>0 and mouse_down and hov and clr_all_long_pressed==0 then progress=math.min(1,(now_t-clr_all_press_time)/1.0) end
  rect(cx,cy,cw,chh,hov and .52 or .32,hov and .10 or .07,hov and .13 or .09,1,1)
  if progress>0 then rect(cx,cy,cw*progress,chh,.90,.20,.20,.60,1) end
  rect(cx,cy,cw,chh,.92,.32,.36,1,0)
  text(cx+24*s,cy+7*s,progress>0 and "CLEAR ALL..." or "CLEAR ALL",11*s,1,.91,.92,true)
  if mouse_click and hov then clr_all_press_time=now_t; clr_all_long_pressed=0 end
  if mouse_down and hov and clr_all_long_pressed==0 and clr_all_press_time>0 and now_t-clr_all_press_time>=1.0 then
    clr_all_long_pressed=1
    for i=0,MAX_INST-1 do
      local b0=1000+i*600; local id=read(b0,0); local hb=(now_t-read(130,i))<=3.0
      if id>0 and hb then
        local ap=math.floor(read(b0,42)+.5); local pp=(ap>=1 and ap<=3) and (ap-1) or 0
        reaper.gmem_write(1000+i*600+pp*200+48,11)
      end
    end
  end
  if not mouse_down and hov and clr_all_long_pressed==0 and clr_all_press_time>0 and now_t-clr_all_press_time<1.0 then
    for i=0,MAX_INST-1 do
      local b0=1000+i*600; local id=read(b0,0); local hb=(now_t-read(130,i))<=3.0
      if id>0 and hb then
        local ap=math.floor(read(b0,42)+.5); local pp=(ap>=1 and ap<=3) and (ap-1) or 0
        reaper.gmem_write(1000+i*600+pp*200+48,2)
      end
    end
  end
  if not mouse_down then clr_all_press_time=0 end
  if clr_all_long_pressed==1 and not mouse_down then clr_all_long_pressed=0 end

  -- Preference de chargement de fichier (a cote de CLEAR ALL) : que faire quand une boucle tourne dans un autre looper
  do
    local bw3=150*s; local bx3=w-124*s-12*s-96*s-8*s-bw3-8*s; local by3=7*s; local bh3=27*s
    local hv3=gfx.mouse_x>=bx3 and gfx.mouse_x<=bx3+bw3 and gfx.mouse_y>=by3 and gfx.mouse_y<=by3+bh3
    rect(bx3,by3,bw3,bh3,hv3 and .22 or .14,hv3 and .24 or .15,hv3 and .30 or .19,1,1)
    rect(bx3,by3,bw3,bh3,.55,.58,.66,1,0)
    ftext(bx3+2,by3+3*s,bw3-4,"FICHIER : "..LOAD_MODE_NAME[LOAD_MODE],10*s,.92,.93,.96,true,7,"center")
    ftext(bx3+2,by3+bh3-10*s,bw3-4,"glisser un son sur un looper",7*s,.60,.62,.68,false,6,"center")
    if mouse_click and hv3 then
      local items={"Adapter la longueur (multiple du maitre)","Fichier independant (longueur d'origine)","Etirer a la bonne longueur"}
      items[LOAD_MODE]="!"..items[LOAD_MODE]
      gfx.x=bx3; gfx.y=by3+bh3
      local c=gfx.showmenu(table.concat(items,"|"))
      if c>=1 and c<=3 then LOAD_MODE=c; reaper.SetExtState("NowUndo_8Looper_Panel","load_mode",tostring(c),true) end
    end
  end

  -- Heartbeat cleanup kept from Dashboard.
  for i=0,MAX_INST-1 do
    local hb=read(130,i)
    if read(100,i)>0 and now_t-hb>3.0 then
      reaper.gmem_write(100+i,0); reaper.gmem_write(130+i,0); reaper.gmem_write(160+i,0)
      for pp=0,2 do reaper.gmem_write(1000+i*600+pp*200,0) end
    end
  end

  -- Eight fixed bands always fit in the window. Resizing is the only zoom control.
  local col_top=48*s
  local usable_w=w-18*s
  local col_w=usable_w/MAX_INST
  local col_h=h-col_top-8*s
  for i=0,MAX_INST-1 do
    COLRECT[i]={9*s+i*col_w,col_top,col_w-2*s,col_h}
    draw_column(i,9*s+i*col_w,col_top,col_w-2*s,col_h,now_t,mouse_click,mouse_down)
  end

  -- Glisser-deposer d'un fichier audio sur une colonne
  -- gfx.getdropfile(idx) renvoie DEUX valeurs (retval, nom) ; retval vaut 0 quand il n'y a (plus) rien : 0 est "vrai" en Lua !
  local drop_rv=ENABLE_FILE_DROP and gfx.getdropfile(0) or 0
  if drop_rv and drop_rv~=0 then
    local files,k={},0
    while k<64 do
      local rv,f=gfx.getdropfile(k)
      if not rv or rv==0 or not f or f=="" then break end
      files[#files+1]=f; k=k+1
    end
    gfx.getdropfile(-1)
    local mx,my,target=gfx.mouse_x,gfx.mouse_y,nil
    for i=0,MAX_INST-1 do
      local r=COLRECT[i]
      if r and mx>=r[1] and mx<=r[1]+r[3] and my>=r[2] and my<=r[2]+r[4] then target=i end
    end
    if target and files[1] then start_load(target,files[1],now_t) else load_msg("Deposez le fichier sur la colonne d'un looper") end
  end
  if ENABLE_FILE_DROP then load_step(now_t) end
  do                                                    -- etat du chargement / message
    local msg
    if LOAD then
      local pct=LOAD.phase=="stream" and math.floor(100*(LOAD.k or 0)/math.max(1,LOAD.Nf or 1)) or 0
      msg=string.format("Chargement looper %d : %s  %s%s",LOAD.i+1,LOAD.name,LOAD.phase=="stream" and (pct.."%") or LOAD.phase,"")
    elseif now_t-LOAD_MSG_T<5 and LOAD_MSG~="" then msg=LOAD_MSG end
    if msg then ftext(w*.30,27*s,w*.40,msg,10*s,1,.85,.35,true,7,"center") end
  end
  gfx.update(); reaper.defer(main)
end

init(); reaper.defer(main)
