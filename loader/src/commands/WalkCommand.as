package commands {

	import engine.BotEngine;

	public class WalkCommand extends BotCommand {

		public var x:int;
		public var y:int;

		public function WalkCommand(x:* = 0, y:* = 0) {
			super(BotCommand.TYPE_WALK);
			this.x = int(x);
			this.y = int(y);
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"x": x,
					"y": y
				};
		}

		public static function fromJSON(data:Object):WalkCommand {
			if (data == null)
				return null;
			return new WalkCommand(
					int(data.x != null ? data.x : 0),
					int(data.y != null ? data.y : 0)
				);
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null || game.world.myAvatar == null) {
				bot.log("[Walk] Error: Game or avatar not found.");
				bot.advanceStep();
				return;
			}

			try {
				var pMC:Object = game.world.myAvatar.pMC;
				if (pMC != null) {
					var sp:Number = (game.world.WALKSPEED != null && Number(game.world.WALKSPEED) > 0) ? Number(game.world.WALKSPEED) : 12;
					if (pMC.walkTo != null) {
						pMC.walkTo(x, y, sp);
					}
					if (game.world.moveRequest != null) {
						game.world.moveRequest({mc: pMC, tx: x, ty: y, sp: sp});
					}
					bot.log("[Walk] Walking to (" + x + ", " + y + ")");
				}
			}
			catch (e:Error) {
				bot.log("[Walk] Error: " + e.message);
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "Walk [" + x + ", " + y + "]";
		}
	}
}
