package {

	/**
	 * Shared utility functions for AQW Mobile loader and engines.
	 */
	public class Utils {

		/**
		 * Trims leading and trailing whitespace from a string.
		 */
		public static function trim(str:String):String {
			if (str == null)
				return "";
			return str.replace(/^\s+|\s+$/g, "");
		}

		/**
		 * Normalizes game packets received from server or sent from client.
		 * Strips debug/logging prefixes and trailing length metadata, and trims whitespace.
		 */
		public static function normalizePacket(packet:String):String {
			if (packet == null)
				return "";

			if (packet.indexOf("[Sending - STR]: ") > -1) {
				packet = packet.replace("[Sending - STR]: ", "");
			}
			if (packet.indexOf("[ RECEIVED ]: ") > -1) {
				packet = packet.replace("[ RECEIVED ]: ", "");
			}
			if (packet.indexOf("[Sending]: ") > -1) {
				packet = packet.replace("[Sending]: ", "");
			}
			if (packet.indexOf(", (len: ") > -1) {
				var index:int = packet.indexOf(", (len: ");
				packet = packet.slice(0, index);
			}
			return trim(packet);
		}

		/**
		 * Safely parses a JSON string, returning null (or defaultValue) if parsing fails.
		 */
		public static function parseJSON(jsonStr:String, defaultValue:* = null):* {
			if (jsonStr == null || jsonStr.length == 0)
				return defaultValue;
			try {
				return JSON.parse(jsonStr);
			}
			catch (e:Error) {
				return defaultValue;
			}
		}

		/**
		 * Formats seconds into HH:MM:SS or MM:SS.
		 */
		public static function formatDuration(totalSecs:int):String {
			if (totalSecs < 0)
				totalSecs = 0;
			const hrs:int = Math.floor(totalSecs / 3600);
			const mins:int = Math.floor((totalSecs % 3600) / 60);
			const secs:int = totalSecs % 60;

			var hStr:String = hrs < 10 ? "0" + hrs : "" + hrs;
			var mStr:String = mins < 10 ? "0" + mins : "" + mins;
			var sStr:String = secs < 10 ? "0" + secs : "" + secs;

			if (hrs > 0) {
				return hStr + ":" + mStr + ":" + sStr;
			}
			return mStr + ":" + sStr;
		}

		/**
		 * Pads a number with leading zeroes.
		 */
		public static function padZero(num:int, digits:int = 2):String {
			var s:String = num.toString();
			while (s.length < digits) {
				s = "0" + s;
			}
			return s;
		}

		/**
		 * Cleans and lowers an item name for consistent comparisons.
		 */
		public static function cleanItemName(name:String):String {
			if (name == null)
				return "";
			return trim(name).toLowerCase();
		}

	}
}
