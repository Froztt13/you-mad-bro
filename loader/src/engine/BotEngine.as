package engine {

	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import input.PacketLoggerUI;
	import commands.BotCommand;
	import commands.KillCommand;
	import commands.JoinCommand;
	import commands.JumpCommand;
	import commands.DelayCommand;
	import commands.QuestAcceptCommand;
	import commands.QuestCompleteCommand;
	import handler.ItemDropsHandler;
	import input.AutoQuestUI;
	import SFSEvent;
	import Utils;
	import com.aqw.battery.BatteryOptimizer;

	public class BotEngine {

		public static const STATE_IDLE:int = 0;
		public static const STATE_RUNNING:int = 1;
		public static const STATE_PAUSED:int = 2;

		public static const STORAGE_KEY:String = "aqw_bot_config";

		public static var instance:BotEngine;

		private var game:Object;
		private var _state:int = STATE_IDLE;

		// Script commands
		private var _commands:Array = [];
		private var _currentStep:int = 0;
		private var _loop:Boolean = true;
		private var _leaveCombatOnStop:Boolean = true;
		private var _notifyItemDrops:Boolean = true;
		private var _completedLoops:int = 0;
		private var _startTime:Number = 0;
		private var _totalRunningTimeMs:Number = 0;

		// Drop Whitelist
		private var _whitelist:Array = [];
		public var autoQuestList:Array = [];
		// Internal engine timer & execution state
		private var engineTimer:Timer = new Timer(500); // ticks every 500ms
		public var delayTicksRemaining:int = 0;
		public var currentKillsForStep:int = 0;
		public var targetWasAlive:Boolean = false;
		public var nextStepAllowedTime:Number = 0;

		// Event callbacks
		public var onStateChange:Function;
		public var onStepChange:Function;
		public var onLog:Function;
		public var itemDropsHandler:ItemDropsHandler;
		private var _stateListeners:Array = [];

		public function addStateListener(fn:Function):void {
			if (fn != null && _stateListeners.indexOf(fn) == -1) {
				_stateListeners.push(fn);
			}
		}

		public function removeStateListener(fn:Function):void {
			var idx:int = _stateListeners.indexOf(fn);
			if (idx != -1) {
				_stateListeners.splice(idx, 1);
			}
		}

		public function BotEngine(game:Object = null) {
			this.game = game;
			instance = this;
			this.itemDropsHandler = new ItemDropsHandler(game, this);
		}

		public function getGame():Object {
			return game;
		}

		public function setGame(game:Object):void {
			if (this.game == game)
				return;
			this.game = game;
			if (itemDropsHandler != null) {
				itemDropsHandler.setGame(game);
			}
		}

		// =========================================================================
		// Getters & Setters
		// =========================================================================
		public function get state():int {
			return _state;
		}

		public function get isRunning():Boolean {
			return _state == STATE_RUNNING;
		}

		public function get isPaused():Boolean {
			return _state == STATE_PAUSED;
		}

		public function get completedLoops():int {
			return _completedLoops;
		}

		public function get runningTimeSeconds():int {
			if (_state == STATE_RUNNING) {
				return Math.floor((_totalRunningTimeMs + (flash.utils.getTimer() - _startTime)) / 1000);
			}
			else if (_state == STATE_PAUSED) {
				return Math.floor(_totalRunningTimeMs / 1000);
			}
			return Math.floor(_totalRunningTimeMs / 1000);
		}

		public function get commandList():Array {
			return _commands;
		}

		public function set commandList(cmds:Array):void {
			_commands = (cmds != null) ? cmds : [];
		}

		public function get currentStep():int {
			return _currentStep;
		}

		public function get loop():Boolean {
			return _loop;
		}

		public function set loop(val:Boolean):void {
			_loop = val;
		}

		public function get leaveCombatOnStop():Boolean {
			return _leaveCombatOnStop;
		}

		public function set leaveCombatOnStop(val:Boolean):void {
			_leaveCombatOnStop = val;
		}

		public function get notifyItemDrops():Boolean {
			return _notifyItemDrops;
		}

		public function set notifyItemDrops(val:Boolean):void {
			_notifyItemDrops = val;
		}

		public function get whitelist():Array {
			return _whitelist;
		}

		// =========================================================================
		// Script Management
		// =========================================================================
		public function addCommand(cmd:BotCommand):void {
			if (cmd != null) {
				_commands.push(cmd);
			}
		}

		public function clearCommands():void {
			stop();
			_commands = [];
			_currentStep = 0;
		}

		public function removeCommandAt(index:int):void {
			if (index >= 0 && index < _commands.length) {
				_commands.splice(index, 1);
				if (_currentStep >= _commands.length) {
					_currentStep = Math.max(0, _commands.length - 1);
				}
			}
		}

		public function moveCommandUp(index:int):Boolean {
			if (index <= 0 || index >= _commands.length)
				return false;
			var temp:BotCommand = _commands[index];
			_commands[index] = _commands[index - 1];
			_commands[index - 1] = temp;
			return true;
		}

		public function moveCommandDown(index:int):Boolean {
			if (index < 0 || index >= _commands.length - 1)
				return false;
			var temp:BotCommand = _commands[index];
			_commands[index] = _commands[index + 1];
			_commands[index + 1] = temp;
			return true;
		}

		// =========================================================================
		// Whitelist Management
		// =========================================================================
		public function addWhitelistItem(itemName:String):Boolean {
			if (itemName == null)
				return false;
			var clean:String = Utils.trim(itemName);
			if (clean.length == 0) {
				return false;
			}
			var lower:String = clean.toLowerCase();
			for each (var w:String in _whitelist) {
				if (w != null && Utils.cleanItemName(w) == lower) {
					return false;
				}
			}
			_whitelist.push(clean);
			return true;
		}

		public function removeWhitelistItem(itemName:String):void {
			if (itemName == null)
				return;
			var clean:String = Utils.cleanItemName(itemName);
			for (var i:int = _whitelist.length - 1; i >= 0; i--) {
				if (Utils.cleanItemName(String(_whitelist[i])) == clean) {
					_whitelist.splice(i, 1);
				}
			}
		}

		public function hasWhitelistItem(itemName:String):Boolean {
			if (itemName == null || itemName.length == 0)
				return false;
			var clean:String = Utils.cleanItemName(itemName);

			for each (var w:String in _whitelist) {
				if (w != null && Utils.cleanItemName(w) == clean) {
					return true;
				}
			}

			// Otomatis whitelist item yang sedang di-hunt oleh KillCommand (MODE_ITEM)
			for each (var cmd:BotCommand in _commands) {
				if (cmd is KillCommand) {
					var kcmd:KillCommand = cmd as KillCommand;
					if (kcmd.killMode == KillCommand.MODE_ITEM && kcmd.itemName != null) {
						if (Utils.cleanItemName(kcmd.itemName) == clean) {
							return true;
						}
					}
				}
			}
			return false;
		}

		// =========================================================================
		// Engine Control
		// =========================================================================
		public function start():Boolean {
			if (_commands.length == 0) {
				log("Cannot start: command list is empty.");
				return false;
			}

			if (game == null || game.sfc == null || !game.sfc.isConnected) {
				log("Cannot start: game is not connected.");
				return false;
			}

			_state = STATE_RUNNING;
			_currentStep = 0;
			_completedLoops = 0;
			_startTime = flash.utils.getTimer();
			_totalRunningTimeMs = 0;
			nextStepAllowedTime = 0;
			resetStepVariables();

			try {
				if (game.world && game.world.actions && game.world.actions.active) {
					for (var s:String in game.world.actions.active) {
						game.world.actions.active[s].range = "20000";
					}
				}
			}
			catch (e:Error) {
			}

			engineTimer.addEventListener(TimerEvent.TIMER, onTick, false, 0, true);
			engineTimer.start();

			if (Config.isAndroid) {
				try {
					BatteryOptimizer.startKeepAlive("YouMadBro Bot Active", "Running " + _commands.length + " commands in background");
					BatteryOptimizer.setPipAutoEnter(true);
				}
				catch (eFgs:Error) {
				}
			}

			log("BotEngine started with " + _commands.length + " commands.");
			dispatchState();
			dispatchStep();
			return true;
		}

		public function pause():void {
			if (_state != STATE_RUNNING)
				return;

			_state = STATE_PAUSED;
			_totalRunningTimeMs += (flash.utils.getTimer() - _startTime);
			engineTimer.stop();
			if (_leaveCombatOnStop) {
				leaveCombat();
			}
			log("BotEngine paused.");
			dispatchState();
		}

		public function resume():void {
			if (_state != STATE_PAUSED)
				return;

			_state = STATE_RUNNING;
			_startTime = flash.utils.getTimer();
			engineTimer.start();
			log("BotEngine resumed.");
			dispatchState();
		}

		public function leaveCombat():void {
			try {
				if (game != null && game.world != null) {
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
			}
			catch (e:Error) {
			}
		}

		public function stop():void {
			if (_state == STATE_IDLE)
				return;

			if (_state == STATE_RUNNING) {
				_totalRunningTimeMs += (flash.utils.getTimer() - _startTime);
			}

			_state = STATE_IDLE;
			engineTimer.removeEventListener(TimerEvent.TIMER, onTick);
			engineTimer.stop();

			if (Config.isAndroid) {
				try {
					BatteryOptimizer.stopKeepAlive();
					BatteryOptimizer.setPipAutoEnter(false);
				}
				catch (eStopFgs:Error) {
				}
			}

			if (_leaveCombatOnStop) {
				leaveCombat();
			}

			log("BotEngine stopped.");
			dispatchState();
		}

		public function toggle():Boolean {
			if (_state == STATE_IDLE) {
				return start();
			}
			else {
				stop();
				return false;
			}
		}

		private function resetStepVariables():void {
			currentKillsForStep = 0;
			delayTicksRemaining = 0;
			targetWasAlive = false;
		}

		// =========================================================================
		// Execution Loop (Sequential & Loops ke atas)
		// =========================================================================
		private function onTick(e:TimerEvent):void {
			if (game == null || game.sfc == null || !game.sfc.isConnected) {
				stop();
				return;
			}

			if (_state != STATE_RUNNING) {
				return;
			}

			// Delay 1 second before executing next command
			if (flash.utils.getTimer() < nextStepAllowedTime) {
				return;
			}

			// Loop ke atas check
			if (_commands.length == 0 || _currentStep >= _commands.length) {
				if (_loop && _commands.length > 0) {
					_completedLoops++;
					_currentStep = 0; // loops ke atas!
					resetStepVariables();
					delay(1000);
					dispatchStep();
					return;
				}
				else {
					_completedLoops++;
					log("Bot completed all commands.");
					if (Config.isAndroid) {
						try {
							BatteryOptimizer.sendNotification("YouMadBro Bot Finished", "All bot script commands completed successfully!");
						}
						catch (eFinNotif:Error) {
						}
					}
					stop();
					return;
				}
			}

			// Auto accept check
			checkDropStack();

			const cmd:BotCommand = _commands[_currentStep] as BotCommand;
			if (cmd == null) {
				advanceStep();
				return;
			}

			cmd.execute(this);
		}

		public function delay(ms:int = 1000):void {
			nextStepAllowedTime = flash.utils.getTimer() + ms;
		}

		public function advanceStep(delayMs:int = 1000):void {
			resetStepVariables();
			_currentStep++;
			delay(delayMs);
			dispatchStep();
		}

		// =========================================================================
		// Combat Helpers
		// =========================================================================
		public function getMonsterByName(name:String):Object {
			if (game == null || game.world == null)
				return null;

			var cleanName:String = (name != null) ? name.toLowerCase() : "*";
			try {
				var monsters:Array = game.world.getMonstersByCell(game.world.strFrame);
				if (monsters != null) {
					for each (var mon:Object in monsters) {
						if (mon != null && mon.pMC != null && mon.dataLeaf != null && mon.dataLeaf.intState > 0 && mon.dataLeaf.intHP > 0) {
							if (cleanName == "*" || cleanName == "") {
								return mon;
							}
							var mName:String = mon.pMC.pname.ti.text.toLowerCase();
							if (mName.indexOf(cleanName) > -1) {
								return mon;
							}
						}
					}
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		// =========================================================================
		// Inventory & Temp Inventory Check
		// =========================================================================
		public function getItemQuantity(itemName:String):int {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return 0;
			}

			if (itemName == null || itemName.length == 0)
				return 0;
			const cleanName:String = Utils.cleanItemName(itemName);
			var total:int = 0;

			// 1. Regular inventory
			try {
				var inv:* = game.world.myAvatar.items;
				if (inv != null) {
					for each (var item:Object in inv) {
						if (item != null && item.sName != null) {
							if (item.sName.toLowerCase() == cleanName) {
								total += int(item.iQty != null ? item.iQty : 1);
							}
						}
					}
				}
			}
			catch (e:Error) {
			}

			// 2. Temp inventory
			try {
				var tempInv:* = game.world.myAvatar.tempitems;
				if (tempInv != null) {
					for each (var tempItem:Object in tempInv) {
						if (tempItem != null && tempItem.sName != null) {
							if (tempItem.sName.toLowerCase() == cleanName) {
								total += int(tempItem.iQty != null ? tempItem.iQty : 1);
							}
						}
					}
				}
			}
			catch (e:Error) {
			}

			// 3. Fallback to invTree
			try {
				if (total == 0 && game.world.invTree != null) {
					for each (var treeItem:Object in game.world.invTree) {
						if (treeItem != null && treeItem.sName != null) {
							if (treeItem.sName.toLowerCase() == cleanName) {
								total += int(treeItem.iQty != null ? treeItem.iQty : 1);
							}
						}
					}
				}
			}
			catch (e:Error) {
			}

			return total;
		}

		public function getInventoryItemByName(itemName:String):Object {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return null;
			}
			if (itemName == null || itemName.length == 0)
				return null;
			const cleanName:String = Utils.cleanItemName(itemName);
			try {
				var inv:* = game.world.myAvatar.items;
				if (inv != null) {
					for each (var item:Object in inv) {
						if (item != null && item.sName != null && String(item.sName).toLowerCase() == cleanName) {
							return item;
						}
					}
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		public function getBankItemByName(itemName:String):Object {
			if (game == null || game.world == null || game.world.bankinfo == null) {
				return null;
			}
			if (itemName == null || itemName.length == 0)
				return null;
			const cleanName:String = Utils.cleanItemName(itemName);
			try {
				var bankItems:* = game.world.bankinfo.items;
				if (bankItems != null) {
					for each (var item:Object in bankItems) {
						if (item != null && item.sName != null && String(item.sName).toLowerCase() == cleanName) {
							return item;
						}
					}
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		// =========================================================================
		// JSON Config Serialization & Storage
		// =========================================================================
		public function exportConfigJSON():String {
			var cmdList:Array = [];
			for each (var cmd:BotCommand in _commands) {
				if (cmd != null) {
					cmdList.push(cmd.toJSON());
				}
			}

			var questList:Array = [];
			if (AutoQuestUI.instance != null) {
				questList = AutoQuestUI.instance.getQuestIds();
				autoQuestList = questList;
			}
			else if (autoQuestList != null) {
				questList = autoQuestList;
			}

			var cfg:Object = {
					"name": "Bot Script",
					"loop": _loop,
					"leaveCombatOnStop": _leaveCombatOnStop,
					"notifyItemDrops": _notifyItemDrops,
					"whitelist": _whitelist,
					"quests": questList,
					"commands": cmdList
				};
			return JSON.stringify(cfg, null, 2);
		}

		public function importConfigJSON(jsonStr:String):Boolean {
			if (jsonStr == null || jsonStr.length == 0)
				return false;
			try {
				var data:Object = JSON.parse(jsonStr);
				if (data == null)
					return false;

				_loop = data.loop !== undefined ? Boolean(data.loop) : true;
				_leaveCombatOnStop = data.leaveCombatOnStop !== undefined ? Boolean(data.leaveCombatOnStop) : true;
				_notifyItemDrops = data.notifyItemDrops !== undefined ? Boolean(data.notifyItemDrops) : true;
				if (data.whitelist != null && data.whitelist is Array) {
					_whitelist = [];
					for each (var w:* in data.whitelist) {
						if (w != null) {
							addWhitelistItem(String(w));
						}
					}
				}
				if (data.quests != null && data.quests is Array) {
					autoQuestList = [];
					for each (var q:* in data.quests) {
						if (q != null) {
							autoQuestList.push(String(q));
						}
					}
					if (AutoQuestUI.instance != null) {
						AutoQuestUI.instance.setQuestIds(autoQuestList);
					}
				}
				else {
					autoQuestList = [];
					if (AutoQuestUI.instance != null) {
						AutoQuestUI.instance.clearQuests();
					}
				}
				if (data.commands != null && data.commands is Array) {
					_commands = [];
					for each (var cObj:Object in data.commands) {
						var parsedCmd:BotCommand = BotCommand.fromJSON(cObj);
						if (parsedCmd != null) {
							_commands.push(parsedCmd);
						}
					}
				}
				_currentStep = 0;
				resetStepVariables();
				log("Imported config with " + _commands.length + " commands, " + _whitelist.length + " whitelist items, and " + autoQuestList.length + " quests.");
				dispatchStep();
				return true;
			}
			catch (e:Error) {
				log("Failed to parse config JSON: " + e.message);
				return false;
			}
			return false;
		}

		// =========================================================================
		// Auto Accept Drops (UI Drop Stack)
		// =========================================================================

		private function checkDropStack():void {
			if (game == null)
				return;

			// 1. Custom Drops UI (cDropsUI)
			try {
				if (game.cDropsUI != null) {
					var cMenu:* = (game.cDropsUI.mcDraggable != null && game.cDropsUI.mcDraggable.menu != null)
						? game.cDropsUI.mcDraggable.menu
						: game.cDropsUI;
					if (cMenu != null && cMenu.numChildren != null) {
						for (var j:int = cMenu.numChildren - 1; j >= 0; j--) {
							var cChild:* = cMenu.getChildAt(j);
							if (cChild != null) {
								var cName:String = "";
								var cId:int = -1;
								if (cChild.itemObj != null) {
									cName = cChild.itemObj.sName != null ? String(cChild.itemObj.sName) : "";
									cId = int(cChild.itemObj.ItemID);
								}
								else if (cChild.txtDrop != null && cChild.txtDrop.text != null) {
									cName = String(cChild.txtDrop.text);
								}
								if (cName.length > 0 && hasWhitelistItem(cName)) {
									log("Auto accepting Custom Drop: " + cName);
									if (cChild.btYes != null) {
										cChild.btYes.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
									}
									if (cId > 0) {
										pickupDrop(cId);
									}
								}
							}
						}
					}
				}
			}
			catch (e:Error) {
			}

			// 2. Standard Drop Stack UI (ui.dropStack)
			try {
				if (game.ui != null && game.ui.dropStack != null) {
					var stack:* = game.ui.dropStack;
					for (var i:int = stack.numChildren - 1; i >= 0; i--) {
						var child:* = stack.getChildAt(i);
						if (child != null) {
							var itemName:String = "";
							var itemId:int = -1;
							if (child.fData != null) {
								itemName = child.fData.sName != null ? String(child.fData.sName) : "";
								itemId = int(child.fData.ItemID);
							}
							if (itemName.length == 0 && child.cnt != null && child.cnt.strName != null) {
								itemName = String(child.cnt.strName.text);
							}
							if (itemName.length > 0 && hasWhitelistItem(itemName)) {
								log("Auto accepting UI drop: " + itemName);
								if (child.cnt != null && child.cnt.ybtn != null) {
									child.cnt.ybtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
								}
								if (itemId > 0) {
									pickupDrop(itemId);
								}
							}
						}
					}
				}
			}
			catch (e:Error) {
			}
		}

		public function pickupDrop(itemId:int):void {
			if (game == null || game.sfc == null)
				return;
			try {
				var curRoom:int = (game.world != null && game.world.curRoom != null) ? int(game.world.curRoom) : 0;
				game.sfc.sendXtMessage("zm", "getDrop", [itemId], "str", curRoom);
			}
			catch (e:Error) {
			}
		}

		public function log(msg:String):void {
			trace("[BotEngine] " + msg);
			PacketLoggerUI.logBot(msg);
			if (onLog != null) {
				onLog(msg);
			}
		}

		private function dispatchState():void {
			if (onStateChange != null) {
				onStateChange(_state);
			}
			for (var i:int = 0; i < _stateListeners.length; i++) {
				var fn:Function = _stateListeners[i] as Function;
				if (fn != null) {
					fn(_state);
				}
			}
		}

		private function dispatchStep():void {
			if (onStepChange != null) {
				onStepChange(_currentStep, (_currentStep < _commands.length) ? _commands[_currentStep] : null);
			}
		}
	}
}
