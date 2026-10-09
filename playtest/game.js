(() => {
  'use strict';

  const WIDTH = 420;
  const HEIGHT = 780;
  const TAU = Math.PI * 2;
  const MAX_WAIT = 20;
  const FEVER_LENGTH = 8;
  const PERFECT_WINDOW = 0.15;
  const ZONES = [
    { a: '#74efff', b: '#8998ff', bg: '#0c1429' },
    { a: '#ffd36e', b: '#ff8d91', bg: '#21162a' },
    { a: '#70ffd1', b: '#9dff91', bg: '#0e2527' },
    { a: '#d6a6ff', b: '#8d7dff', bg: '#1b1532' },
    { a: '#69daff', b: '#4e91ff', bg: '#101d38' },
    { a: '#ffab77', b: '#ff5e9a', bg: '#2b1325' },
  ];
  const DEATH_LINES = [
    'Gravity just filed a complaint.',
    'The planet said: not today.',
    'A brave launch. A very short sequel.',
    'The stars are pretending they saw nothing.',
    'That was a confident almost.',
    'The danger soup got a little too close.',
    'Your blob found the off-screen shortcut.',
    'The galaxy has a strict no-floors policy.',
    'A tiny blob, a giant whoops.',
    'The next orbit is already looking adorable.',
  ];

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const overlay = document.getElementById('overlay');
  const overlayKicker = document.getElementById('overlayKicker');
  const overlayTitle = document.getElementById('overlayTitle');
  const overlayText = document.getElementById('overlayText');
  const overlayButton = document.getElementById('overlayButton');
  const overlayFoot = document.getElementById('overlayFoot');
  const scoreNode = document.getElementById('score');
  const comboNode = document.getElementById('combo');
  const comboBadge = document.getElementById('comboBadge');
  const coinsNode = document.getElementById('coins');
  const feverBadge = document.getElementById('feverBadge');
  const tapHint = document.getElementById('tapHint');
  const pauseButton = document.getElementById('pauseButton');
  const phaseLabel = document.getElementById('phaseLabel');
  const stateReadout = document.getElementById('stateReadout');
  const bestScoreNode = document.getElementById('bestScore');
  const lastRunNode = document.getElementById('lastRun');
  const toast = document.getElementById('toast');
  const stage = document.getElementById('stage');

  let cssWidth = 0;
  let cssHeight = 0;
  let scale = 1;
  let offsetX = 0;
  let offsetY = 0;
  let mode = 'title';
  let previousMode = 'ready';
  let lastFrame = 0;
  let hudTimer = 0;
  let clock = 0;
  let seed = 0x6d2b79f5;
  let current = null;
  let target = null;
  let player = { x: 0, y: 0, angle: 0 };
  let playerAngle = 0;
  let idealAngle = 0;
  let launchAngle = 0;
  let launchStart = { x: 0, y: 0 };
  let launchDirection = { x: 0, y: -1 };
  let flightSpeed = 430;
  let flightDistance = 0;
  let flightElapsed = 0;
  let runElapsed = 0;
  let waitElapsed = 0;
  let cameraY = 0;
  let dangerY = 0;
  let score = 0;
  let combo = 0;
  let maxCombo = 0;
  let coins = 0;
  let perfects = 0;
  let fever = false;
  let feverSeconds = 0;
  let perfectFlash = 0;
  let deathLine = '';
  let runNumber = 0;
  let lastScore = null;
  let bestScore = Number(localStorage.getItem('orbit-hop-playtest-best') || 0);
  let pickups = [];
  let trail = [];
  let particles = [];
  let shake = 0;
  let shakePower = 0;
  let toastTimer = 0;
  let stars = [];

  bestScoreNode.textContent = String(bestScore);
  stars = Array.from({ length: 92 }, (_, i) => ({
    x: ((i * 197 + 41) % 416) + 2,
    y: ((i * 317 + 137) % 780),
    r: 0.65 + (i % 4) * 0.42,
    alpha: 0.2 + (i % 5) * 0.11,
    parallax: 0.025 + (i % 6) * 0.025,
    phase: (i * 0.73) % TAU,
  }));

  function random() {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = seed;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  function between(min, max) { return min + random() * (max - min); }
  function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }
  function wrapAngle(value) {
    while (value > Math.PI) value -= TAU;
    while (value < -Math.PI) value += TAU;
    return value;
  }
  function orbitPoint(planet, angle) {
    return { x: planet.x + Math.cos(angle) * planet.orbitRadius, y: planet.y + Math.sin(angle) * planet.orbitRadius };
  }
  function tangent(angle, direction) {
    return { x: -Math.sin(angle) * direction, y: Math.cos(angle) * direction };
  }
  function add(a, b, factor = 1) { return { x: a.x + b.x * factor, y: a.y + b.y * factor }; }
  function dot(a, b) { return a.x * b.x + a.y * b.y; }
  function distance(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
  function palette() { return ZONES[Math.floor(score / 25) % ZONES.length]; }

  function resetRun() {
    seed = (Date.now() ^ (runNumber * 2654435761)) >>> 0;
    runNumber += 1;
    score = 0;
    combo = 0;
    maxCombo = 0;
    coins = 0;
    perfects = 0;
    fever = false;
    feverSeconds = 0;
    perfectFlash = 0;
    waitElapsed = 0;
    runElapsed = 0;
    flightDistance = 0;
    flightElapsed = 0;
    cameraY = 0;
    clock = 0;
    shake = 0;
    shakePower = 0;
    trail = [];
    particles = [];
    pickups = [];

    const spinDirection = random() < 0.5 ? 1 : -1;
    current = {
      x: WIDTH / 2,
      baseX: WIDTH / 2,
      y: HEIGHT * 0.62,
      radius: 37,
      orbitRadius: 72,
      spinSpeed: 1.22,
      spinDirection,
      phase: random() * TAU,
      moving: false,
      motionAmplitude: 0,
      motionFrequency: 0,
      shrinking: false,
      hasSpikes: false,
      spikeAngles: [],
      shrinkRate: 0,
    };
    dangerY = current.y + HEIGHT * 1.12;
    makeNextPlanet();
    playerAngle = wrapAngle(idealAngle - current.spinDirection * 0.72);
    player = orbitPoint(current, playerAngle);
    mode = 'ready';
    hideOverlay();
    pauseButton.style.visibility = 'visible';
    showToast('Find the gold launch window');
    updateHud(true);
  }

  function makeNextPlanet() {
    const nextScore = score + 1;
    const baseAngle = current.spinDirection > 0 ? Math.PI : 0;
    const towardCenter = current.x < WIDTH / 2 ? 1 : -1;
    const offset = between(0.07, 0.34);
    idealAngle = baseAngle + towardCenter * offset;
    const idealStart = orbitPoint(current, idealAngle);
    const dir = tangent(idealAngle, current.spinDirection);
    const normal = { x: -dir.y, y: dir.x };
    const radius = Math.max(21, 37 - nextScore * 0.17);
    const orbitRadius = radius + 35;
    const travel = orbitRadius + 220 + between(-12, 18);
    const sideShift = between(-8, 8);
    const idealCenter = add(add(idealStart, dir, travel), normal, sideShift);
    const targetX = clamp(idealCenter.x, WIDTH * 0.12, WIDTH * 0.88);
    const spiked = nextScore >= 9 && random() < Math.min(0.62, 0.06 + (nextScore - 8) * 0.009);
    const spikeAngles = [];
    if (spiked) {
      const expectedEntry = Math.atan2(-dir.y, -dir.x);
      for (let i = 0; i < (nextScore > 50 ? 3 : 2); i += 1) {
        let angle = between(-Math.PI, Math.PI);
        if (Math.abs(wrapAngle(angle - expectedEntry)) < 0.62) angle = wrapAngle(angle + Math.PI);
        spikeAngles.push(angle);
      }
    }
    target = {
      x: targetX,
      baseX: targetX,
      y: idealCenter.y,
      radius,
      orbitRadius,
      spinSpeed: Math.min(3.35, 1.22 + nextScore * 0.025),
      spinDirection: random() < 0.5 ? 1 : -1,
      phase: random() * TAU,
      moving: nextScore >= 4 && random() < Math.min(0.62, 0.05 + nextScore * 0.012),
      motionAmplitude: Math.min(WIDTH * 0.12, 18 + nextScore * 0.8),
      motionFrequency: 0.42 + nextScore * 0.006,
      shrinking: nextScore >= 15 && random() < Math.min(0.35, 0.04 + (nextScore - 14) * 0.004),
      shrinkRate: 0,
      hasSpikes: spiked,
      spikeAngles,
    };

    const coinCount = nextScore < 7 ? 3 : 2 + Math.floor(random() * 2);
    pickups = [];
    for (let i = 0; i < coinCount; i += 1) {
      const progress = 0.25 + ((i + 1) / (coinCount + 1)) * 0.53;
      const p = add(add(idealStart, dir, travel * progress), normal, between(-5, 5));
      pickups.push({ x: p.x, y: p.y, kind: 'coin', collected: false, phase: random() * TAU });
    }
    if (nextScore >= 3 && random() < 1 / 16) {
      const p = add(add(idealStart, dir, travel * between(0.55, 0.88)), normal, between(21, 39));
      pickups.push({ x: p.x, y: p.y, kind: 'gem', collected: false, phase: random() * TAU });
    }
  }

  function launch() {
    if (mode !== 'ready') return;
    mode = 'flight';
    launchAngle = playerAngle;
    launchStart = { x: player.x, y: player.y };
    launchDirection = tangent(playerAngle, current.spinDirection);
    flightSpeed = Math.min(600, 430 + score * 2.2 + Math.floor(score / 150) * 16);
    flightDistance = 0;
    flightElapsed = 0;
    trail = [];
    updateHud(true);
  }

  function landOn(planet, landingAngle) {
    const perfect = Math.abs(wrapAngle(launchAngle - idealAngle)) <= (fever ? 0.23 : PERFECT_WINDOW);
    score += 1;
    combo = perfect ? combo + 1 : 0;
    maxCombo = Math.max(maxCombo, combo);
    if (perfect) {
      perfects += 1;
      perfectFlash = 0.8;
      coins += fever ? 14 : 7;
      showToast(combo > 1 ? `PERFECT · ${combo}× COMBO` : 'PERFECT LANDING');
      burst(player.x, player.y, '#ffe17a', 20, 130);
      shake = 0.16;
      shakePower = 3;
    } else {
      coins += fever ? 6 : 3;
      showToast('NICE LANDING');
      burst(player.x, player.y, '#78edff', 13, 95);
      shake = 0.1;
      shakePower = 1.8;
    }
    if (planet.shrinking) planet.shrinkRate = 3.5 + score * 0.08;
    planet.orbitRadius = planet.radius + 35;
    current = planet;
    target = null;
    playerAngle = landingAngle;
    player = orbitPoint(current, playerAngle);
    waitElapsed = 0;
    flightDistance = 0;
    flightElapsed = 0;
    trail = [];
    mode = 'ready';

    if (combo >= 5 && combo % 5 === 0 && !fever) {
      fever = true;
      feverSeconds = FEVER_LENGTH;
      showToast('FEVER MODE · COINS ×2');
      burst(player.x, player.y, '#ff8dc8', 32, 185);
    }
    makeNextPlanet();
    updateHud(true);
  }

  function die(reason) {
    if (mode === 'gameover') return;
    mode = 'gameover';
    deathLine = DEATH_LINES[Math.floor(random() * DEATH_LINES.length)];
    lastScore = score;
    if (score > bestScore) {
      bestScore = score;
      localStorage.setItem('orbit-hop-playtest-best', String(bestScore));
    }
    lastRunNode.textContent = String(score);
    showOverlay('gameover', reason);
    burst(player.x, player.y, '#ff7ca8', 24, 180);
    pauseButton.style.visibility = 'hidden';
    updateHud(true);
  }

  function pause() {
    if (mode !== 'ready' && mode !== 'flight') return;
    previousMode = mode;
    mode = 'paused';
    showOverlay('paused');
    updateHud(true);
  }

  function resume() {
    if (mode !== 'paused') return;
    mode = previousMode;
    hideOverlay();
    updateHud(true);
  }

  function updatePlanet(planet, dt) {
    if (!planet) return;
    planet.x = planet.baseX + (planet.moving ? Math.sin(clock * planet.motionFrequency + planet.phase) * planet.motionAmplitude : 0);
    if (planet.shrinking && planet.shrinkRate > 0) {
      planet.radius = Math.max(16, planet.radius - planet.shrinkRate * dt);
      planet.orbitRadius = planet.radius + 35;
    }
  }

  function update(dt) {
    clock += dt;
    if (mode === 'title' || mode === 'paused' || mode === 'gameover') return;
    dt = Math.min(dt, 0.06);
    runElapsed += dt;
    if (fever) {
      feverSeconds = Math.max(0, feverSeconds - dt);
      if (feverSeconds === 0) fever = false;
    }
    perfectFlash = Math.max(0, perfectFlash - dt);
    shake = Math.max(0, shake - dt);
    dangerY -= 36 * dt;
    updatePlanet(current, dt);
    updatePlanet(target, dt);

    if (mode === 'ready') {
      waitElapsed += dt;
      playerAngle += current.spinSpeed * current.spinDirection * dt;
      player = orbitPoint(current, playerAngle);
      if (waitElapsed >= MAX_WAIT) {
        die('ORBIT TIMEOUT');
        return;
      }
      if (dangerY <= player.y + 4) {
        die('DANGER ZONE');
        return;
      }
    } else if (mode === 'flight') {
      flightDistance += flightSpeed * dt;
      flightElapsed += dt;
      player = add(launchStart, launchDirection, flightDistance);
      trail.unshift({ x: player.x, y: player.y });
      if (trail.length > 18) trail.length = 18;
      collectPickups();

      if (!target) { die('MISSED ORBIT'); return; }
      const relative = { x: target.x - launchStart.x, y: target.y - launchStart.y };
      const along = dot(relative, launchDirection);
      const lateral = { x: relative.x - launchDirection.x * along, y: relative.y - launchDirection.y * along };
      const perpendicular = Math.hypot(lateral.x, lateral.y);
      const laneWidth = Math.min(target.orbitRadius - 3, target.orbitRadius * 0.72 + 32 * 0.44);
      if (perpendicular <= laneWidth && along > 0) {
        const inside = Math.sqrt(Math.max(0, target.orbitRadius ** 2 - perpendicular ** 2));
        const entryDistance = along - inside;
        if (entryDistance > 0 && flightDistance >= entryDistance) {
          const impact = add(launchStart, launchDirection, entryDistance);
          const impactAngle = Math.atan2(impact.y - target.y, impact.x - target.x);
          if (target.hasSpikes && target.spikeAngles.some((angle) => Math.abs(wrapAngle(angle - impactAngle)) < 0.32)) {
            die('SPIKE HAZARD');
            return;
          }
          player = impact;
          landOn(target, impactAngle);
          return;
        }
      }
      if (flightDistance > 1500 || flightElapsed > 2.9 || player.y < target.y - 420 || player.x < -100 || player.x > WIDTH + 100) {
        die('MISSED ORBIT');
        return;
      }
    }

    const cameraTarget = player.y - HEIGHT * 0.62;
    if (cameraTarget < cameraY) cameraY += (cameraTarget - cameraY) * Math.min(1, dt * 8);
    updateParticles(dt);
    hudTimer += dt;
    if (hudTimer > 0.09) {
      hudTimer = 0;
      updateHud(false);
    }
  }

  function collectPickups() {
    for (const pickup of pickups) {
      if (pickup.collected) continue;
      if (distance(player, pickup) > (pickup.kind === 'coin' ? 19 : 17)) continue;
      pickup.collected = true;
      coins += pickup.kind === 'coin' ? (fever ? 2 : 1) : 0;
      if (pickup.kind === 'gem') showToast('RARE COSMIC GEM');
      burst(pickup.x, pickup.y, pickup.kind === 'coin' ? '#ffd879' : '#bc9aff', pickup.kind === 'coin' ? 7 : 12, 88);
    }
  }

  function burst(x, y, color, amount, force) {
    for (let i = 0; i < amount && particles.length < 150; i += 1) {
      const angle = random() * TAU;
      const speed = between(force * 0.24, force);
      particles.push({ x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: between(0.3, 0.75), maxLife: 0.75, r: between(1.3, 3.1), color, spark: i % 4 === 0 });
    }
  }

  function updateParticles(dt) {
    for (const p of particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 55 * dt;
      p.r *= Math.max(0.92, 1 - dt * 0.42);
    }
    particles = particles.filter((p) => p.life > 0);
  }

  function updateHud(force) {
    scoreNode.textContent = String(score);
    comboNode.textContent = String(combo);
    coinsNode.textContent = String(coins);
    comboBadge.classList.toggle('hot', combo >= 2);
    feverBadge.classList.toggle('visible', fever);
    tapHint.style.opacity = mode === 'ready' ? '1' : '0.35';
    pauseButton.style.visibility = mode === 'title' || mode === 'gameover' ? 'hidden' : 'visible';
    const state = ({ title: 'TITLE', ready: 'ORBITING', flight: 'IN FLIGHT', paused: 'PAUSED', gameover: 'GAME OVER' })[mode] || 'READY';
    phaseLabel.textContent = state;
    stateReadout.textContent = state;
    bestScoreNode.textContent = String(bestScore);
    if (force) hudTimer = 0;
  }

  function showOverlay(kind, reason = '') {
    overlay.classList.remove('hidden');
    if (kind === 'title') {
      overlayKicker.textContent = 'A LITTLE SPACE. A LOT OF TIMING.';
      overlayTitle.innerHTML = 'Ready to<br><em>orbit?</em>';
      overlayText.textContent = 'Tap to launch from the planet. Land on the next orbit and see how far your blob can hop.';
      overlayButton.innerHTML = 'START PLAYTEST <span>↗</span>';
      overlayFoot.textContent = 'CLICK OR TAP · SPACEBAR ALSO WORKS';
    } else if (kind === 'gameover') {
      overlayKicker.textContent = reason || 'THE ORBIT ENDS HERE';
      overlayTitle.innerHTML = `RUN<br><em>OVER</em>`;
      overlayText.textContent = `${deathLine} You landed on ${score} planet${score === 1 ? '' : 's'} and collected ${coins} coins.`;
      overlayButton.innerHTML = 'TRY AGAIN <span>↻</span>';
      overlayFoot.textContent = `BEST SCORE · ${bestScore}  |  COMBO · ${maxCombo}`;
    } else {
      overlayKicker.textContent = 'TAKE A BREATHER';
      overlayTitle.innerHTML = 'Orbit<br><em>paused.</em>';
      overlayText.textContent = 'Your run is waiting right where you left it.';
      overlayButton.innerHTML = 'RESUME RUN <span>↗</span>';
      overlayFoot.textContent = 'TAP RESUME OR PRESS SPACE';
    }
  }

  function hideOverlay() { overlay.classList.add('hidden'); }
  function showToast(text) {
    toast.textContent = text;
    toast.classList.add('show');
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => toast.classList.remove('show'), 1150);
  }

  function resize() {
    const rect = stage.getBoundingClientRect();
    cssWidth = rect.width;
    cssHeight = rect.height;
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.round(cssWidth * dpr);
    canvas.height = Math.round(cssHeight * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    scale = Math.min(cssWidth / WIDTH, cssHeight / HEIGHT);
    offsetX = (cssWidth - WIDTH * scale) / 2;
    offsetY = (cssHeight - HEIGHT * scale) / 2;
  }

  function draw() {
    if (!cssWidth || !cssHeight) return;
    ctx.clearRect(0, 0, cssWidth, cssHeight);
    ctx.save();
    ctx.translate(offsetX, offsetY);
    ctx.scale(scale, scale);
    const zone = palette();
    const background = ctx.createLinearGradient(0, 0, WIDTH * 0.8, HEIGHT);
    background.addColorStop(0, '#10172d');
    background.addColorStop(0.48, zone.bg);
    background.addColorStop(1, '#0a0d1d');
    ctx.fillStyle = background;
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    for (const star of stars) {
      const y = ((star.y - cameraY * star.parallax) % HEIGHT + HEIGHT) % HEIGHT;
      const twinkle = 0.65 + 0.35 * Math.sin(clock * 1.7 + star.phase);
      ctx.beginPath();
      ctx.fillStyle = `rgba(221,235,255,${star.alpha * twinkle})`;
      ctx.arc(star.x, y, star.r, 0, TAU);
      ctx.fill();
    }
    drawNebula(zone);
    drawDanger();
    if (target) drawPlanet(target, true);
    if (current) drawPlanet(current, false);
    drawPickups();
    drawOrbitGate();
    drawTrail();
    if (player) drawBlob(player.x, player.y - cameraY, 12, zone.a);
    drawParticles();
    if (perfectFlash > 0 && mode !== 'title') drawPerfectLabel();
    ctx.restore();
  }

  function drawNebula(zone) {
    const y = HEIGHT * 0.34;
    const gradient = ctx.createRadialGradient(WIDTH * 0.52, y, 5, WIDTH * 0.52, y, 280);
    gradient.addColorStop(0, `${zone.a}19`);
    gradient.addColorStop(1, `${zone.a}00`);
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, WIDTH, HEIGHT);
  }

  function drawDanger() {
    const y = dangerY - cameraY;
    if (y < -30 || y > HEIGHT + 30) return;
    const gradient = ctx.createLinearGradient(0, y - 30, 0, y + 18);
    gradient.addColorStop(0, 'rgba(255,89,139,0)');
    gradient.addColorStop(0.75, 'rgba(255,89,139,.12)');
    gradient.addColorStop(1, 'rgba(255,89,139,.5)');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, y - 30, WIDTH, 48);
    ctx.save();
    ctx.shadowBlur = 13;
    ctx.shadowColor = '#ff679b';
    ctx.strokeStyle = 'rgba(255,116,159,.78)';
    ctx.lineWidth = 1.2;
    ctx.setLineDash([6, 9]);
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(WIDTH, y);
    ctx.stroke();
    ctx.restore();
  }

  function drawPlanet(planet, isTarget) {
    const x = planet.x;
    const y = planet.y - cameraY;
    const color = isTarget ? palette().b : palette().a;
    const ringRadius = planet.orbitRadius;
    ctx.save();
    ctx.strokeStyle = isTarget ? 'rgba(202,219,255,.15)' : `${color}45`;
    ctx.lineWidth = 1;
    ctx.setLineDash(isTarget ? [3, 7] : [2, 8]);
    ctx.beginPath();
    ctx.arc(x, y, ringRadius, 0, TAU);
    ctx.stroke();
    ctx.setLineDash([]);
    const halo = ctx.createRadialGradient(x, y, planet.radius * 0.4, x, y, planet.radius * 2.25);
    halo.addColorStop(0, `${color}27`);
    halo.addColorStop(1, `${color}00`);
    ctx.fillStyle = halo;
    ctx.beginPath();
    ctx.arc(x, y, planet.radius * 2.25, 0, TAU);
    ctx.fill();
    const sphere = ctx.createRadialGradient(x - planet.radius * 0.35, y - planet.radius * 0.48, 2, x, y, planet.radius * 1.12);
    sphere.addColorStop(0, '#f2fdff');
    sphere.addColorStop(0.24, color);
    sphere.addColorStop(1, '#29314d');
    ctx.fillStyle = sphere;
    ctx.beginPath();
    ctx.arc(x, y, planet.radius, 0, TAU);
    ctx.fill();
    ctx.strokeStyle = `${color}90`;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(x, y, planet.radius + 3, 0, TAU);
    ctx.stroke();
    ctx.save();
    ctx.beginPath();
    ctx.arc(x, y, planet.radius, 0, TAU);
    ctx.clip();
    ctx.fillStyle = 'rgba(255,255,255,.12)';
    ctx.beginPath();
    ctx.ellipse(x - planet.radius * 0.25, y - planet.radius * 0.32, planet.radius * 0.62, planet.radius * 0.22, -0.55, 0, TAU);
    ctx.fill();
    ctx.restore();
    if (planet.shrinking) {
      ctx.strokeStyle = 'rgba(255,184,118,.58)';
      ctx.lineWidth = 1.4;
      ctx.beginPath();
      ctx.arc(x, y, planet.radius + 7 + Math.sin(clock * 5) * 2, 0, TAU);
      ctx.stroke();
    }
    if (planet.hasSpikes) drawSpikes(planet, x, y);
    ctx.restore();
  }

  function drawSpikes(planet, x, y) {
    for (const angle of planet.spikeAngles) {
      ctx.save();
      ctx.translate(x + Math.cos(angle) * planet.radius * 0.82, y + Math.sin(angle) * planet.radius * 0.82);
      ctx.rotate(angle + Math.PI / 2);
      ctx.fillStyle = '#ff7ca8';
      ctx.shadowColor = '#ff7ca8';
      ctx.shadowBlur = 8;
      ctx.beginPath();
      ctx.moveTo(0, -9);
      ctx.lineTo(6, 5);
      ctx.lineTo(-6, 5);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    }
  }

  function drawOrbitGate() {
    if (!current || mode !== 'ready') return;
    const cx = current.x;
    const cy = current.y - cameraY;
    ctx.save();
    ctx.shadowBlur = 12;
    ctx.shadowColor = '#ffd879';
    ctx.strokeStyle = 'rgba(255,216,121,.95)';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, current.orbitRadius + 5, idealAngle - 0.12, idealAngle + 0.12);
    ctx.stroke();
    ctx.restore();
  }

  function drawPickups() {
    for (const pickup of pickups) {
      if (pickup.collected) continue;
      const x = pickup.x;
      const y = pickup.y - cameraY + Math.sin(clock * 3 + pickup.phase) * 2;
      const gem = pickup.kind === 'gem';
      ctx.save();
      ctx.shadowColor = gem ? '#bb91ff' : '#ffd879';
      ctx.shadowBlur = gem ? 13 : 9;
      if (gem) {
        ctx.fillStyle = '#c4a0ff';
        ctx.beginPath();
        ctx.moveTo(x, y - 8);
        ctx.lineTo(x + 6, y);
        ctx.lineTo(x, y + 8);
        ctx.lineTo(x - 6, y);
        ctx.closePath();
        ctx.fill();
      } else {
        ctx.fillStyle = '#ffd879';
        ctx.beginPath();
        ctx.arc(x, y, 5, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#fff0b3';
        ctx.beginPath();
        ctx.arc(x, y, 2, 0, TAU);
        ctx.fill();
      }
      ctx.restore();
    }
  }

  function drawTrail() {
    if (trail.length < 2) return;
    ctx.save();
    for (let i = 0; i < trail.length - 1; i += 1) {
      const alpha = (1 - i / trail.length) * 0.48;
      ctx.strokeStyle = `rgba(120,241,255,${alpha})`;
      ctx.lineWidth = Math.max(1, 7 * (1 - i / trail.length));
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(trail[i].x, trail[i].y - cameraY);
      ctx.lineTo(trail[i + 1].x, trail[i + 1].y - cameraY);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawBlob(x, y, radius, color) {
    ctx.save();
    ctx.shadowColor = color;
    ctx.shadowBlur = 19;
    const blob = ctx.createRadialGradient(x - radius * 0.34, y - radius * 0.48, 2, x, y, radius * 1.2);
    blob.addColorStop(0, '#ffffff');
    blob.addColorStop(0.27, color);
    blob.addColorStop(1, '#415179');
    ctx.fillStyle = blob;
    ctx.beginPath();
    ctx.ellipse(x, y, radius * 1.05, radius * 0.94, 0, 0, TAU);
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.fillStyle = '#1c2941';
    ctx.beginPath();
    ctx.ellipse(x - 4.2, y - 1, 1.6, 2.1, 0, 0, TAU);
    ctx.ellipse(x + 4.2, y - 1, 1.6, 2.1, 0, 0, TAU);
    ctx.fill();
    ctx.strokeStyle = '#1c2941';
    ctx.lineWidth = 1.2;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.arc(x, y + 1.4, 3.4, 0.2, Math.PI - 0.2);
    ctx.stroke();
    ctx.restore();
  }

  function drawParticles() {
    for (const p of particles) {
      const alpha = clamp(p.life / p.maxLife, 0, 1);
      const y = p.y - cameraY;
      ctx.globalAlpha = alpha;
      ctx.fillStyle = p.color;
      ctx.strokeStyle = p.color;
      if (p.spark) {
        ctx.lineWidth = Math.max(1, p.r * 0.7);
        ctx.beginPath();
        ctx.moveTo(p.x, y);
        ctx.lineTo(p.x - p.vx * 0.018, y - p.vy * 0.018);
        ctx.stroke();
      } else {
        ctx.beginPath();
        ctx.arc(p.x, y, p.r, 0, TAU);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
    }
  }

  function drawPerfectLabel() {
    const alpha = clamp(perfectFlash / 0.8, 0, 1);
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.textAlign = 'center';
    ctx.font = '700 13px system-ui, sans-serif';
    ctx.fillStyle = '#ffe17a';
    ctx.shadowColor = '#ffc55f';
    ctx.shadowBlur = 14;
    ctx.fillText('PERFECT!', player.x, player.y - cameraY - 29);
    ctx.restore();
  }


  function frame(now) {
    const elapsed = lastFrame ? Math.min(0.06, (now - lastFrame) / 1000) : 0;
    lastFrame = now;
    if (mode !== 'paused' && mode !== 'title' && mode !== 'gameover') update(elapsed);
    else {
      clock += elapsed;
      if (mode === 'title' && current) {
        playerAngle += current.spinSpeed * current.spinDirection * elapsed;
        player = orbitPoint(current, playerAngle);
      }
    }
    draw();
    requestAnimationFrame(frame);
  }

  function startTitleScene() {
    seed = 0x4f524249;
    current = {
      x: WIDTH / 2,
      baseX: WIDTH / 2,
      y: HEIGHT * 0.62,
      radius: 37,
      orbitRadius: 72,
      spinSpeed: 1.22,
      spinDirection: 1,
      phase: 0,
      moving: false,
      motionAmplitude: 0,
      motionFrequency: 0,
      shrinking: false,
      hasSpikes: false,
      spikeAngles: [],
      shrinkRate: 0,
    };
    dangerY = current.y + HEIGHT * 1.12;
    score = 0;
    makeNextPlanet();
    playerAngle = idealAngle - 0.8;
    player = orbitPoint(current, playerAngle);
    mode = 'title';
    showOverlay('title');
    updateHud(true);
  }

  function onPointerDown(event) {
    if (event.target.closest('button')) return;
    if (mode === 'title') return;
    if (mode === 'ready') launch();
    else if (mode === 'gameover') resetRun();
  }

  stage.addEventListener('pointerdown', onPointerDown);
  overlayButton.addEventListener('click', () => {
    if (mode === 'paused') resume();
    else resetRun();
  });
  pauseButton.addEventListener('click', (event) => {
    event.stopPropagation();
    pause();
  });
  document.getElementById('resetButton').addEventListener('click', resetRun);
  document.addEventListener('keydown', (event) => {
    if (event.code !== 'Space' && event.code !== 'Enter') return;
    event.preventDefault();
    if (mode === 'title' || mode === 'gameover') resetRun();
    else if (mode === 'ready') launch();
    else if (mode === 'paused') resume();
  });
  window.addEventListener('resize', resize);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && (mode === 'ready' || mode === 'flight')) pause();
  });

  resize();
  startTitleScene();
  requestAnimationFrame(frame);
})();
