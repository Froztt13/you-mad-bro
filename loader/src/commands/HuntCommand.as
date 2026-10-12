package commands {

	import engine.AutoBattle;
	import engine.BotEngine;

	public class HuntCommand extends KillCommand {

		public function HuntCommand(
				monster:String = "*",
				killMode:String = MODE_NONE,
				killCount:int = 1,
				itemName:String = "",
				itemQty:int = 1
			) {
			super(monster, killMode, killCount, itemName, itemQty);
			this.type = BotCommand.TYPE_HUNT;
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

		public static function fromJSON(data:Object):HuntCommand {
			if (data == null)
				return null;
			return new HuntCommand(
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
					bot.log("[Hunt] Requirement met: Item [" + itemName + "] count is " + currentQty + "/" + itemQty);
					bot.leaveCombat();
					bot.advanceStep();
					return;
				}
			}
			else if (killMode == MODE_COUNT) {
				if (bot.currentKillsForStep >= killCount) {
					bot.log("[Hunt] Requirement met: Killed [" + monster + "] " + bot.currentKillsForStep + "/" + killCount + " times.");
					bot.leaveCombat();
					bot.advanceStep();
					return;
				}
			}

			// 2. Validate Game & World instances
			var game:Object = bot.getGame();
			if (game == null || game.world == null)
				return;

			var myAvatar:Object = game.world.myAvatar;
			if (myAvatar == null)
				return;

			var curTarget:Object = myAvatar.target;

			// 3. Track kill count on target death
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

			// 4. Target selection & Auto-jump to alive monster cell
			if (curTarget == null || curTarget.dataLeaf == null || curTarget.dataLeaf.intHP <= 0) {
				// 4a. Check if alive monster exists in the CURRENT cell
				var localTarget:Object = bot.getMonsterByName(monster);
				if (localTarget != null) {
					game.world.setTarget(localTarget);
					bot.targetWasAlive = (localTarget.dataLeaf.intHP > 0);
					return;
				}

				// 4b. No alive monster in current cell. Search all monsters in the map for an alive one
				var aliveMonster:Object = findAliveMonster(game, monster);
				if (aliveMonster != null && aliveMonster.dataLeaf != null) {
					var targetCell:String = aliveMonster.dataLeaf.strFrame;
					var curCell:String = (game.world.strFrame != null) ? game.world.strFrame : "";

					if (targetCell != null && targetCell.length > 0 && targetCell.toLowerCase() != curCell.toLowerCase()) {
						bot.log("[Hunt] Monster [" + monster + "] alive in cell [" + targetCell + "]. Jumping...");
						jumpToCell(game, targetCell);
						bot.delay(1000); // Jeda 1 detik agar transisi sel dan asset monster dimuat
						return;
					}
					else {
						// Sudah berada di sel yang sama, langsung kunci target
						game.world.setTarget(aliveMonster);
						bot.targetWasAlive = (aliveMonster.dataLeaf.intHP > 0);
						return;
					}
				}

				// 4c. Jika monster belum spawn di sel manapun (sedang respawn):
				// Pastikan player menunggu di sel tempat monster tersebut biasa spawn
				var inSpawnCell:Boolean = isCurrentCellMonsterSpawn(game, monster);
				if (!inSpawnCell) {
					var spawnCell:String = findMonsterSpawnCell(game, monster);
					if (spawnCell != null && spawnCell.length > 0 && spawnCell.toLowerCase() != (game.world.strFrame ? game.world.strFrame.toLowerCase() : "")) {
						bot.log("[Hunt] No alive [" + monster + "] found. Moving to spawn cell [" + spawnCell + "] to wait for respawn...");
						jumpToCell(game, spawnCell);
						bot.delay(1000);
						return;
					}
				}

				return;
			}

			// 5. Approach & smart combat
			try {
				game.world.approachTarget();
				AutoBattle.useSmartSkill(game);
			}
			catch (e:Error) {
			}
		}

		private function findAliveMonster(game:Object, nameFilter:String):Object {
			if (game == null || game.world == null || game.world.monsters == null)
				return null;

			var cleanFilter:String = (nameFilter != null) ? nameFilter.toLowerCase() : "*";

			try {
				var mons:* = game.world.monsters;
				for each (var m:Object in mons) {
					if (m != null && m.dataLeaf != null) {
						var isAlive:Boolean = (int(m.dataLeaf.intState) > 0 && int(m.dataLeaf.intHP) > 0);
						if (isAlive && matchesMonsterName(m, cleanFilter)) {
							return m;
						}
					}
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		private function isCurrentCellMonsterSpawn(game:Object, nameFilter:String):Boolean {
			if (game == null || game.world == null || game.world.strFrame == null)
				return false;

			var curCell:String = String(game.world.strFrame).toLowerCase();
			var cleanFilter:String = (nameFilter != null) ? nameFilter.toLowerCase() : "*";

			try {
				var mons:* = game.world.monsters;
				if (mons != null) {
					for each (var m:Object in mons) {
						if (m != null && m.dataLeaf != null && m.dataLeaf.strFrame != null) {
							if (String(m.dataLeaf.strFrame).toLowerCase() == curCell && matchesMonsterName(m, cleanFilter)) {
								return true;
							}
						}
					}
				}
			}
			catch (e:Error) {
			}
			return false;
		}

		private function findMonsterSpawnCell(game:Object, nameFilter:String):String {
			if (game == null || game.world == null || game.world.monsters == null)
				return null;

			var cleanFilter:String = (nameFilter != null) ? nameFilter.toLowerCase() : "*";

			try {
				var mons:* = game.world.monsters;
				for each (var m:Object in mons) {
					if (m != null && m.dataLeaf != null && m.dataLeaf.strFrame != null) {
						if (matchesMonsterName(m, cleanFilter)) {
							return String(m.dataLeaf.strFrame);
						}
					}
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		private function matchesMonsterName(mon:Object, filter:String):Boolean {
			if (mon == null)
				return false;
			if (filter == "*" || filter == "" || filter == null)
				return true;

			// Check objData.strMonName
			if (mon.objData != null && mon.objData.strMonName != null) {
				var name1:String = String(mon.objData.strMonName).toLowerCase();
				if (name1.indexOf(filter) > -1)
					return true;
			}

			// Check pMC pname ti text
			try {
				if (mon.pMC != null && mon.pMC.pname != null && mon.pMC.pname.ti != null && mon.pMC.pname.ti.text != null) {
					var name2:String = String(mon.pMC.pname.ti.text).toLowerCase();
					if (name2.indexOf(filter) > -1)
						return true;
				}
			}
			catch (e:Error) {
			}

			// Check MonMapID
			if (mon.dataLeaf != null && mon.dataLeaf.MonMapID != null) {
				if (String(mon.dataLeaf.MonMapID) == filter)
					return true;
			}

			return false;
		}

		private function jumpToCell(game:Object, cell:String, pad:String = "Spawn"):void {
			try {
				if (game.world.cancelTarget != null) {
					game.world.cancelTarget();
				}
			}
			catch (e:Error) {
			}

			try {
				game.world.moveToCell(cell, pad);
			}
			catch (e:Error) {
			}
		}

		override public function toString():String {
			if (killMode == MODE_ITEM) {
				return "Hunt [" + monster + "] for " + itemName + " (" + itemQty + ")";
			}
			else if (killMode == MODE_COUNT) {
				return "Hunt [" + monster + "] x" + killCount;
			}
			else {
				return "Hunt [" + monster + "]";
			}
		}
	}
}
