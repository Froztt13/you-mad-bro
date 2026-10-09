package commands {

	import engine.BotEngine;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class NotifCommand extends BotCommand {

		public var title:String = "Bot Alert";
		public var message:String = "";

		public function NotifCommand(message:String = "", title:String = "Bot Alert") {
			super(BotCommand.TYPE_NOTIF);
			this.message = message != null ? message : "";
			this.title = (title != null && title.length > 0) ? title : "Bot Alert";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"title": title,
					"message": message
				};
		}

		public static function fromJSON(data:Object):NotifCommand {
			if (data == null)
				return null;
			var t:String = data.title != null ? String(data.title) : "Bot Alert";
			var m:String = data.message != null ? String(data.message) : "";
			return new NotifCommand(m, t);
		}

		override public function execute(bot:BotEngine):void {
			bot.log("Notification: " + title + " - " + message);
			if (Config.isAndroid) {
				try {
					BatteryOptimizer.sendNotification(title, message, 2003);
				}
				catch (e:Error) {
				}
			}
			bot.advanceStep();
		}

		override public function toString():String {
			var preview:String = message;
			if (preview.length > 25) {
				preview = preview.substr(0, 25) + "...";
			}
			return "Notif [" + (preview.length > 0 ? preview : title) + "]";
		}
	}
}
