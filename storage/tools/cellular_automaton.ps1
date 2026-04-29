
# 生成元胞自动机网页并打开
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlPath = Join-Path $scriptDir "cellular_automaton.html"

# HTML内容
$htmlContent = @'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>元胞自动机 - Cellular Automaton</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0a0a1a;
    color: #e0e0e0;
    font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif;
    overflow: hidden;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }
  .header {
    background: linear-gradient(135deg, #1a1a2e, #16213e);
    padding: 10px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #2a2a4a;
    flex-shrink: 0;
  }
  .header h1 {
    font-size: 22px;
    background: linear-gradient(90deg, #00d2ff, #7b2ff7);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: 2px;
  }
  .header .subtitle { font-size: 12px; color: #666; margin-top: 2px; }
  .controls {
    background: #111128;
    padding: 10px 20px;
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
    border-bottom: 1px solid #2a2a4a;
    flex-shrink: 0;
  }
  .control-group { display: flex; align-items: center; gap: 6px; }
  .control-group label { font-size: 13px; color: #aaa; white-space: nowrap; }
  .controls select, .controls input[type="number"] {
    background: #1a1a3a; border: 1px solid #3a3a6a; color: #ddd;
    padding: 5px 10px; border-radius: 6px; font-size: 13px; outline: none;
  }
  .controls select:focus, .controls input:focus { border-color: #7b2ff7; }
  .controls input[type="range"] {
    -webkit-appearance: none; height: 6px; background: #2a2a5a;
    border-radius: 3px; outline: none; width: 100px;
  }
  .controls input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none; width: 16px; height: 16px;
    background: #7b2ff7; border-radius: 50%; cursor: pointer;
  }
  .btn {
    padding: 6px 16px; border: none; border-radius: 6px;
    font-size: 13px; cursor: pointer; transition: all 0.2s; font-weight: 500;
  }
  .btn:hover { transform: translateY(-1px); }
  .btn-primary { background: linear-gradient(135deg, #7b2ff7, #00d2ff); color: #fff; }
  .btn-danger { background: linear-gradient(135deg, #e74c3c, #c0392b); color: #fff; }
  .btn-secondary { background: #2a2a5a; color: #ccc; border: 1px solid #3a3a6a; }
  .btn-success { background: linear-gradient(135deg, #27ae60, #2ecc71); color: #fff; }
  .canvas-container {
    flex: 1; display: flex; align-items: center; justify-content: center;
    position: relative; overflow: hidden;
  }
  canvas { border: 1px solid #2a2a4a; cursor: crosshair; image-rendering: pixelated; }
  .statusbar {
    background: #111128; padding: 6px 20px; display: flex;
    align-items: center; justify-content: space-between;
    font-size: 12px; color: #666; border-top: 1px solid #2a2a4a; flex-shrink: 0;
  }
  .statusbar .stat { display: flex; align-items: center; gap: 4px; }
  .statusbar .stat .val { color: #00d2ff; font-weight: 600; }
  .presets-panel {
    position: absolute; top: 10px; right: 10px;
    background: rgba(20, 20, 50, 0.95); border: 1px solid #3a3a6a;
    border-radius: 10px; padding: 12px; display: none;
    max-height: 80vh; overflow-y: auto; z-index: 100; min-width: 180px;
  }
  .presets-panel.show { display: block; }
  .presets-panel h3 { font-size: 14px; color: #7b2ff7; margin-bottom: 8px; }
  .preset-item {
    padding: 6px 10px; margin: 3px 0; background: #1a1a3a;
    border-radius: 6px; cursor: pointer; font-size: 13px; transition: all 0.15s;
  }
  .preset-item:hover { background: #2a2a5a; color: #00d2ff; }
  .color-swatch {
    width: 20px; height: 20px; border-radius: 50%;
    border: 2px solid transparent; cursor: pointer;
    display: inline-block; transition: all 0.2s;
  }
  .color-swatch:hover, .color-swatch.active { border-color: #fff; transform: scale(1.2); }
  .rule-display {
    font-family: monospace; font-size: 12px; color: #00d2ff;
    background: #1a1a3a; padding: 3px 8px; border-radius: 4px;
  }
</style>
</head>
<body>
<div class="header">
  <div>
    <h1>🔬 元胞自动机</h1>
    <div class="subtitle">Cellular Automaton Simulator</div>
  </div>
  <div class="control-group" style="gap:8px;">
    <div class="color-swatch active" data-theme="cyber" style="background: linear-gradient(135deg, #7b2ff7, #00d2ff);" title="赛博主题"></div>
    <div class="color-swatch" data-theme="fire" style="background: linear-gradient(135deg, #e74c3c, #f39c12);" title="烈焰主题"></div>
    <div class="color-swatch" data-theme="matrix" style="background: linear-gradient(135deg, #00ff41, #008f11);" title="矩阵主题"></div>
    <div class="color-swatch" data-theme="ocean" style="background: linear-gradient(135deg, #0077b6, #00b4d8);" title="海洋主题"></div>
  </div>
</div>
<div class="controls">
  <div class="control-group">
    <label>模式:</label>
    <select id="modeSelect">
      <option value="life">生命游戏 (2D)</option>
      <option value="1d">初等自动机 (1D)</option>
    </select>
  </div>
  <div class="control-group" id="ruleGroup" style="display:none;">
    <label>规则:</label>
    <input type="number" id="ruleNum" value="30" min="0" max="255" style="width:70px;">
    <span class="rule-display" id="ruleBits">00011110</span>
  </div>
  <div class="control-group">
    <label>网格:</label>
    <select id="gridSize">
      <option value="3">大 (3px)</option>
      <option value="4" selected>中 (4px)</option>
      <option value="6">小 (6px)</option>
      <option value="8">超小 (8px)</option>
    </select>
  </div>
  <div class="control-group">
    <label>速度:</label>
    <input type="range" id="speedSlider" min="1" max="60" value="15">
    <span id="speedVal" style="font-size:12px;color:#aaa;width:30px;">15</span>
  </div>
  <button class="btn btn-primary" id="btnPlay">▶ 运行</button>
  <button class="btn btn-secondary" id="btnStep">⏭ 单步</button>
  <button class="btn btn-danger" id="btnClear">✖ 清除</button>
  <button class="btn btn-secondary" id="btnRandom">🎲 随机</button>
  <button class="btn btn-success" id="btnPresets">📋 预设</button>
</div>
<div class="canvas-container">
  <canvas id="canvas"></canvas>
  <div class="presets-panel" id="presetsPanel">
    <h3>🏗 生命游戏预设</h3>
    <div class="preset-item" data-preset="glider">滑翔机 Glider</div>
    <div class="preset-item" data-preset="lwss">轻量飞船 LWSS</div>
    <div class="preset-item" data-preset="pulsar">脉冲星 Pulsar</div>
    <div class="preset-item" data-preset="pentadecathlon">五倍体 Pentadecathlon</div>
    <div class="preset-item" data-preset="gosper">高斯帕枪 Gosper Gun</div>
    <div class="preset-item" data-preset="acorn">橡果 Acorn</div>
    <div class="preset-item" data-preset="rpentomino">R五联骨牌</div>
    <div class="preset-item" data-preset="diehard">顽固 Diehard</div>
    <h3 style="margin-top:10px;">🔢 1D 经典规则</h3>
    <div class="preset-item" data-rule="30">Rule 30 (混沌)</div>
    <div class="preset-item" data-rule="90">Rule 90 (谢尔宾斯基)</div>
    <div class="preset-item" data-rule="110">Rule 110 (图灵完备)</div>
    <div class="preset-item" data-rule="184">Rule 184 (交通流)</div>
    <div class="preset-item" data-rule="150">Rule 150 (分形)</div>
    <div class="preset-item" data-rule="60">Rule 60 (三角)</div>
  </div>
</div>
<div class="statusbar">
  <div style="display:flex;gap:20px;">
    <div class="stat">代数: <span class="val" id="genCount">0</span></div>
    <div class="stat">活细胞: <span class="val" id="cellCount">0</span></div>
    <div class="stat">网格: <span class="val" id="gridInfo">-</span></div>
  </div>
  <div class="stat">点击/拖拽绘制 | 空格 运行/暂停 | N 单步 | C 清除 | R 随机</div>
</div>
<script>
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
let cellSize = 4, cols, rows, grid, nextGrid;
let running = false, generation = 0, animId = null, lastTime = 0, speed = 15;
let mode = 'life', rule1d = 30, currentRow1d = 0, history1d = [];
let isDrawing = false, drawValue = 1;
const themes = {
  cyber:  { alive: '#7b2ff7', alive2: '#00d2ff', bg: '#0a0a1a', grid: '#0f0f2a' },
  fire:   { alive: '#e74c3c', alive2: '#f39c12', bg: '#1a0a0a', grid: '#1a0f0f' },
  matrix: { alive: '#00ff41', alive2: '#008f11', bg: '#000a00', grid: '#001a00' },
  ocean:  { alive: '#0077b6', alive2: '#00b4d8', bg: '#0a0a1a', grid: '#0a1a2a' }
};
let currentTheme = 'cyber';

function init() { resizeCanvas(); clearGrid(); draw(); }
function resizeCanvas() {
  const c = canvas.parentElement;
  const w = c.clientWidth - 20, h = c.clientHeight - 20;
  cols = Math.floor(w / cellSize); rows = Math.floor(h / cellSize);
  canvas.width = cols * cellSize; canvas.height = rows * cellSize;
  document.getElementById('gridInfo').textContent = cols + '×' + rows;
}
function clearGrid() {
  generation = 0; currentRow1d = 0; history1d = [];
  grid = new Uint8Array(cols * rows); nextGrid = new Uint8Array(cols * rows);
  updateStats();
}
function randomize() {
  clearGrid();
  if (mode === 'life') { for (let i = 0; i < grid.length; i++) grid[i] = Math.random() < 0.3 ? 1 : 0; }
  else { grid[Math.floor(cols / 2)] = 1; history1d = [grid.slice()]; }
  draw(); updateStats();
}
function stepLife() {
  for (let y = 0; y < rows; y++) for (let x = 0; x < cols; x++) {
    let n = 0;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
      if (!dx && !dy) continue;
      n += grid[((y + dy + rows) % rows) * cols + (x + dx + cols) % cols];
    }
    const i = y * cols + x;
    nextGrid[i] = grid[i] ? (n === 2 || n === 3 ? 1 : 0) : (n === 3 ? 1 : 0);
  }
  [grid, nextGrid] = [nextGrid, grid]; generation++;
}
function step1D() {
  if (currentRow1d >= rows - 1) { history1d.shift(); currentRow1d = rows - 1; }
  const cur = currentRow1d === 0 ? grid.slice() : history1d[history1d.length - 1];
  const nxt = new Uint8Array(cols);
  for (let x = 0; x < cols; x++) {
    const p = (cur[(x-1+cols)%cols] << 2) | (cur[x] << 1) | cur[(x+1)%cols];
    nxt[x] = (rule1d >> p) & 1;
  }
  currentRow1d++; history1d.push(nxt);
  grid.fill(0);
  for (let r = 0; r < history1d.length; r++) for (let x = 0; x < cols; x++) {
    const gy = rows - history1d.length + r;
    if (gy >= 0) grid[gy * cols + x] = history1d[r][x];
  }
  generation++;
}
function step() { mode === 'life' ? stepLife() : step1D(); updateStats(); }
function lerpColor(c1, c2, t) {
  const p = (s, i) => parseInt(s.slice(i, i+2), 16);
  const r = Math.round(p(c1,1)+(p(c2,1)-p(c1,1))*t);
  const g = Math.round(p(c1,3)+(p(c2,3)-p(c1,3))*t);
  const b = Math.round(p(c1,5)+(p(c2,5)-p(c1,5))*t);
  return 'rgb('+r+','+g+','+b+')';
}
function draw() {
  const th = themes[currentTheme];
  ctx.fillStyle = th.bg; ctx.fillRect(0, 0, canvas.width, canvas.height);
  if (cellSize >= 6) {
    ctx.strokeStyle = th.grid; ctx.lineWidth = 0.5;
    for (let x = 0; x <= cols; x++) { ctx.beginPath(); ctx.moveTo(x*cellSize,0); ctx.lineTo(x*cellSize,canvas.height); ctx.stroke(); }
    for (let y = 0; y <= rows; y++) { ctx.beginPath(); ctx.moveTo(0,y*cellSize); ctx.lineTo(canvas.width,y*cellSize); ctx.stroke(); }
  }
  const gap = cellSize >= 6 ? 1 : 0;
  for (let y = 0; y < rows; y++) for (let x = 0; x < cols; x++) {
    if (grid[y * cols + x]) {
      ctx.fillStyle = lerpColor(th.alive, th.alive2, (x/cols+y/rows)%1);
      ctx.fillRect(x*cellSize+gap, y*cellSize+gap, cellSize-gap*2, cellSize-gap*2);
    }
  }
}
function animate(ts) {
  if (!running) return;
  if (ts - lastTime >= 1000/speed) { step(); draw(); lastTime = ts; }
  animId = requestAnimationFrame(animate);
}
function toggleRun() {
  running = !running;
  const btn = document.getElementById('btnPlay');
  if (running) { btn.textContent = '⏸ 暂停'; lastTime = performance.now(); animId = requestAnimationFrame(animate); }
  else { btn.textContent = '▶ 运行'; if (animId) cancelAnimationFrame(animId); }
}
function getCellPos(e) {
  const r = canvas.getBoundingClientRect();
  return { x: Math.max(0, Math.min(cols-1, Math.floor((e.clientX-r.left)/cellSize))),
           y: Math.max(0, Math.min(rows-1, Math.floor((e.clientY-r.top)/cellSize))) };
}
canvas.addEventListener('mousedown', e => { isDrawing=true; const p=getCellPos(e); drawValue=grid[p.y*cols+p.x]?0:1; grid[p.y*cols+p.x]=drawValue; draw(); updateStats(); });
canvas.addEventListener('mousemove', e => { if(!isDrawing)return; const p=getCellPos(e); grid[p.y*cols+p.x]=drawValue; draw(); updateStats(); });
canvas.addEventListener('mouseup', () => isDrawing=false);
canvas.addEventListener('mouseleave', () => isDrawing=false);
canvas.addEventListener('touchstart', e => { e.preventDefault(); const p=getCellPos(e.touches[0]); isDrawing=true; drawValue=grid[p.y*cols+p.x]?0:1; grid[p.y*cols+p.x]=drawValue; draw(); updateStats(); });
canvas.addEventListener('touchmove', e => { e.preventDefault(); if(!isDrawing)return; const p=getCellPos(e.touches[0]); grid[p.y*cols+p.x]=drawValue; draw(); updateStats(); });
canvas.addEventListener('touchend', () => isDrawing=false);
document.addEventListener('keydown', e => {
  if(e.target.tagName==='INPUT'||e.target.tagName==='SELECT')return;
  switch(e.code){ case'Space':e.preventDefault();toggleRun();break; case'KeyN':step();draw();break; case'KeyC':clearGrid();draw();break; case'KeyR':randomize();break; }
});
document.getElementById('btnPlay').addEventListener('click', toggleRun);
document.getElementById('btnStep').addEventListener('click', () => { step(); draw(); });
document.getElementById('btnClear').addEventListener('click', () => { clearGrid(); draw(); });
document.getElementById('btnRandom').addEventListener('click', randomize);
document.getElementById('modeSelect').addEventListener('change', e => {
  mode=e.target.value; document.getElementById('ruleGroup').style.display=mode==='1d'?'flex':'none';
  clearGrid(); if(mode==='1d'){grid[Math.floor(cols/2)]=1;history1d=[grid.slice()];} draw(); updateStats();
});
document.getElementById('ruleNum').addEventListener('input', e => {
  rule1d=Math.max(0,Math.min(255,parseInt(e.target.value)||0));
  document.getElementById('ruleBits').textContent=rule1d.toString(2).padStart(8,'0');
  clearGrid(); if(mode==='1d'){grid[Math.floor(cols/2)]=1;history1d=[grid.slice()];} draw();
});
document.getElementById('gridSize').addEventListener('change', e => {
  cellSize=parseInt(e.target.value); const w=running; if(running)toggleRun();
  resizeCanvas(); clearGrid(); if(mode==='1d'){grid[Math.floor(cols/2)]=1;history1d=[grid.slice()];} draw(); updateStats();
});
document.getElementById('speedSlider').addEventListener('input', e => { speed=parseInt(e.target.value); document.getElementById('speedVal').textContent=speed; });
document.querySelectorAll('.color-swatch').forEach(s => s.addEventListener('click', () => {
  document.querySelectorAll('.color-swatch').forEach(x=>x.classList.remove('active'));
  s.classList.add('active'); currentTheme=s.dataset.theme; draw();
}));
document.getElementById('btnPresets').addEventListener('click', () => document.getElementById('presetsPanel').classList.toggle('show'));
document.addEventListener('click', e => { if(!e.target.closest('#btnPresets')&&!e.target.closest('#presetsPanel'))document.getElementById('presetsPanel').classList.remove('show'); });

const presets = {
  glider:[[0,1,0],[0,0,1],[1,1,1]],
  lwss:[[0,1,0,0,1],[1,0,0,0,0],[1,0,0,0,1],[1,1,1,1,0]],
  pulsar:[[0,0,1,1,1,0,0,0,1,1,1,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0],[1,0,0,0,0,1,0,1,0,0,0,0,1],[1,0,0,0,0,1,0,1,0,0,0,0,1],[1,0,0,0,0,1,0,1,0,0,0,0,1],[0,0,1,1,1,0,0,0,1,1,1,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,1,1,1,0,0,0,1,1,1,0,0],[1,0,0,0,0,1,0,1,0,0,0,0,1],[1,0,0,0,0,1,0,1,0,0,0,0,1],[1,0,0,0,0,1,0,1,0,0,0,0,1],[0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,1,1,1,0,0,0,1,1,1,0,0]],
  pentadecathlon:[[0,0,1,0,0,0,0,1,0,0],[1,1,0,1,1,1,1,0,1,1],[0,0,1,0,0,0,0,1,0,0]],
  acorn:[[0,1,0,0,0,0,0],[0,0,0,1,0,0,0],[1,1,0,0,1,1,1]],
  rpentomino:[[0,1,1],[1,1,0],[0,1,0]],
  diehard:[[0,0,0,0,0,0,1,0],[1,1,0,0,0,0,0,0],[0,1,0,0,0,1,1,1]],
  gosper:[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],[0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],[1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[1,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
};
function placePreset(name) {
  clearGrid(); const pat=presets[name]; if(!pat)return;
  const sx=Math.floor((cols-pat[0].length)/2), sy=Math.floor((rows-pat.length)/2);
  for(let y=0;y<pat.length;y++) for(let x=0;x<pat[0].length;x++) {
    const gx=sx+x, gy=sy+y;
    if(gx>=0&&gx<cols&&gy>=0&&gy<rows) grid[gy*cols+gx]=pat[y][x];
  }
  draw(); updateStats();
}
document.querySelectorAll('.preset-item[data-preset]').forEach(i => i.addEventListener('click', () => {
  document.getElementById('modeSelect').value='life'; mode='life'; document.getElementById('ruleGroup').style.display='none';
  placePreset(i.dataset.preset); document.getElementById('presetsPanel').classList.remove('show');
}));
document.querySelectorAll('.preset-item[data-rule]').forEach(i => i.addEventListener('click', () => {
  document.getElementById('modeSelect').value='1d'; mode='1d'; document.getElementById('ruleGroup').style.display='flex';
  rule1d=parseInt(i.dataset.rule); document.getElementById('ruleNum').value=rule1d;
  document.getElementById('ruleBits').textContent=rule1d.toString(2).padStart(8,'0');
  clearGrid(); grid[Math.floor(cols/2)]=1; history1d=[grid.slice()]; draw(); updateStats();
  document.getElementById('presetsPanel').classList.remove('show');
}));
function updateStats() {
  document.getElementById('genCount').textContent=generation;
  let a=0; for(let i=0;i<grid.length;i++) if(grid[i])a++;
  document.getElementById('cellCount').textContent=a;
}
window.addEventListener('resize', () => { const w=running; if(running)toggleRun(); resizeCanvas(); clearGrid(); draw(); updateStats(); });
init(); placePreset('glider');
</script>
</body>
</html>
'@

Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
Write-Host "✅ 元胞自动机网页已生成: $htmlPath"
Start-Process $htmlPath

