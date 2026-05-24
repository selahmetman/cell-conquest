import { WebSocket } from "ws";
import { v4 as uuidv4 } from "uuid";

const TICK_MS        = 50;    // 20 Hz
const GROWTH_MS      = 1000;
const GAME_DURATION  = 180;   // seconds
const TROOP_SPEED    = 200;   // px/s
const MIN_SEND_RATIO = 0.5;
const MAX_PLAYERS    = 6;

interface Cell {
  id: number;
  owner: string;
  strength: number;
  x: number;
  y: number;
  radius: number;
}

interface Movement {
  id: string;
  fromId: number;
  toId: number;
  amount: number;
  ownerId: string;
  progress: number;
  dist: number;
}

interface Player {
  id: string;
  name: string;
  ws: WebSocket;
  cellCount: number;
}

export class GameRoom {
  readonly id: string;
  private players = new Map<string, Player>();
  private cells: Cell[] = [];
  private movements: Movement[] = [];
  private timeRemaining = GAME_DURATION;
  private gameActive = false;
  private tickTimer: ReturnType<typeof setInterval> | null = null;
  private growthAccum = 0;

  constructor() {
    this.id = uuidv4().slice(0, 8);
    this._spawnCells();
  }

  get playerCount() { return this.players.size; }
  get isFull()      { return this.players.size >= MAX_PLAYERS; }

  join(ws: WebSocket, name: string): string {
    const pid = uuidv4().slice(0, 8);
    this.players.set(pid, { id: pid, name, ws, cellCount: 0 });
    this._assignStartingCell(pid);

    ws.send(JSON.stringify({ type: "room_joined", room_id: this.id, player_id: pid }));

    if (this.players.size >= 2 && !this.gameActive) this._startGame();
    else this._broadcastState();

    return pid;
  }

  leave(pid: string) {
    this.players.delete(pid);
    // Neutral the player's cells so others can capture them
    for (const c of this.cells) {
      if (c.owner === pid) { c.owner = ""; c.strength = Math.max(1, Math.floor(c.strength / 2)); }
    }
  }

  handleMessage(pid: string, msg: { type: string; from?: number; to?: number }) {
    if (msg.type === "send_troops" && msg.from !== undefined && msg.to !== undefined) {
      this._sendTroops(pid, msg.from, msg.to);
    }
  }

  private _startGame() {
    this.gameActive = true;
    this.timeRemaining = GAME_DURATION;
    this.tickTimer = setInterval(() => this._tick(), TICK_MS);
    this._broadcast({ type: "game_started" });
  }

  private _tick() {
    this.timeRemaining -= TICK_MS / 1000;

    this.growthAccum += TICK_MS;
    if (this.growthAccum >= GROWTH_MS) {
      this.growthAccum = 0;
      for (const c of this.cells)
        if (c.owner !== "") c.strength = Math.min(100, c.strength + 1);
    }

    // Move troops
    const resolved: Movement[] = [];
    for (const mv of this.movements) {
      mv.progress += (TROOP_SPEED * TICK_MS / 1000) / mv.dist;
      if (mv.progress >= 1) { this._resolve(mv); resolved.push(mv); }
    }
    this.movements = this.movements.filter(m => !resolved.includes(m));

    this._updateCellCounts();
    this._broadcastState();

    if (this.timeRemaining <= 0) this._endGame();
  }

  private _resolve(mv: Movement) {
    const target = this.cells[mv.toId];
    if (!target) return;
    if (target.owner === mv.ownerId) {
      target.strength = Math.min(100, target.strength + mv.amount);
    } else {
      target.strength -= mv.amount;
      if (target.strength < 0) {
        target.owner = mv.ownerId;
        target.strength = Math.abs(target.strength);
      }
    }
  }

  private _sendTroops(pid: string, fromId: number, toId: number) {
    const from = this.cells[fromId];
    if (!from || from.owner !== pid || from.strength <= 1) return;
    const amount = Math.max(1, Math.floor(from.strength * MIN_SEND_RATIO));
    from.strength -= amount;
    const to = this.cells[toId];
    const dist = Math.hypot(to.x - from.x, to.y - from.y);
    this.movements.push({ id: uuidv4(), fromId, toId, amount, ownerId: pid, progress: 0, dist });
  }

  private _updateCellCounts() {
    for (const [pid, p] of this.players)
      p.cellCount = this.cells.filter(c => c.owner === pid).length;
  }

  private _endGame() {
    if (this.tickTimer) { clearInterval(this.tickTimer); this.tickTimer = null; }
    this.gameActive = false;
    let winnerId = "", maxCells = -1;
    for (const [pid, p] of this.players) {
      if (p.cellCount > maxCells) { maxCells = p.cellCount; winnerId = pid; }
    }
    this._broadcast({ type: "game_over", winner_id: winnerId });
  }

  private _broadcastState() {
    const playerList: Record<string, { name: string; cell_count: number }> = {};
    for (const [pid, p] of this.players)
      playerList[pid] = { name: p.name, cell_count: p.cellCount };

    const payload = {
      type: "state",
      time_remaining: Math.max(0, this.timeRemaining),
      game_active: this.gameActive,
      players: playerList,
      cells: this.cells.map(c => ({ id: c.id, owner: c.owner, strength: c.strength, x: c.x, y: c.y, radius: c.radius })),
      movements: this.movements.map(m => ({ from: m.fromId, to: m.toId, progress: m.progress, owner: m.ownerId })),
    };
    this._broadcast(payload);
  }

  private _broadcast(msg: object) {
    const raw = JSON.stringify(msg);
    for (const p of this.players.values())
      if (p.ws.readyState === WebSocket.OPEN) p.ws.send(raw);
  }

  private _spawnCells() {
    const cols = 4, rows = 4, sx = 220, sy = 200, ox = 140, oy = 160;
    let id = 0;
    for (let r = 0; r < rows; r++)
      for (let c = 0; c < cols; c++)
        this.cells.push({ id: id++, owner: "", strength: 5, x: ox + c * sx, y: oy + r * sy, radius: 50 });
  }

  private _assignStartingCell(pid: string) {
    const neutral = this.cells.filter(c => c.owner === "");
    if (!neutral.length) return;
    const cell = neutral[Math.floor(Math.random() * neutral.length)];
    cell.owner = pid;
    cell.strength = 20;
  }
}
