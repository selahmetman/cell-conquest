import express from "express";
import cors from "cors";
import { WebSocketServer, WebSocket } from "ws";
import { createServer } from "http";
import { GameRoom } from "./rooms/GameRoom";

const PORT = Number(process.env.PORT) || 2567;
const app  = express();

app.use(cors());
app.use(express.json());
app.get("/health", (_req, res) => res.json({ status: "ok" }));

const httpServer = createServer(app);
const wss = new WebSocketServer({ server: httpServer });

// Room pool: one active room, create new when full
const rooms: GameRoom[] = [];

function getOrCreateRoom(): GameRoom {
  const available = rooms.find(r => !r.isFull);
  if (available) return available;
  const room = new GameRoom();
  rooms.push(room);
  return room;
}

wss.on("connection", (ws: WebSocket) => {
  let room: GameRoom | null = null;
  let playerId: string | null = null;

  ws.on("message", (raw: Buffer) => {
    let msg: { type: string; name?: string; from?: number; to?: number };
    try { msg = JSON.parse(raw.toString()); } catch { return; }

    if (msg.type === "join") {
      room = getOrCreateRoom();
      playerId = room.join(ws, msg.name ?? "Oyuncu");
      return;
    }

    if (room && playerId) room.handleMessage(playerId, msg);
  });

  ws.on("close", () => {
    if (room && playerId) room.leave(playerId);
  });
});

httpServer.listen(PORT, () => {
  console.log(`Cell Conquest sunucu çalışıyor → ws://localhost:${PORT}`);
});
