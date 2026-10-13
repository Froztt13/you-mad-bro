package {

	import flash.system.Capabilities;

	public class Config {

		public static const GAME_BASE_URL:String = "https://game.aq.com/game/";

		public static const API_VERSION_URL:String = GAME_BASE_URL + "api/data/gameversion";
		public static const API_LOGIN_URL:String = GAME_BASE_URL + "api/login/now";

		public static const GAME_SWF_PATH:String = "app:/gamefiles/Game.swf";

		public static const APP_VERSION:String = "v1.1.0";

		public static const GITHUB_REPO:String = "Froztt13/you-mad-bro";
		public static const GITHUB_API_LATEST_RELEASE:String = "https://api.github.com/repos/" + GITHUB_REPO + "/releases/latest";
		public static const GITHUB_RELEASES_URL:String = "https://github.com/" + GITHUB_REPO + "/releases";

		public static function get isAndroid():Boolean {
			return Capabilities.version.indexOf("AND") == 0;
		}

		public static function get isMac():Boolean {
			return Capabilities.version.indexOf("MAC") == 0;
		}

	}

}