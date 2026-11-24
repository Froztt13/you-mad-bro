package commands {

	import engine.BotEngine;
	import Utils;

	/**
	 * Sends a raw packet string to the server (sfc.sendString) or injects it to the client (sfc.handleMessage).
	 */
	public class SendPacketCommand extends BotCommand {

		public var packet:String = "";
		public var forClient:Boolean = false;
		public var delayMs:int = 1000;

		public function SendPacketCommand(packet:String = "", forClient:Boolean = false, delayMs:int = 1000) {
			super(BotCommand.TYPE_SEND_PACKET);
			this.packet = (packet != null) ? Utils.trim(packet) : "";
			this.forClient = forClient;
			this.delayMs = Math.max(100, delayMs);
		}

		override public function toJSON():Object {
			var obj:Object = {
					"type": type,
					"packet": packet
				};
			if (forClient) {
				obj["forClient"] = true;
			}
			if (delayMs != 1000) {
				obj["delayMs"] = delayMs;
			}
			return obj;
		}

		public static function fromJSON(data:Object):SendPacketCommand {
			if (data == null)
				return null;
			var pkt:String = data.packet != null ? String(data.packet) : "";
			var client:Boolean = Boolean(data.forClient);
			var dMs:int = (data.delayMs != null) ? int(data.delayMs) : 1000;
			return new SendPacketCommand(pkt, client, dMs);
		}

		override public function execute(bot:BotEngine):void {
			if (packet == null || packet.length == 0) {
				bot.advanceStep(100);
				return;
			}

			var game:Object = bot.getGame();
			try {
				if (game != null && game.sfc != null) {
					if (forClient) {
						if ("handleMessage" in game.sfc) {
							game.sfc.handleMessage(packet);
						}
						else {
							game.sfc["handleMessage"](packet);
						}
						bot.log("[Packet] Injected to Client: " + packet);
					}
					else if (game.sfc.sendString != null) {
						game.sfc.sendString(packet);
						bot.log("[Packet] Sent to Server: " + packet);
					}
				}
			}
			catch (e:Error) {
				bot.log("[Packet] Error: " + e.message);
			}

			bot.advanceStep(delayMs);
		}

		override public function toString():String {
			var prefix:String = forClient ? "Client Packet [" : "Server Packet [";
			var preview:String = packet.length > 36 ? packet.substr(0, 33) + "..." : packet;
			return prefix + preview + "]";
		}
	}
}
