package commands {
	import flash.utils.getTimer;
	import engine.BotEngine;

	public class JoinCommand extends BotCommand {

		public var map:String = "";
		public var cell:String = "Enter";
		public var pad:String = "Spawn";

		private var combatExitAttempts:int = 0;

		public function JoinCommand(map:String = "", cell:String = "Enter", pad:String = "Spawn") {
			super(BotCommand.TYPE_JOIN);
			this.map = (map != null) ? map : "";
			this.cell = (cell != null && cell.length > 0) ? cell : "Enter";
			this.pad = (pad != null && pad.length > 0) ? pad : "Spawn";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"map": map,
					"cell": cell,
					"pad": pad
				};
		}

		public static function fromJSON(data:Object):JoinCommand {
			if (data == null)
				return null;
			return new JoinCommand(
					data.map || "",
					data.cell || "Enter",
					data.pad || "Spawn"
				);
		}

		private function isPlayerInCombat(game:Object):Boolean {
			try {
				if (game != null && game.world != null && game.world.myAvatar != null) {
					if (game.world.myAvatar.dataLeaf != null && game.world.myAvatar.dataLeaf.intState == 2) {
						return true;
					}
					if (game.world.myAvatar.target != null) {
						return true;
					}
				}
			}
			catch (e:Error) {
			}
			return false;
		}

		private function leaveCombat(game:Object, bot:BotEngine):void {
			try {
				if (game.world.cancelTarget != null) {
					game.world.cancelTarget();
				}
				if (game.world.cancelAutoAttack != null) {
					game.world.cancelAutoAttack();
				}
				if (game.world.exitCombat != null) {
					game.world.exitCombat();
				}
				if (game.world.setTarget != null) {
					game.world.setTarget(null);
				}
			}
			catch (e:Error) {
				bot.log("[Join] Leave combat error: " + e.message);
			}
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null) {
				bot.log("[Join] Error: Game or World instance not found.");
				bot.advanceStep();
				return;
			}

			try {
				var targetMap:String = (map != null) ? map : "";
				var targetCell:String = (cell != null && cell.length > 0) ? cell : "Enter";
				var targetPad:String = (pad != null && pad.length > 0) ? pad : "Spawn";

				if (targetMap.length == 0) {
					bot.log("[Join] Error: Map name is empty.");
					bot.advanceStep();
					return;
				}

				var currentArea:String = (game.world.strAreaName != null) ? game.world.strAreaName : "";
				var currentMapName:String = (currentArea.indexOf("-") > -1) ? currentArea.split("-")[0].toLowerCase() : currentArea.toLowerCase();
				var targetMapName:String = (targetMap.indexOf("-") > -1) ? targetMap.split("-")[0].toLowerCase() : targetMap.toLowerCase();

				// Check if we need to transfer to a different map or specific room
				var needsTransfer:Boolean = false;
				if (targetMap.indexOf("-") > -1) {
					// Target specifies an exact room number (e.g. "battleon-1234")
					needsTransfer = (currentArea.toLowerCase() != targetMap.toLowerCase());
				}
				else {
					// Target is general map name (e.g. "battleon")
					needsTransfer = (currentMapName != targetMapName || currentArea.length == 0);
				}

				if (needsTransfer) {
					// Pastikan leave combat terlebih dahulu sebelum join map
					if (isPlayerInCombat(game) && combatExitAttempts < 3) {
						combatExitAttempts++;
						bot.log("[Join] Player in combat. Leaving combat first (attempt " + combatExitAttempts + ")...");
						leaveCombat(game, bot);
						// Reposisi / jump cell untuk memutuskan aggro monster jika memungkinkan
						if (game.world.moveToCell != null && game.world.strFrame != null) {
							var curPad:String = (game.world.strPad != null && game.world.strPad.length > 0) ? game.world.strPad : "Spawn";
							game.world.moveToCell(game.world.strFrame, curPad);
						}
						return; // Tunggu tick berikutnya (500ms) agar combat lepas sebelum join
					}

					combatExitAttempts = 0;
					leaveCombat(game, bot);

					bot.log("[Join] Joining map: " + targetMap + " [" + targetCell + ", " + targetPad + "] (current: " + (currentArea.length > 0 ? currentArea : "none") + ")");
					// AQW World.gotoTown requires 3 arguments: (mapName:String, cell:String, pad:String)
					game.world.gotoTown(targetMap, targetCell, targetPad);
					bot.advanceStep(3000); // Beri jeda 3 detik agar map dan asset selesai dimuat
					return;
				}

				combatExitAttempts = 0;

				// Already in the correct map, just jump to cell and pad if needed
				var currentCell:String = (game.world.strFrame != null) ? game.world.strFrame : "";
				if (currentCell.toLowerCase() != targetCell.toLowerCase()) {
					bot.log("[Join] Already in " + currentArea + ", moving to [" + targetCell + ", " + targetPad + "]");
					game.world.moveToCell(targetCell, targetPad);
				}
				else {
					bot.log("[Join] Already at " + currentArea + " [" + targetCell + ", " + targetPad + "]");
				}
				bot.advanceStep();
			}
			catch (e:Error) {
				combatExitAttempts = 0;
				var errMsg:String = "[Join] Error: " + e.name + " - " + e.message;
				bot.log(errMsg);
				trace(errMsg);
				bot.advanceStep();
			}
		}

		override public function toString():String {
			return "Join [" + map + ", " + cell + ", " + pad + "]";
		}
	}
}
