import { Schema, MapSchema, ArraySchema, type } from "@colyseus/schema";

export class CellState extends Schema {
  @type("uint8")  id: number = 0;
  @type("string") owner: string = "";      // player session id, "" = neutral
  @type("uint16") strength: number = 0;
  @type("float32") x: number = 0;
  @type("float32") y: number = 0;
  @type("float32") radius: number = 50;
}

export class PlayerState extends Schema {
  @type("string") id: string = "";
  @type("string") name: string = "Player";
  @type("uint8")  cellCount: number = 0;
  @type("boolean") connected: boolean = true;
}

export class TroopMovement extends Schema {
  @type("uint8")  fromId: number = 0;
  @type("uint8")  toId: number = 0;
  @type("uint16") amount: number = 0;
  @type("string") ownerId: string = "";
  @type("float32") progress: number = 0;   // 0.0 → 1.0
}

export class GameState extends Schema {
  @type("float32")                   timeRemaining: number = 180;
  @type("boolean")                   gameActive: boolean = false;
  @type({ map: PlayerState })        players = new MapSchema<PlayerState>();
  @type({ array: CellState })        cells = new ArraySchema<CellState>();
  @type({ array: TroopMovement })    movements = new ArraySchema<TroopMovement>();
}
