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
				game.chatF.pushMsg("server", "Auto battling started", "SERVER", "", 0);
				botTimer.addEventListener(TimerEvent.TIMER, onTick);
				botTimer.start();
				return true;
			}
			else {
				_state = STATE_IDLE;
				if (onStateChange != null) {
					onStateChange(_state);
				}
				game.chatF.pushMsg("server", "Auto battling stopped", "SERVER", "", 0);
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
				if (isUsingCSH(game)) {
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

				if (isSkillReady(game, skill) == 0 && canUseSkill(game, index) && game.world.myAvatar.dataLeaf.intMP >= skill.mp) {
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

				var cleanTargetName:String = auraName.toLowerCase().split(' ').join('');
				for each (var aura:Object in objAura) {
					if (aura != null && aura.nam != null) {
						var cleanName:String = String(aura.nam).toLowerCase().split(' ').join('');
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

		public static function isUsingCSH(game:Object):Boolean {
			var cls:String = getEquippedClass(game);
			return cls == "Chrono ShadowSlayer" || cls == "Chrono ShadowHunter";
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
											game.chatF.pushMsg("server", "Auto battling paused", "SERVER", "", 0);
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
											game.chatF.pushMsg("server", "Auto battling resumed", "SERVER", "", 0);
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
