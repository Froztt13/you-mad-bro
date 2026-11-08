package handler {

	import flash.display.MovieClip;
	import flash.utils.getTimer;
	import input.AppLogUI;
	import input.PacketLoggerUI;
	import ui.InfoMessage;

	public class PacketHandler {

		public static var instance:PacketHandler;
		public static var animObservers:Array = [];
		public static var lastAnimMsgs:Array = [];
		public static var auraObservers:Array = [];
		public static var lastAuraActions:Array = [];

		private var game:MovieClip;
		private var chatHandler:ChatHandler;

		public static function addAnimObserver(callback:Function):void {
			if (callback != null && animObservers.indexOf(callback) == -1) {
				animObservers.push(callback);
			}
		}

		public static function removeAnimObserver(callback:Function):void {
			var idx:int = animObservers.indexOf(callback);
			if (idx > -1) {
				animObservers.splice(idx, 1);
			}
		}

		public static function addAuraObserver(callback:Function):void {
			if (callback != null && auraObservers.indexOf(callback) == -1) {
				auraObservers.push(callback);
			}
		}

		public static function removeAuraObserver(callback:Function):void {
			var idx:int = auraObservers.indexOf(callback);
			if (idx > -1) {
				auraObservers.splice(idx, 1);
			}
		}

		public function PacketHandler(game:MovieClip) {
			instance = this;
			this.game = game;
			this.chatHandler = new ChatHandler(game);
		}

		public function handleServerResponse(msg:String):void {
			if (msg == null || msg.length == 0)
				return;

			// Handle XT chat messages (chatm, whisper, warning, message)
			if (msg.indexOf("%xt%") > -1 || msg.indexOf("xt%") == 0) {
				if (chatHandler != null) {
					chatHandler.handleXtMessage(msg);
				}
				return;
			}

			// JSON parsing
			if (msg.indexOf("{") == 0) {
				try {
					var root:Object = JSON.parse(msg);
					if (root == null)
						return;

					var data:Object = (root.b && root.b.o) ? root.b.o : (root.o ? root.o : (root.b ? root.b : root));
					if (data == null)
						return;

					var cmd:String = (data.cmd != null) ? String(data.cmd) : "";

					switch (cmd) {
						case "ct":
							handleCombatTrace(data);
							break;

						case "initUserData":
							if (data.data) {
								checkUserAccessLevel(data.data.strUsername, int(data.data.intAccessLevel));
							}
							break;

						case "initUserDatas":
							if (data.a != null) {
								for each (var user:Object in data.a) {
									if (user.data) {
										checkUserAccessLevel(user.data.strUsername, int(user.data.intAccessLevel));
									}
								}
							}
							break;
					}
				}
				catch (e:Error) {
					// Not valid JSON or other error
				}
			}
		}

		private function handleCombatTrace(data:Object):void {
			var animMsgs:Array = [];
			var animsRaw:* = (data.anims != null) ? data.anims : data.anim;

			if (animsRaw is Array) {
				var animsArr:Array = animsRaw as Array;
				for (var i:int = 0; i < animsArr.length; i++) {
					var aObj:Object = animsArr[i];
					if (aObj == null)
						continue;

					var msgStr:String = (aObj.msg != null && String(aObj.msg).length > 0)
						? String(aObj.msg)
						: ((aObj.str != null) ? String(aObj.str) : "");

					if (msgStr.length > 0 && animMsgs.indexOf(msgStr) == -1) {
						animMsgs.push(msgStr);
					}
				}
			}
			else if (animsRaw != null) {
				var singleObj:Object = animsRaw;
				var sMsg:String = (singleObj.msg != null && String(singleObj.msg).length > 0)
					? String(singleObj.msg)
					: ((singleObj.str != null) ? String(singleObj.str) : "");

				if (sMsg.length > 0 && animMsgs.indexOf(sMsg) == -1) {
					animMsgs.push(sMsg);
				}
			}

			var directMsg:String = (data.msg != null) ? String(data.msg) : "";
			if (directMsg.length > 0 && animMsgs.indexOf(directMsg) == -1) {
				animMsgs.push(directMsg);
			}

			if (animMsgs.length > 0) {
				lastAnimMsgs = animMsgs.slice();
				for each (var animMsg:String in animMsgs) {
					AppLogUI.log("[ANIM] " + animMsg);
				}
				notifyAnimObservers(animMsgs, data);
			}

			// Extract aura actions (e.g. aura+, aura-, aura?)
			var actionsRaw:* = (data.a != null) ? data.a : data.actions;
			var auraActions:Array = [];

			if (actionsRaw is Array) {
				var actionsArr:Array = actionsRaw as Array;
				for (var j:int = 0; j < actionsArr.length; j++) {
					var actObj:Object = actionsArr[j];
					if (actObj != null && actObj.cmd != null && String(actObj.cmd).indexOf("aura") > -1) {
						auraActions.push(actObj);
					}
				}
			}
			else if (actionsRaw != null && typeof actionsRaw == "object") {
				if (actionsRaw.cmd != null && String(actionsRaw.cmd).indexOf("aura") > -1) {
					auraActions.push(actionsRaw);
				}
			}

			if (auraActions.length > 0) {
				lastAuraActions = auraActions.slice();
				notifyAuraObservers(auraActions, data);
			}
		}

		private function notifyAnimObservers(animMsgs:Array, data:Object):void {
			for each (var observer:Function in animObservers) {
				try {
					if (observer != null) {
						if (observer.length == 0) {
							observer();
						}
						else if (observer.length == 1) {
							observer(animMsgs);
						}
						else {
							observer(animMsgs, data);
						}
					}
				}
				catch (e:Error) {
				}
			}
		}

		private function notifyAuraObservers(auraActions:Array, data:Object):void {
			for each (var observer:Function in auraObservers) {
				try {
					if (observer != null) {
						if (observer.length == 0) {
							observer();
						}
						else if (observer.length == 1) {
							observer(auraActions);
						}
						else {
							observer(auraActions, data);
						}
					}
				}
				catch (e:Error) {
				}
			}
		}

		private function checkUserAccessLevel(username:String, level:int):void {
			if (level >= 30) {
				game.chatF.pushMsg("server", "Game staff " + username + " (accessLevel " + level + ") detected!", "SERVER", "", 0);
				game.logout();

				const alert:InfoMessage = new InfoMessage("Game staff Detected!", "Game staff " + username + " (accessLevel " + level + ") is in your area.");
				game.addChild(alert);
			}
		}
	}
}
