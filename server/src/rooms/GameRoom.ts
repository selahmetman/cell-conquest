import { Room, Client } from "@colyseus/core";
import { GameState, CellState, PlayerState, TroopMovement } from "../schema/GameState";

const TICK_RATE       = 20;          // Hz
const GROWTH_INTERVAL = 1000;        // ms
const GAME_DURATION   = 180;         // seconds
const TROOP_SPEED     = 200;         // pixels/second
const MIN_SEND_RATIO  = 0.5;         // minimum fraction of strength to send
const MAX_PLAYERS     = 6;

interface SendTroopsCmd {
  type: "send_troops";
  from: number;
  to: number;
  amount: number;
}

export class GameRoom extends Room<GameState> {
  maxClients = MAX_PLAYERS;
  private _growthTimer = 0;
  private _tickInterval!: ReturnType<typeof setInterval>;

  onCreate(_options: unknown) {
    this.setState(new GameState());
    this._spawnCells();
    this.onMessage("send_troops", (client, msg: SendTroopsCmd) => {
      this._handleSendTroops(client.sessionId, msg);
    });
  }

  onJoin(client: Client, options: { name?: string }) {
    const player = new PlayerState();
    player.id   = client.sessionId;
    player.name = options?.name ?? `Player ${this.clients.length}`;
    this.state.players.set(client.sessionId, player);

    this._assignStartingCell(client.sessionId);

    if (this.clients.length >= 2 && !this.state.gameActive) {
      this._startGame();
    }
  }

  onLeave(client: Client, _consented: boolean) {
    const player = this.state.players.get(client.sessionId);
    if (player) player.connected = false;
  }

  onDispose() {
    clearInterval(this._tickInterval);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  private _startGame() {
    this.state.gameActive   = true;
    this.state.timeRemaining = GAME_DURATION;

    this._tickInterval = setInterval(() => this._tick(1 / TICK_RATE), 1000 / TICK_RATE);
  }

  private _tick(dt: number) {
    if (!this.state.gameActive) return;

    this.state.timeRemaining -= dt;
    if (this.state.timeRemaining <= 0) {
      this._endGame();
      return;
    }

    this._growthTimer += dt * 1000;
    if (this._growthTimer >= GROWTH_INTERVAL) {
      this._growthTimer = 0;
      this._applyGrowth();
    }

    this._updateMovements(dt);
    this._updateCellCounts();
  }

  private _applyGrowth() {
    for (const cell of this.state.cells) {
      if (cell.owner !== "" && cell.strength < 100) {
        cell.strength = Math.min(100, cell.strength + 1);
      }
    }
  }

  private _updateMovements(dt: number) {
    const done: TroopMovement[] = [];

    for (const mv of this.state.movements) {
      const from = this.state.cells[mv.fromId];
      const to   = this.state.cells[mv.toId];
      if (!from || !to) { done.push(mv); continue; }

      const dist = Math.hypot(to.x - from.x, to.y - from.y);
      mv.progress += (TROOP_SPEED * dt) / dist;

      if (mv.progress >= 1) {
        this._resolveBattle(mv);
        done.push(mv);
      }
    }

    for (const mv of done) {
      const idx = this.state.movements.indexOf(mv);
      if (idx !== -1) this.state.movements.splice(idx, 1);
    }
  }

  private _resolveBattle(mv: TroopMovement) {
    const target = this.state.cells[mv.toId];
    if (!target) return;

    if (target.owner === mv.ownerId) {
      target.strength = Math.min(100, target.strength + mv.amount);
    } else {
      target.strength -= mv.amount;
      if (target.strength < 0) {
        target.owner    = mv.ownerId;
        target.strength = Math.abs(target.strength);
      }
    }
  }

  private _handleSendTroops(playerId: string, msg: SendTroopsCmd) {
    const from = this.state.cells[msg.from];
    if (!from || from.owner !== playerId || from.strength <= 1) return;

    const amount = Math.floor(from.strength * MIN_SEND_RATIO);
    from.strength -= amount;

    const mv = new TroopMovement();
    mv.fromId   = msg.from;
    mv.toId     = msg.to;
    mv.amount   = amount;
    mv.ownerId  = playerId;
    mv.progress = 0;
    this.state.movements.push(mv);
  }

  private _updateCellCounts() {
    for (const [pid, player] of this.state.players) {
      let count = 0;
      for (const cell of this.state.cells) {
        if (cell.owner === pid) count++;
      }
      player.cellCount = count;
    }
  }

  private _endGame() {
    clearInterval(this._tickInterval);
    this.state.gameActive = false;

    let winnerId = "";
    let maxCells = -1;
    for (const [pid, player] of this.state.players) {
      if (player.cellCount > maxCells) {
        maxCells = player.cellCount;
        winnerId = pid;
      }
    }

    this.broadcast("game_over", { winner_id: winnerId });
  }

  private _spawnCells() {
    // 16 cells in a 4x4 grid layout
    const cols = 4, rows = 4;
    const spacingX = 200, spacingY = 200;
    const offsetX = 300, offsetY = 200;
    let id = 0;

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const cell   = new CellState();
        cell.id      = id++;
        cell.owner   = "";
        cell.strength = 5;
        cell.x       = offsetX + c * spacingX;
        cell.y       = offsetY + r * spacingY;
        cell.radius  = 50;
        this.state.cells.push(cell);
      }
    }
  }

  private _assignStartingCell(playerId: string) {
    const neutralCells = this.state.cells.filter(c => c.owner === "");
    if (neutralCells.length === 0) return;
    const cell   = neutralCells[Math.floor(Math.random() * neutralCells.length)];
    cell.owner   = playerId;
    cell.strength = 20;
  }
}
