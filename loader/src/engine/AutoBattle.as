package engine {

	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import SFSEvent;
	import Utils;

	public class AutoBattle {

		public static const STATE_IDLE:int = 0;
		public static const STATE_RUNNING:int = 1;
		public static const STATE_PAUSED:int = 2;

		public static var instance:AutoBattle;
		private static var skillIndex:int = 0;
		private static var temporalRift:int = 0;

		private var _state:int = STATE_IDLE;
		private var game:Object;
		private var botTimer:Timer = new Timer(100);
		private var skillDelay:int = 0;
		private var onStateChange:Function;

		public function AutoBattle(game:Object, onStateChange:Function) {
			this.game = game;
			this.onStateChange = onStateChange;
			instance = this;

			this.game.sfc.addEventListener(SFSEvent.onDebugMessage, this.onPacketReceived);
		}

		public function get state():int {
			return _state;
		}

		public function get active():Boolean {
			return _state != STATE_IDLE;
		}

		public function get paused():Boolean {
			return _state == STATE_PAUSED;
		}

		public function get idle():Boolean {
			return _state == STATE_IDLE;
		}

		public function set paused(value:Boolean):void {
			if (_state == STATE_IDLE)
				return;
			_state = value ? STATE_PAUSED : STATE_RUNNING;
			if (onStateChange != null) {
				onStateChange(_state);
			}
		}

		public function setActive(value:Boolean):Boolean {
			if (value) {
				if (game == null || game.sfc == null || !game.sfc.isConnected) {
					return false;
				}

				_state = STATE_RUNNING;

				// Set skill range to infinite
				for (var s:String in game.world.actions.active) {
					game.world.actions.active[s].range = "20000";
				}

				if (onStateChange != null) {
					onStateChange(_state);
				}
				botTimer.addEventListener(TimerEvent.TIMER, onTick);
				botTimer.start();
				return true;
			}
			else {
				_state = STATE_IDLE;
				if (onStateChange != null) {
					onStateChange(_state);
				}
				botTimer.removeEventListener(TimerEvent.TIMER, onTick);
				botTimer.stop();
				return false;
			}
		}

		public function toggle():Boolean {
			return setActive(_state == STATE_IDLE);
		}

		private function setMonTarget():void {
			var target:Object = null;
			var currentTarget:Object = game.world.myAvatar.target;
			var priorities:Array = ["Staff of Inversion", "Attack Drone", "Defense Drone", "Ultra Fire Orb", "Stalagbite"];

			for each (var name:String in priorities) {
				target = getMonsterByName(name);
				if (target != null)
					break;
			}

			if (target == null && game.world.myAvatar.target == null) {
				target = getMonsterByName("*");
			}

			if (target != null && currentTarget != target) {
				game.world.setTarget(target);
			}
		}

		private function onTick(e:TimerEvent):void {
			// Stop botting if not connected to server or logged out
			if (game == null || game.sfc == null || !game.sfc.isConnected) {
				setActive(false);
				skillDelay = 0;
				return;
			}

			if (_state == STATE_PAUSED) {
				game.world.cancelAutoAttack();
				game.world.cancelTarget();
				return;
			}

			skillDelay++;
			if (skillDelay >= 1) {
				// delay 100ms
				setMonTarget();

				if (game.world.myAvatar && game.world.myAvatar.target && game.world.myAvatar.target.dataLeaf && game.world.myAvatar.target.dataLeaf.intHP > 0) {
					game.world.approachTarget();
					useSmartSkill(game);
				}
				skillDelay = 0;
			}
		}

		// =========================================================================
		// Reusable Smart Combat Engine (used by AutoBattle & KillCommand)
		// =========================================================================
		public static function useSmartSkill(game:Object):void {
			try {
				if (game == null || game.world == null || game.world.myAvatar == null || game.world.myAvatar.target == null || game.world.myAvatar.target.dataLeaf == null || game.world.myAvatar.target.dataLeaf.intHP <= 0) {
					return;
				}

				// Check if paused or monster has counter attack aura (avoid self-kill)
				if (instance != null && instance.paused) {
					return;
				}
				if (hasCounterAttack(game)) {
					return;
				}

				// CSH combo if equipped
				if (isUsingClass(game, "Chrono ShadowSlayer", "Chrono ShadowHunter")) {
					if (temporalRift >= 4) {
						if (useSkill(game, 4)) {
							temporalRift = 0;
						}
					}
					else if (getAurasValue(game, true, "Rounds Empty") > 0) {
						useSkill(game, 1);
					}
					else if (getAurasValue(game, true, "Temporal Rift") < 1) {
						useSkill(game, 2);
					}
					else {
						if (useSkill(game, 3)) {
							temporalRift++;
						}
					}
					return;
				}

				// Arcana Invoker combo if equipped
				if (isUsingClass(game, "Arcana Invoker")) {
					executeArcanaInvokerCombo(game);
					return;
				}

				// King's Echo combo if equipped
				if (isUsingClass(game, "King's Echo")) {
					executeKingsEchoCombo(game);
					return;
				}

				// Master Ranger & Ranger combo if equipped
				if (isUsingClass(game, "Master Ranger", "Ranger")) {
					executeRangerCombo(game);
					return;
				}

				// Smart skill rotation: try from current skillIndex, find next available skill
				for (var i:int = 0; i < 5; i++) {
					var idx:int = (skillIndex + i) % 5;
					if (useSkill(game, idx)) {
						skillIndex = (idx + 1) % 5;
						break;
					}
				}
			}
			catch (e:Error) {
			}
		}

		public static function useSkill(game:Object, index:int):Boolean {
			try {
				var skill:Object = getSkill(game, index);
				if (skill == null)
					return false;

				// Infinite range hack
				if (skill.range != "20000") {
					skill.range = "20000";
				}

				if (isSkillReady(game, skill) == 0 && canUseSkill(game, index) && hasEnoughMana(game, skill)) {
					if (skill.isOK && !skill.skillLock) {
						game.world.testAction(skill);
						return true;
					}
				}
			}
			catch (e:Error) {
			}
			return false;
		}

		public static function getRequiredMana(game:Object, skill:Object):int {
			if (skill == null || skill.mp == null)
				return 0;
			var baseMp:Number = Number(skill.mp || 0);
			if (baseMp <= 0)
				return 0;
			var cmc:Number = 1.0;
			try {
				if (game != null && game.world != null && game.world.myAvatar != null && game.world.myAvatar.dataLeaf != null && game.world.myAvatar.dataLeaf.sta != null && game.world.myAvatar.dataLeaf.sta.$cmc != null) {
					cmc = Number(game.world.myAvatar.dataLeaf.sta.$cmc);
					if (isNaN(cmc) || cmc < 0) {
						cmc = 0;
					}
				}
			}
			catch (e:Error) {
				cmc = 1.0;
			}
			return Math.round(baseMp * cmc);
		}

		public static function hasEnoughMana(game:Object, skill:Object):Boolean {
			try {
				if (skill == null)
					return false;
				var reqMp:int = getRequiredMana(game, skill);
				if (reqMp <= 0)
					return true;
				if (game == null || game.world == null || game.world.myAvatar == null || game.world.myAvatar.dataLeaf == null)
					return false;
				var currentMp:int = int(game.world.myAvatar.dataLeaf.intMP || 0);
				return currentMp >= reqMp;
			}
			catch (e:Error) {
			}
			return true;
		}

		public static function isSkillReady(game:Object, skill:Object):int {
			try {
				var now:Number = new Date().getTime();
				var haste:Number = 0;
				if (game.world.myAvatar.dataLeaf.sta != null && game.world.myAvatar.dataLeaf.sta.$tha != null) {
					haste = Number(game.world.myAvatar.dataLeaf.sta.$tha);
				}
				var hasteMod:Number = 1 - Math.min(Math.max(haste, -1), 0.5);
				var baseCd:Number = (skill.OldCD != null) ? Number(skill.OldCD) : Number(skill.cd || 0);
				var skillCD:Number = Math.round(baseCd * hasteMod);
				if (skill.OldCD != null)
					delete skill.OldCD;

				var gcdTs:Number = Number(game.world.GCDTS || 0);
				var gcdVal:Number = Number(game.world.GCD || 0);
				var gcd:Number = Math.max(0, gcdVal - (now - gcdTs));

				var skillTs:Number = Number(skill.ts || 0);
				var cd:Number = Math.max(0, skillCD - (now - skillTs));

				return Math.max(gcd, cd);
			}
			catch (e:Error) {
			}
			return 0;
		}

		public static function canUseSkill(game:Object, skillIdx:int):Boolean {
			try {
				if (game.world.myAvatar == null || game.world.myAvatar.dataLeaf == null) {
					return false;
				}
				var intHP:Number = Number(game.world.myAvatar.dataLeaf.intHP || 0);
				var intHPMax:Number = Number(game.world.myAvatar.dataLeaf.intHPMax || 1);
				var myHP:int = intHP / intHPMax * 100;
				var myMP:int = int(game.world.myAvatar.dataLeaf.intMP || 0);

				switch (getEquippedClass(game)) {
					case "Void Highlord":
						if (myHP < 60 && (skillIdx == 1 || skillIdx == 3))
							return false;
						break;
					case "Scarlet Sorceress":
						if (myHP < 50 && (skillIdx == 1 || skillIdx == 4))
							return false;
						break;
					case "Dragon of Time":
						if (myHP < 50 && (skillIdx == 1 || skillIdx == 3))
							return false;
						break;
					case "Lich":
						if ((myHP < 70 && skillIdx == 4) || (myMP > 40 && skillIdx == 3))
							return false;
						break;
					case "ArchPaladin":
						if (myHP > 60 && skillIdx == 2)
							return false;
						break;
					case "Hollowborn Vindicator":
						var hasSafeguard:Boolean = getAurasValue(game, true, "Safeguard") > 0;
						var hasDecay:Boolean = getAurasValue(game, true, "Decay") > 0;
						if ((skillIdx == 1 || skillIdx == 3) && hasSafeguard)
							return true;
						if (skillIdx == 2 && !hasSafeguard && hasDecay)
							return true;
						if (skillIdx == 4 && !hasSafeguard && !hasDecay)
							return true;
						return false;
					case "King's Echo":
					case "Kings Echo":
						if (skillIdx == 3 && getAurasValue(game, true, "Waiting For Corvak") > 0)
							return false;
						break;
					case "Master Ranger":
					case "Ranger":
						if (skillIdx == 3 && Math.max(getAurasValue(game, true, "Marks"), getAurasValue(game, false, "Marks")) < 6)
							return false;
						if (skillIdx == 4 && getAurasValue(game, true, "Vampiric Shot") > 0)
							return false;
						break;
				}
			}
			catch (e:Error) {
			}
			return true;
		}

		public static function hasCounterAttack(game:Object):Boolean {
			try {
				if (game.world.myAvatar.target != null && game.world.myAvatar.target.dataLeaf != null) {
					var auras:Object = game.world.myAvatar.target.dataLeaf.auras;
					if (auras != null) {
						for each (var aura:Object in auras) {
							if (aura != null && aura.nam != null && String(aura.nam).toLowerCase().indexOf("counter attack") > -1) {
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

		public static function getAurasValue(game:Object, isSelf:Boolean, auraName:String):int {
			try {
				var value:int = 0;
				var hasTarget:Boolean = game.world.myAvatar.target != null && game.world.myAvatar.target.dataLeaf != null && game.world.myAvatar.target.dataLeaf.intHP > 0;
				if (!isSelf && !hasTarget) {
					return value;
				}
				var objAura:Object = isSelf ? game.world.myAvatar.dataLeaf.auras : game.world.myAvatar.target.dataLeaf.auras;
				if (objAura == null)
					return 0;

				var cleanTargetName:String = auraName.toLowerCase().replace(/[\s\-_]/g, "");
				for each (var aura:Object in objAura) {
					if (aura != null && aura.nam != null) {
						var cleanName:String = String(aura.nam).toLowerCase().replace(/[\s\-_]/g, "");
						if (cleanName == cleanTargetName) {
							var numericVal:Number = parseFloat(aura.val);
							value = (!isNaN(numericVal) && numericVal > 0) ? Math.ceil(numericVal) : 1;
							break;
						}
					}
				}
				return value;
			}
			catch (e:Error) {
			}
			return 0;
		}

		public static function getEquippedClass(game:Object):String {
			try {
				if (game.world.myAvatar != null && game.world.myAvatar.objData != null && game.world.myAvatar.objData.strClassName != null) {
					return String(game.world.myAvatar.objData.strClassName);
				}
			}
			catch (e:Error) {
			}
			return "";
		}

		public static function isUsingClass(game:Object, ...classes):Boolean {
			var current:String = getEquippedClass(game);
			if (current == null || current.length == 0 || classes == null || classes.length == 0) {
				return false;
			}
			var cleanCurrent:String = Utils.trim(current).toLowerCase();
			for each (var target:* in classes) {
				if (target is Array) {
					for each (var subItem:* in target) {
						if (subItem != null && Utils.trim(String(subItem)).toLowerCase() == cleanCurrent) {
							return true;
						}
					}
				}
				else if (target != null && Utils.trim(String(target)).toLowerCase() == cleanCurrent) {
					return true;
				}
			}
			return false;
		}

		private static function executeKingsEchoCombo(game:Object):void {
			var hasWaitingForCorvak:Boolean = getAurasValue(game, true, "Waiting For Corvak") > 0;

			// Spam skills normally, but skip Skill 3 if 'Waiting For Corvak' is active
			for (var i:int = 0; i < 5; i++) {
				var idx:int = (skillIndex + i) % 5;
				if (idx == 3 && hasWaitingForCorvak) {
					continue;
				}
				if (useSkill(game, idx)) {
					skillIndex = (idx + 1) % 5;
					break;
				}
			}
		}

		private static function executeRangerCombo(game:Object):void {
			var marks:int = Math.max(getAurasValue(game, true, "Marks"), getAurasValue(game, false, "Marks"));
			var hasVampiricShot:Boolean = getAurasValue(game, true, "Vampiric Shot") > 0;

			// Prioritize Skill 3 immediately when player reaches 6 stacks of Marks
			if (marks >= 6) {
				if (useSkill(game, 3))
					return;
			}

			// Spam remaining skills normally (skip Skill 3 if marks < 6, skip Skill 4 if Vampiric Shot active)
			for (var i:int = 0; i < 5; i++) {
				var idx:int = (skillIndex + i) % 5;
				if (idx == 3 && marks < 6) {
					continue;
				}
				if (idx == 4 && hasVampiricShot) {
					continue;
				}
				if (useSkill(game, idx)) {
					skillIndex = (idx + 1) % 5;
					break;
				}
			}
		}

		private static function executeArcanaInvokerCombo(game:Object):void {
			var hasWorld:Boolean = getAurasValue(game, true, "XXI - The World") > 0;
			var hasJudgement:Boolean = getAurasValue(game, true, "XX - Judgement") > 0;
			var endOfTheWorld:int = getAurasValue(game, true, "End of The World");
			var hasFool:Boolean = getAurasValue(game, true, "0 - The Fool") > 0;
			var myMP:int = int(game.world.myAvatar.dataLeaf.intMP || 0);

			if (!hasWorld) {
				// Pre-World Phase:
				// 1. Draw The Fool if not active
				if (!hasFool) {
					if (useSkill(game, 1))
						return;
				}
				// 2. Advance to The World when Judgement is reached
				else if (hasJudgement) {
					if (useSkill(game, 1))
						return;
				}
			}

			// THE WORLD CYCLE / Core skills: prioritize Skill 2 and Skill 4
			if (useSkill(game, 2))
				return;
			if (useSkill(game, 4))
				return;

			// Use Skill 3 if Judgement active or Mana > 50
			if (hasJudgement || myMP > 50) {
				if (useSkill(game, 3))
					return;
			}

			// Nuke with Skill 1 when "End of The World" stacks exceed 10
			if (endOfTheWorld > 10) {
				if (useSkill(game, 1))
					return;
			}
		}

		public static function getSkill(game:Object, index:int):Object {
			try {
				if (game != null && game.world != null && game.world.actions != null && game.world.actions.active != null) {
					return game.world.actions.active[index];
				}
			}
			catch (e:Error) {
			}
			return null;
		}

		private function getMonsterByName(name:String):Object {
			for each (var mon:Object in game.world.getMonstersByCell(game.world.strFrame)) {
				if (mon.pMC) {
					var monster:String = mon.pMC.pname.ti.text.toLowerCase();
					if (((monster.indexOf(name.toLowerCase()) > -1) || (name == "*")) && mon.dataLeaf.intState > 0) {
						return mon;
					}
				}
			}
			return null;
		}

		private function getMonsterByMonMapId(monId:String):Object {
			for each (var mon:Object in game.world.getMonstersByCell(game.world.strFrame)) {
				if (mon.pMC) {
					var monster:String = mon.dataLeaf.MonMapID;
					if (((monster.indexOf(monId) > -1) || (monId == "*")) && mon.dataLeaf.intState > 0) {
						return mon;
					}
				}
			}
			return null;
		}

		private function onPacketReceived(packet:*):void {
			var msg:String = packet.params.message;
			var serverMsg:String = Utils.normalizePacket(msg);

			if (serverMsg.indexOf("{") == 0) {
				try {
					var data:Object = JSON.parse(serverMsg);
					if (data && data.b && data.b.o) {
						var obj:Object = data.b.o;
						var cmd:String = obj.cmd;

						if (cmd == "ct") {
							if (obj.anims != null) {
								for each (var anim:Object in obj.anims) {
									if (anim.msg != null && anim.msg.indexOf("prepares a counter attack") > -1) {
										if (state == STATE_RUNNING) {
											this.paused = true;
											break;
										}
									}
								}
							}
							if (obj.a != null) {
								for each (var action:Object in obj.a) {
									if (action.cmd.indexOf("aura-") > -1 && action.aura.nam.indexOf("Counter Attack") > -1) {
										if (state == STATE_PAUSED) {
											this.paused = false;
											break;
										}
									}
								}
							}
						}
					}
				}
				catch (e:Error) {
					// Ignore non-JSON or malformed
				}
			}
		}
	}
}
