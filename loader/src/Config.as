package {

	import flash.system.Capabilities;

	public class Config {

		public static const GAME_BASE_URL:String = "https://game.aq.com/game/";

		public static const API_VERSION_URL:String = GAME_BASE_URL + "api/data/gameversion";
		public static const API_LOGIN_URL:String = GAME_BASE_URL + "api/login/now";

		public static const GAME_SWF_PATH:String = "app:/gamefiles/Game.swf";

		public static const APP_VERSION:String = "v1.0.0";

		public static function get isAndroid():Boolean {
			return Capabilities.version.indexOf("AND") == 0;
		}

		public static function get isMac():Boolean {
			return Capabilities.version.indexOf("MAC") == 0;
		}

	}

}