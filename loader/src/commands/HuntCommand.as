package commands {

	import engine.AutoBattle;
	import engine.BotEngine;
	import engine.MapCommands;

	public class HuntCommand extends KillCommand {

		public var mostMonstersOnly:Boolean = true;

		public function HuntCommand(
				monster:String = "*",
				killMode:String = MODE_NONE,
				killCount:int = 1,
				itemName:String = "",
				itemQty:int = 1,
				mostMonstersOnly:Boolean = true
			) {
			super(monster, killMode, killCount, itemName, itemQty);
			this.type = BotCommand.TYPE_HUNT;
			this.mostMonstersOnly = mostMonstersOnly;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"monster": monster,
					"killMode": killMode,
					"killCount": killCount,
					"itemName": itemName,
					"itemQty": itemQty,
					"mostMonstersOnly": mostMonstersOnly
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
					int(data.itemQty || 1),
					("mostMonstersOnly" in data && data.mostMonstersOnly != null) ? Boolean(data.mostMonstersOnly) : true
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

			try {
				if (game.world.setSpawnPoint != null && game.world.strFrame != null && game.world.strPad != null) {
					game.world.setSpawnPoint(game.world.strFrame, game.world.strPad);
				}
			}
			catch (eSpawn:Error) {
			}

			var myAvatar:Object = game.world.myAvatar;
			if (myAvatar == null)
				return;

			var curTarget:Object = myAvatar.target;

			// Verify if curTarget is the monster we are actually hunting (exact match)
			var targetMatches:Boolean = (curTarget != null && matchesMonsterName(curTarget, monster));
			if (curTarget != null && !targetMatches) {
				// Target is a different monster (e.g. Luxuria Guard when hunting Luxuria)
				curTarget = null;
				try {
					if (game.world != null && game.world.cancelTarget != null) {
						game.world.cancelTarget();
					}
				}
				catch (eCancel:Error) {
				}
			}

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

			// 4. Mode-specific behavior:
			// If mostMonstersOnly is true, stay exclusively in the 1 cell with the most monsters
			if (mostMonstersOnly) {
				var curCellStr:String = (game.world.strFrame != null) ? String(game.world.strFrame) : "";
				var bestCell:String = findCellWithMostMonsters(game, monster);

				// If bestCell is found and player is not there yet, jump there
				if (bestCell != null && bestCell.length > 0 && bestCell.toLowerCase() != curCellStr.toLowerCase()) {
					bot.log("[Hunt] Moving to cell [" + bestCell + "] with most [" + monster + "]...");
					jumpToCell(bot, game, bestCell);
					bot.delay(1000);
					return;
				}

				// Inside bestCell: target alive monster in current cell without jumping around
				if (curTarget == null || curTarget.dataLeaf == null || curTarget.dataLeaf.intHP <= 0) {
					var localTgt:Object = findAliveMonsterInCell(game, curCellStr, monster);
					if (localTgt != null) {
						game.world.setTarget(localTgt);
						bot.targetWasAlive = (localTgt.dataLeaf.intHP > 0);
						return;
					}
					// No alive monster in current cell: wait here for respawn (no jumping!)
					return;
				}
			}
			else {
				// 4. Default Hunt: Target selection & Auto-jump to alive monster across cells
				if (curTarget == null || curTarget.dataLeaf == null || curTarget.dataLeaf.intHP <= 0) {
					// 4a. Check if alive monster exists in the CURRENT cell
					var curCell:String = (game.world.strFrame != null) ? game.world.strFrame : "";
					var localTarget:Object = findAliveMonsterInCell(game, curCell, monster);
					if (localTarget != null) {
						game.world.setTarget(localTarget);
						bot.targetWasAlive = (localTarget.dataLeaf.intHP > 0);
						return;
					}

					// 4b. No alive monster in current cell. Search all monsters in the map for an alive one
					var aliveMonster:Object = findAliveMonster(game, monster);
					if (aliveMonster != null && aliveMonster.dataLeaf != null) {
						var targetCell:String = aliveMonster.dataLeaf.strFrame;

						if (targetCell != null && targetCell.length > 0 && targetCell.toLowerCase() != curCell.toLowerCase()) {
							bot.log("[Hunt] Monster [" + monster + "] alive in cell [" + targetCell + "]. Jumping...");
							jumpToCell(bot, game, targetCell);
							bot.delay(1000); // Wait 1 second for cell transition and monster assets to load
							return;
						}
						else {
							// Already in the same cell, lock target immediately
							game.world.setTarget(aliveMonster);
							bot.targetWasAlive = (aliveMonster.dataLeaf.intHP > 0);
							return;
						}
					}

					// 4c. If the monster has not spawned in any cell yet (respawning):
					// Ensure player waits in the cell where this monster normally spawns
					var inSpawnCell:Boolean = isCurrentCellMonsterSpawn(game, monster);
					if (!inSpawnCell) {
						var spawnCell:String = findMonsterSpawnCell(game, monster);
						if (spawnCell != null && spawnCell.length > 0 && spawnCell.toLowerCase() != (game.world.strFrame ? game.world.strFrame.toLowerCase() : "")) {
							bot.log("[Hunt] No alive [" + monster + "] found. Moving to spawn cell [" + spawnCell + "] to wait for respawn...");
							jumpToCell(bot, game, spawnCell);
							bot.delay(1000);
							return;
						}
					}

					return;
				}
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

		private function findAliveMonsterInCell(game:Object, cell:String, nameFilter:String):Object {
			if (game == null || game.world == null)
				return null;

			var cleanFilter:String = (nameFilter != null) ? nameFilter : "*";
			var targetCell:String = (cell != null) ? cell.toLowerCase() : "";

			try {
				if (game.world.getMonstersByCell != null) {
					var cellMons:Array = game.world.getMonstersByCell(game.world.strFrame);
					if (cellMons != null) {
						for each (var m1:Object in cellMons) {
							if (m1 != null && m1.dataLeaf != null) {
								var isAlive1:Boolean = (int(m1.dataLeaf.intState) > 0 && int(m1.dataLeaf.intHP) > 0);
								if (isAlive1 && matchesMonsterName(m1, cleanFilter)) {
									return m1;
								}
							}
						}
					}
				}

				var mons:* = game.world.monsters;
				if (mons != null) {
					for each (var m2:Object in mons) {
						if (m2 != null && m2.dataLeaf != null && m2.dataLeaf.strFrame != null) {
							if (String(m2.dataLeaf.strFrame).toLowerCase() == targetCell) {
								var isAlive2:Boolean = (int(m2.dataLeaf.intState) > 0 && int(m2.dataLeaf.intHP) > 0);
								if (isAlive2 && matchesMonsterName(m2, cleanFilter)) {
									return m2;
								}
							}
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
			if (filter == null || filter == "*" || filter == "")
				return true;

			var cleanFilter:String = filter.replace(/^\s+|\s+$/g, "").toLowerCase();
			if (cleanFilter == "*" || cleanFilter == "")
				return true;

			// Check MonMapID
			if (mon.dataLeaf != null && mon.dataLeaf.MonMapID != null) {
				if (String(mon.dataLeaf.MonMapID) == cleanFilter)
					return true;
			}

			// Check objData.strMonName (Exact match, case-insensitive)
			if (mon.objData != null && mon.objData.strMonName != null) {
				var name1:String = String(mon.objData.strMonName).replace(/^\s+|\s+$/g, "").toLowerCase();
				if (name1 == cleanFilter)
					return true;
			}

			// Check pMC pname ti text (Exact match, case-insensitive)
			try {
				if (mon.pMC != null && mon.pMC.pname != null && mon.pMC.pname.ti != null && mon.pMC.pname.ti.text != null) {
					var name2:String = String(mon.pMC.pname.ti.text).replace(/^\s+|\s+$/g, "").toLowerCase();
					if (name2 == cleanFilter)
						return true;
				}
			}
			catch (e:Error) {
			}

			return false;
		}

		private function jumpToCell(bot:BotEngine, game:Object, cell:String, pad:String = "*"):void {
			try {
				if (game.world != null && game.world.cancelTarget != null) {
					game.world.cancelTarget();
				}
			}
			catch (e:Error) {
			}

			try {
				var mapCmd:MapCommands = (bot != null) ? bot.getMapCommands() : null;
				if (mapCmd != null) {
					mapCmd.smartJump(cell, pad);
				}
				else if (game.world != null) {
					game.world.moveToCell(cell, (pad == "*") ? "Spawn" : pad);
				}
			}
			catch (e:Error) {
			}
		}

		public function findCellWithMostMonsters(game:Object, nameFilter:String):String {
			if (game == null || game.world == null || game.world.monsters == null)
				return null;

			var cleanFilter:String = (nameFilter != null) ? nameFilter.toLowerCase() : "*";
			var curCell:String = (game.world.strFrame != null) ? String(game.world.strFrame).toLowerCase() : "";

			try {
				var mons:* = game.world.monsters;
				var cellCounts:Object = {};
				var cellOrigName:Object = {};

				for each (var m:Object in mons) {
					if (m != null && m.dataLeaf != null && m.dataLeaf.strFrame != null) {
						var rawCell:String = String(m.dataLeaf.strFrame);
						if (rawCell.length > 0 && matchesMonsterName(m, cleanFilter)) {
							var lowerCell:String = rawCell.toLowerCase();
							if (cellCounts[lowerCell] == null) {
								cellCounts[lowerCell] = 0;
								cellOrigName[lowerCell] = rawCell;
							}
							cellCounts[lowerCell]++;
						}
					}
				}

				var maxCount:int = 0;
				var bestCellLower:String = null;

				for (var c:String in cellCounts) {
					var count:int = int(cellCounts[c]);
					if (count > maxCount) {
						maxCount = count;
						bestCellLower = c;
					}
					else if (count == maxCount && c == curCell) {
						// Prefer staying in current cell if it's tied for the maximum count
						bestCellLower = c;
					}
				}

				if (bestCellLower != null) {
					return cellOrigName[bestCellLower];
				}
			}
			catch (e:Error) {
			}

			return null;
		}

		override public function toString():String {
			var suffix:String = mostMonstersOnly ? " [Most Only]" : "";
			if (killMode == MODE_ITEM) {
				return "Hunt [" + monster + "] for " + itemName + " (" + itemQty + ")" + suffix;
			}
			else if (killMode == MODE_COUNT) {
				return "Hunt [" + monster + "] x" + killCount + suffix;
			}
			else {
				return "Hunt [" + monster + "]" + suffix;
			}
		}
	}
}
