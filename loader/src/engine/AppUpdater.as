package engine {

	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.navigateToURL;
	import ui.ConfirmationMessage;
	import ui.InfoMessage;
	import ui.MyButton;
	import Config;

	public class AppUpdater {

		private static const SO_KEY:String = "aqw_updater_settings";
		private static const PREF_LAST_CHECK:String = "lastCheckTime";
		private static const CHECK_INTERVAL_MS:Number = 24 * 60 * 60 * 1000; // 24 hours (86,400,000 ms)

		private static var isChecking:Boolean = false;

		public static function checkUpdate(stage:Stage, isManualCheck:Boolean = false):void {
			if (stage == null || isChecking)
				return;

			var now:Number = new Date().getTime();

			// If background auto-check, verify that 24 hours have elapsed since the last check
			if (!isManualCheck) {
				var lastCheck:Number = getLastCheckTime();
				if (lastCheck > 0 && (now - lastCheck) < CHECK_INTERVAL_MS) {
					return;
				}
			}

			isChecking = true;

			var req:URLRequest = new URLRequest(Config.GITHUB_API_LATEST_RELEASE);
			req.requestHeaders.push(new URLRequestHeader("User-Agent", "YouMadBro-App"));
			req.requestHeaders.push(new URLRequestHeader("Accept", "application/vnd.github.v3+json"));

			var loader:URLLoader = new URLLoader();

			loader.addEventListener(Event.COMPLETE, function(e:Event):void {
				isChecking = false;
				saveLastCheckTime(now);

				try {
					var data:Object = JSON.parse(loader.data);
					if (data == null)
						return;

					var latestTag:String = String(data.tag_name || "");
					var releaseUrl:String = String(data.html_url || Config.GITHUB_RELEASES_URL);

					if (latestTag.length > 0 && isNewerVersion(latestTag, Config.APP_VERSION)) {
						var desc:String = "A new release (" + latestTag + ") is available!\nYour current version: " + Config.APP_VERSION + "\n\nOpen GitHub releases page to update?";
						var confirmDialog:ConfirmationMessage = new ConfirmationMessage(
							"Update Available",
							desc,
							function():void {
								try {
									navigateToURL(new URLRequest(releaseUrl), "_blank");
								}
								catch (errNav:Error) {
								}
							},
							null,
							"Download",
							"Later",
							MyButton.TYPE_PRIMARY
						);
						stage.addChild(confirmDialog);
					}
					else if (isManualCheck) {
						stage.addChild(new InfoMessage("Up to Date", "You are already using the latest version (" + Config.APP_VERSION + ")."));
					}
				}
				catch (errParse:Error) {
					if (isManualCheck) {
						stage.addChild(new InfoMessage("Update Error", "Failed to parse GitHub release data."));
					}
				}
			});

			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
				isChecking = false;
				if (isManualCheck) {
					stage.addChild(new InfoMessage("Connection Failed", "Unable to connect to GitHub API. Please check your internet connection."));
				}
			});

			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
				isChecking = false;
				if (isManualCheck) {
					stage.addChild(new InfoMessage("Security Error", "Connection to GitHub API was blocked by security policy."));
				}
			});

			try {
				loader.load(req);
			}
			catch (errLoad:Error) {
				isChecking = false;
				if (isManualCheck) {
					stage.addChild(new InfoMessage("Error", "Failed to start update check."));
				}
			}
		}

		public static function isNewerVersion(latest:String, current:String):Boolean {
			if (latest == null || latest.length == 0 || current == null || current.length == 0)
				return false;

			var cleanLatest:String = latest.replace(/^[vV]/, "").split("-")[0];
			var cleanCurrent:String = current.replace(/^[vV]/, "").split("-")[0];

			var lParts:Array = cleanLatest.split(".");
			var cParts:Array = cleanCurrent.split(".");

			var len:int = Math.max(lParts.length, cParts.length);
			for (var i:int = 0; i < len; i++) {
				var lNum:int = (i < lParts.length) ? parseInt(lParts[i]) : 0;
				var cNum:int = (i < cParts.length) ? parseInt(cParts[i]) : 0;
				if (isNaN(lNum)) lNum = 0;
				if (isNaN(cNum)) cNum = 0;

				if (lNum > cNum)
					return true;
				if (lNum < cNum)
					return false;
			}
			return false;
		}

		private static function getLastCheckTime():Number {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null && so.data.hasOwnProperty(PREF_LAST_CHECK)) {
					return Number(so.data[PREF_LAST_CHECK]);
				}
			}
			catch (e:Error) {
			}
			return 0;
		}

		private static function saveLastCheckTime(time:Number):void {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null) {
					so.data[PREF_LAST_CHECK] = time;
					so.flush();
				}
			}
			catch (e:Error) {
			}
		}
	}
}
