package com.aqw.battery
{
	import flash.external.ExtensionContext;
	import flash.events.StatusEvent;

	public class BatteryOptimizer
	{
		private static const EXTENSION_ID:String = "com.aqw.battery";
		private static var ctx:ExtensionContext = null;
		private static var isAvailable:Boolean = false;
		private static var checkedAvailability:Boolean = false;

		public static var onFilePickResult:Function = null;
		public static var onFileSaveResult:Function = null;

		private static function getContext():ExtensionContext
		{
			if (!checkedAvailability)
			{
				checkedAvailability = true;
				try
				{
					ctx = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
					isAvailable = (ctx != null);
					if (ctx != null)
					{
						ctx.addEventListener(StatusEvent.STATUS, onStatusEvent);
					}
				}
				catch (e:Error)
				{
					isAvailable = false;
				}
			}
			return ctx;
		}

		private static function onStatusEvent(e:StatusEvent):void
		{
			if (e.code == "SAF_OPEN_SUCCESS")
			{
				var name:String = getLastPickedFileName();
				var content:String = getLastPickedContent();
				if (onFilePickResult != null)
				{
					onFilePickResult(true, name, content);
				}
			}
			else if (e.code == "SAF_OPEN_CANCELLED" || e.code == "SAF_OPEN_ERROR")
			{
				if (onFilePickResult != null)
				{
					onFilePickResult(false, "", "");
				}
			}
			else if (e.code == "SAF_SAVE_SUCCESS")
			{
				if (onFileSaveResult != null)
				{
					onFileSaveResult(true, e.level);
				}
			}
			else if (e.code == "SAF_SAVE_CANCELLED" || e.code == "SAF_SAVE_ERROR")
			{
				if (onFileSaveResult != null)
				{
					onFileSaveResult(false, "");
				}
			}
		}

		public static function requestUnrestricted():void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("requestUnrestricted");
				}
				catch (e:Error) {}
			}
		}

		public static function isIgnoringBatteryOptimizations():Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("isIgnoringBatteryOptimizations");
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function openAppDetails():void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("openAppDetails");
				}
				catch (e:Error) {}
			}
		}

		public static function hasStoragePermission():Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("hasStoragePermission");
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function requestStoragePermission():void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("requestStoragePermission");
				}
				catch (e:Error) {}
			}
		}

		public static function startKeepAlive(title:String = "YouMadBro Bot Active", text:String = "Background keep-alive running..."):void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("startForeground", title, text);
				}
				catch (e:Error) {}
			}
		}

		public static function updateKeepAlive(title:String, text:String):void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("updateForeground", title, text);
				}
				catch (e:Error) {}
			}
		}

		public static function stopKeepAlive():void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("stopForeground");
				}
				catch (e:Error) {}
			}
		}

		public static function isKeepAliveRunning():Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("isKeepAliveRunning");
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function sendNotification(title:String, text:String, id:int = 2001):void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("sendNotification", title, text, id);
				}
				catch (e:Error) {}
			}
		}

		public static function cancelNotification(id:int = 2001):void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("cancelNotification", id);
				}
				catch (e:Error) {}
			}
		}

		public static function requestNotificationPermission():void
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					c.call("requestNotificationPermission");
				}
				catch (e:Error) {}
			}
		}

		public static function isPipSupported():Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("isPipSupported");
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function isInPipMode():Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("isInPipMode");
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function enterPipMode(aspectRatioNum:int = 16, aspectRatioDen:int = 9):Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("enterPipMode", aspectRatioNum, aspectRatioDen);
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function setPipAutoEnter(enabled:Boolean, aspectRatioNum:int = 16, aspectRatioDen:int = 9):Boolean
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("setPipAutoEnter", enabled, aspectRatioNum, aspectRatioDen);
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function openFilePicker(callback:Function = null, mimeType:String = "*/*"):Boolean
		{
			if (callback != null)
			{
				onFilePickResult = callback;
			}
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("openFilePicker", mimeType);
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function saveFilePicker(fileName:String, content:String, callback:Function = null):Boolean
		{
			if (callback != null)
			{
				onFileSaveResult = callback;
			}
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("saveFilePicker", fileName, content);
					return res === true;
				}
				catch (e:Error) {}
			}
			return false;
		}

		public static function getLastPickedFileName():String
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("getLastPickedFileName");
					return res != null ? String(res) : "";
				}
				catch (e:Error) {}
			}
			return "";
		}

		public static function getLastPickedContent():String
		{
			var c:ExtensionContext = getContext();
			if (c != null)
			{
				try
				{
					var res:* = c.call("getLastPickedContent");
					return res != null ? String(res) : "";
				}
				catch (e:Error) {}
			}
			return "";
		}
	}
}
