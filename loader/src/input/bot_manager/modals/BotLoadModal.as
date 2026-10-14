package input.bot_manager.modals {

	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.text.TextField;

	import engine.BotEngine;
	import ui.CloseButton;
	import ui.InfoMessage;
	import ui.MyButton;
	import ui.UIUtils;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class BotLoadModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var botEngine:BotEngine;
		private var onLoadedCallback:Function;

		private var explorer:BotFileExplorer;
		private var pathSub:TextField;

		public function BotLoadModal(botEngine:BotEngine, onLoadedCallback:Function = null) {
			super();
			this.botEngine = botEngine;
			this.onLoadedCallback = onLoadedCallback;
			this.visible = false;

			buildUI();
		}

		public static function isWritable(dir:File):Boolean {
			if (dir == null)
				return false;
			try {
				if (!dir.exists) {
					dir.createDirectory();
				}
				var testFile:File = dir.resolvePath(".wr_test_" + int(Math.random() * 10000) + ".tmp");
				var fs:FileStream = new FileStream();
				fs.open(testFile, FileMode.WRITE);
				fs.writeByte(1);
				fs.close();
				if (testFile.exists) {
					testFile.deleteFile();
				}
				return true;
			}
			catch (err:Error) {
				return false;
			}
			return false;
		}

		public static function getBotDirectory():File {
			// 1. Android public /storage/emulated/0/Documents/YouMadBro/Bots
			try {
				var aDoc:File = new File("/storage/emulated/0/Documents/YouMadBro/Bots");
				if (isWritable(aDoc))
					return aDoc;
			}
			catch (e1:Error) {
			}

			// 2. Android public /sdcard/Documents/YouMadBro/Bots
			try {
				var aSd:File = new File("/sdcard/Documents/YouMadBro/Bots");
				if (isWritable(aSd))
					return aSd;
			}
			catch (e2:Error) {
			}

			// 3. Android public /storage/emulated/0/YouMadBro/Bots
			try {
				var aRoot:File = new File("/storage/emulated/0/YouMadBro/Bots");
				if (isWritable(aRoot))
					return aRoot;
			}
			catch (e3:Error) {
			}

			// 4. Standard documentsDirectory (Desktop PC/Mac)
			try {
				var dDoc:File = File.documentsDirectory.resolvePath("YouMadBro/Bots");
				if (isWritable(dDoc))
					return dDoc;
			}
			catch (e4:Error) {
			}

			// 5. User Directory
			try {
				if (File.userDirectory != null && File.userDirectory.exists) {
					var uDoc:File = File.userDirectory.resolvePath("Documents/YouMadBro/Bots");
					if (isWritable(uDoc))
						return uDoc;
				}
			}
			catch (eU:Error) {
			}

			// 6. Guaranteed Writable Fallback: applicationStorageDirectory
			try {
				var appDir:File = File.applicationStorageDirectory.resolvePath("YouMadBro/Bots");
				if (!appDir.exists) {
					appDir.createDirectory();
				}
				return appDir;
			}
			catch (e5:Error) {
			}

			return File.applicationStorageDirectory;
		}

		public static function getAllBotDirectories():Array {
			var dirs:Array = [];
			var seenPaths:Object = {};

			function addDir(d:File):void {
				if (d != null) {
					try {
						var np:String = d.nativePath;
						if (np != null && np.length > 0 && !seenPaths[np]) {
							seenPaths[np] = true;
							dirs.push(d);
						}
					}
					catch (err:Error) {
					}
				}
			}

			// Android Public Paths - YouMadBro
			var directPaths:Array = [
					"/storage/emulated/0/Documents/YouMadBro/Bots",
					"/storage/emulated/0/YouMadBro/Bots",
					"/sdcard/Documents/YouMadBro/Bots",
					"/sdcard/YouMadBro/Bots",
					"/storage/emulated/0/Download/YouMadBro/Bots"
				];

			for each (var p:String in directPaths) {
				try {
					var f:File = new File(p);
					if (f.exists && f.isDirectory) {
						addDir(f);
					}
				}
				catch (ePath:Error) {
				}
			}

			// Standard AIR directories - YouMadBro
			try {
				if (File.documentsDirectory != null)
					addDir(File.documentsDirectory.resolvePath("YouMadBro/Bots"));
			}
			catch (eDocY1:Error) {
			}
			try {
				if (File.userDirectory != null)
					addDir(File.userDirectory.resolvePath("Documents/YouMadBro/Bots"));
			}
			catch (eUserY1:Error) {
			}
			try {
				if (File.userDirectory != null)
					addDir(File.userDirectory.resolvePath("YouMadBro/Bots"));
			}
			catch (eUserY2:Error) {
			}
			try {
				if (File.applicationStorageDirectory != null)
					addDir(File.applicationStorageDirectory.resolvePath("YouMadBro/Bots"));
			}
			catch (eAppY:Error) {
			}

			// Primary directory
			try {
				addDir(getBotDirectory());
			}
			catch (ePrim:Error) {
			}

			return dirs;
		}

		public static function getDisplayPath(dir:File):String {
			if (dir == null) {
				return "Bots/";
			}
			try {
				var np:String = dir.nativePath;
				if (np == null || np.length == 0) {
					return dir.name + "/";
				}
				var idx:int = np.indexOf("YouMadBro/Bots");
				if (idx != -1) {
					return np.substring(idx);
				}
				idx = np.indexOf("YouMadBro\\Bots");
				if (idx != -1) {
					return np.substring(idx);
				}
				if (np.indexOf("/storage/emulated/0/") == 0) {
					return np.replace("/storage/emulated/0/", "Storage > ");
				}
				return dir.name + "/";
			}
			catch (e:Error) {
			}
			return dir.name;
		}

		private function buildUI():void {
			// Dimmer background
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			addChild(dimmer);

			// Dialog Card
			const boxW:Number = 480;
			const boxH:Number = 300;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Header
			const title:TextField = UIUtils.createLabel("LOAD BOT SCRIPT", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

			pathSub = UIUtils.createLabel("Folder: Documents/YouMadBro/Bots/", UIUtils.TEXT_DIM, 9.5, false);
			pathSub.x = boxX + 130;
			pathSub.y = boxY + 14;
			pathSub.width = 280;
			addChild(pathSub);

			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = boxX + boxW - 32;
			closeBtn.y = boxY + 10;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});
			addChild(closeBtn);

			// Divider under header
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(boxX + 16, boxY + 36);
			div.graphics.lineTo(boxX + boxW - 16, boxY + 36);
			addChild(div);

			// Reusable File Explorer Component
			const listW:Number = boxW - 32;
			const listH:Number = 200;
			explorer = new BotFileExplorer(
					listW,
					listH,
					"Load",
					MyButton.TYPE_PRIMARY,
					loadFile,
					onFolderChanged,
					loadFile
				);
			explorer.x = boxX + 16;
			explorer.y = boxY + 44;
			addChild(explorer);

			// Footer Buttons
			const refreshBtn:MyButton = new MyButton("Refresh", 76, 26, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					refreshList();
				});
			refreshBtn.x = boxX + 16;
			refreshBtn.y = boxY + boxH - 44;
			addChild(refreshBtn);

			if (Config.isAndroid) {
				const safPickBtn:MyButton = new MyButton("📂 Import File (SAF)", 140, 26, MyButton.TYPE_PRIMARY, onNativePickClick);
				safPickBtn.x = refreshBtn.x + 76 + 8;
				safPickBtn.y = boxY + boxH - 44;
				addChild(safPickBtn);
			}

			const closeFooterBtn:MyButton = new MyButton("Close", 64, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					close();
				});
			closeFooterBtn.x = boxX + boxW - 16 - 64;
			closeFooterBtn.y = boxY + boxH - 44;
			addChild(closeFooterBtn);
		}

		private function onFolderChanged(dir:File):void {
			if (pathSub != null) {
				pathSub.text = "Folder: " + explorer.getDisplayPath();
			}
		}

		private function onNativePickClick(e:MouseEvent):void {
			BatteryOptimizer.openFilePicker(function(success:Boolean, fileName:String, content:String):void {
					if (!success || content == null || content.length == 0) {
						return;
					}

					if (botEngine != null) {
						var ok:Boolean = botEngine.importConfigJSON(content);
						if (ok) {
							botEngine.log("Bot script loaded via SAF: " + fileName);
							if (onLoadedCallback != null) {
								onLoadedCallback(fileName);
							}
							close();
							showAlert("Bot Loaded", "Successfully imported & loaded:\n" + fileName);
						}
						else {
							showAlert("Import Failed", "Invalid bot JSON configuration in file:\n" + fileName);
						}
					}
				});
		}

		public function open():void {
			refreshList();
			this.visible = true;
			if (parent != null) {
				parent.setChildIndex(this, parent.numChildren - 1);
			}
		}

		public function close():void {
			this.visible = false;
		}

		public function refreshList():void {
			if (explorer != null) {
				explorer.refreshList();
				if (pathSub != null) {
					pathSub.text = "Folder: " + explorer.getDisplayPath();
				}
			}
		}

		private function loadFile(f:File):void {
			if (f == null) {
				return;
			}
			try {
				var stream:FileStream = new FileStream();
				stream.open(f, FileMode.READ);
				var content:String = stream.readUTFBytes(stream.bytesAvailable);
				stream.close();

				if (botEngine != null && botEngine.importConfigJSON(content)) {
					botEngine.log("Bot script loaded from: " + f.name);
					close();

					if (onLoadedCallback != null) {
						onLoadedCallback(f.name);
					}

					showAlert("Bot Loaded", "Successfully loaded:\n" + f.name);
				}
				else {
					showAlert("Import Failed", "Invalid bot JSON configuration in file:\n" + f.name);
				}
			}
			catch (err:Error) {
				showAlert("Read Error", "Could not read file: " + err.message);
			}
		}

		private function showAlert(title:String, desc:String):void {
			const alert:InfoMessage = new InfoMessage(title, desc);
			if (stage != null) {
				stage.addChild(alert);
			}
			else if (parent != null) {
				parent.addChild(alert);
			}
		}
	}
}
