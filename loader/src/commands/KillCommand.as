package commands {

	import engine.AutoBattle;
	import engine.BotEngine;

	public class KillCommand extends BotCommand {

		public static const MODE_NONE:String = "none";
		public static const MODE_COUNT:String = "count";
		public static const MODE_ITEM:String = "item";

		public var monster:String = "*";
		public var killMode:String = MODE_NONE;
		public var killCount:int = 1;
		public var itemName:String = "";
		public var itemQty:int = 1;

		public function KillCommand(
				monster:String = "*",
				killMode:String = MODE_NONE,
				killCount:int = 1,
				itemName:String = "",
				itemQty:int = 1
			) {
			super(BotCommand.TYPE_KILL);
			this.monster = (monster != null && monster.length > 0) ? monster : "*";
			this.killMode = (killMode != null) ? killMode : MODE_NONE;
			this.killCount = Math.max(1, killCount);
			this.itemName = (itemName != null) ? itemName : "";
			this.itemQty = Math.max(1, itemQty);
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"monster": monster,
					"killMode": killMode,
					"killCount": killCount,
					"itemName": itemName,
					"itemQty": itemQty
				};
		}

		public static function fromJSON(data:Object):KillCommand {
			if (data == null)
				return null;
			return new KillCommand(
					data.monster || "*",
					data.killMode || MODE_NONE,
					int(data.killCount || 1),
					data.itemName || "",
					int(data.itemQty || 1)
				);
		}

		override public function execute(bot:BotEngine):void {
			// 1. Check if condition already satisfied
			if (killMode == MODE_ITEM) {
				var currentQty:int = bot.getItemQuantity(itemName);
				if (currentQty >= itemQty) {
					bot.log("Kill requirement met: Item [" + itemName + "] count is " + currentQty + "/" + itemQty);
					bot.leaveCombat();
					bot.advanceStep();
					return;
				}
			}
			else if (killMode == MODE_COUNT) {
				if (bot.currentKillsForStep >= killCount) {
					bot.log("Kill requirement met: Killed [" + monster + "] " + bot.currentKillsForStep + "/" + killCount + " times.");
					bot.leaveCombat();
					bot.advanceStep();
					return;
				}
			}

			// 2. Target selection & Combat
			var game:Object = bot.getGame();
			if (game == null || game.world == null)
				return;

			var myAvatar:Object = game.world.myAvatar;
			if (myAvatar == null)
				return;

			var curTarget:Object = myAvatar.target;

			// Track kill count on target death
			if (curTarget != null && curTarget.dataLeaf != null) {
				if (curTarget.dataLeaf.intHP > 0) {
					bot.targetWasAlive = true;
				}
				else if (bot.targetWasAlive && curTarget.dataLeaf.intHP <= 0) {
					bot.currentKillsForStep++;
					bot.targetWasAlive = false;

					if (killMode == MODE_NONE) {
						bot.leaveCombat();
						bot.advanceStep();
						return;
					}
				}
			}

			// Find monster if no active living target
			if (curTarget == null || curTarget.dataLeaf == null || curTarget.dataLeaf.intHP <= 0) {
				var target:Object = bot.getMonsterByName(monster);
				if (target != null) {
					game.world.setTarget(target);
					bot.targetWasAlive = (target.dataLeaf.intHP > 0);
				}
				return;
			}

			// Approach & use skills
			try {
				game.world.approachTarget();
				AutoBattle.useSmartSkill(game);
			}
			catch (e:Error) {
			}
		}

		override public function toString():String {
			if (killMode == MODE_ITEM) {
				return "Kill [" + monster + "] for " + itemName + " (" + itemQty + ")";
			}
			else if (killMode == MODE_COUNT) {
				return "Kill [" + monster + "] x" + killCount;
			}
			else {
				return "Kill [" + monster + "]";
			}
		}
	}
}
