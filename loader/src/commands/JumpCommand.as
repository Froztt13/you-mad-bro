package commands {

	import engine.BotEngine;

	public class JumpCommand extends BotCommand {

		public var cell:String = "Enter";
		public var pad:String = "Spawn";

		public function JumpCommand(cell:String = "Enter", pad:String = "Spawn") {
			super(BotCommand.TYPE_JUMP);
			this.cell = (cell != null && cell.length > 0) ? cell : "Enter";
			this.pad = (pad != null && pad.length > 0) ? pad : "Spawn";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"cell": cell,
					"pad": pad
				};
		}

		public static function fromJSON(data:Object):JumpCommand {
			if (data == null)
				return null;
			return new JumpCommand(
					data.cell || "Enter",
					data.pad || "Spawn"
				);
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null) {
				bot.log("[Jump] Error: Game or World instance not found.");
				bot.advanceStep();
				return;
			}

			try {
				game.world.moveToCell(cell, pad);
				bot.log("[Jump] Moved to cell [" + cell + ", " + pad + "]");
			}
			catch (e:Error) {
				var errMsg:String = "[Jump] Error: " + e.name + " - " + e.message;
				bot.log(errMsg);
				trace(errMsg);
			}
			bot.advanceStep();
		}

		override public function toString():String {
			return "Jump [" + cell + ", " + pad + "]";
		}
	}
}
