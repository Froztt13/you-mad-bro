package handler {

	import flash.display.MovieClip;
	import input.AppLogUI;

	/**
	 * Handles incoming XT chat packets (chatm, whisper, warning, message).
	 * Ported from Grimoire's HandlerChat.cs architecture.
	 */
	public class ChatHandler {

		private var game:MovieClip;

		public function ChatHandler(game:MovieClip = null) {
			this.game = game;
		}

		public function setGame(game:MovieClip):void {
			this.game = game;
		}

		/**
		 * Handles an XT packet string from server.
		 * Formats and forwards chat events to AppLogUI.chat().
		 */
		public function handleXtMessage(raw:String):void {
			if (raw == null || raw.length == 0)
				return;

			var idx:int = raw.indexOf("%xt%");
			var args:Array;
			if (idx > -1) {
				args = raw.substr(idx).split("%");
			}
			else if (raw.indexOf("xt%") == 0) {
				args = ("%" + raw).split("%");
			}
			else {
				return;
			}

			if (args.length < 5)
				return;

			// XT format: %xt%<cmd>%<roomId>%<msg>%<sender>%<receiver/extra>%...
			var cmd:String = String(args[2]);
			var msg:String = String(args[4]);
			var tolog:String = "";

			switch (cmd) {
				case "chatm":
					var sender:String = (args.length > 5 && args[5] != null) ? String(args[5]) : "";
					if (msg.indexOf("zone~") == 0) {
						tolog = sender + ": " + msg.substr(5);
					}
					else if (msg.indexOf("guild~") == 0) {
						tolog = "[GUILD] " + sender + ": " + msg.substr(6);
					}
					else if (msg.indexOf("party~") == 0) {
						tolog = "[PARTY] " + sender + ": " + msg.substr(6);
					}
					else if (msg.indexOf("mod~") == 0) {
						tolog = "[MOD] " + sender + ": " + msg.substr(4);
					}
					else {
						// Standard Grimoire replacement fallback
						tolog = (sender + msg).replace("zone~", ": ").replace("guild~", " [GUILD]: ").replace("party~", " [PARTY]: ");
					}
					break;

				case "whisper":
					var whisperSender:String = (args.length > 5 && args[5] != null) ? String(args[5]) : "";
					var whisperTarget:String = (args.length > 6 && args[6] != null) ? String(args[6]) : "";
					var myUser:String = getMyUsername();

					if (myUser.length > 0 && whisperTarget.toLowerCase() == myUser.toLowerCase()) {
						tolog = "From " + whisperSender + ": " + msg;
					}
					else if (whisperTarget.length > 0) {
						tolog = "To " + whisperTarget + ": " + msg;
					}
					else {
						tolog = "From " + whisperSender + ": " + msg;
					}
					break;

				case "warning":
					tolog = (msg.indexOf("[WARNING]") > -1) ? msg : ("[WARNING] " + msg);
					break;

				case "message":
					tolog = (msg.indexOf("[SERVER]") > -1) ? msg : ("[SERVER] " + msg);
					break;

				default:
					return;
			}

			if (tolog.length > 0) {
				// Strip any stray HTML tags to keep log clean
				tolog = tolog.replace(/<[^<]+?>/g, "");
				AppLogUI.chat(tolog);
			}
		}

		private function getMyUsername():String {
			try {
				if (game != null) {
					if (game.sfc != null && game.sfc.myUserName != null) {
						return String(game.sfc.myUserName);
					}
					if (game.world != null && game.world.myAvatar != null && game.world.myAvatar.objData != null && game.world.myAvatar.objData.strUsername != null) {
						return String(game.world.myAvatar.objData.strUsername);
					}
				}
			}
			catch (e:Error) {
			}
			return "";
		}
	}
}
