package handler {

	import flash.display.MovieClip;
	import flash.utils.getTimer;
	import input.PacketLoggerUI;
	import ui.InfoMessage;

	public class PacketHandler {

		private var game:MovieClip;

		public function PacketHandler(game:MovieClip) {
			this.game = game;
		}

		public function handleServerResponse(msg:String):void {
			// JSON parsing
			if (msg.indexOf("{") == 0) {
				try {
					var data:Object = JSON.parse(msg);
					if (data && data.b && data.b.o) {
						var obj:Object = data.b.o;
						var cmd:String = obj.cmd;

						switch (cmd) {
							case "initUserData":
								if (obj.data) {
									checkUserAccessLevel(obj.data.strUsername, int(obj.data.intAccessLevel));
								}
								break;

							case "initUserDatas":
								if (obj.a != null) {
									for each (var user:Object in obj.a) {
										if (user.data) {
											checkUserAccessLevel(user.data.strUsername, int(user.data.intAccessLevel));
										}
									}
								}
								break;
						}
					}
				}
				catch (e:Error) {
					// Not valid JSON or other error
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
