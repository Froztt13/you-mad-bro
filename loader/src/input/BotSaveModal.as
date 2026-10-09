package input {

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
	import ui.MyTextField;
	import ui.UIUtils;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class BotSaveModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var botEngine:BotEngine;
		private var onSavedCallback:Function;

		private var saveFileNameInput:MyTextField;

		public function BotSaveModal(botEngine:BotEngine, onSavedCallback:Function = null) {
			super();
			this.botEngine = botEngine;
			this.onSavedCallback = onSavedCallback;
			this.visible = false;

			buildUI();
		}

		private function buildUI():void {
			// Dimmer background
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			addChild(dimmer);

			// Dialog Card
			const boxW:Number = 420;
			const boxH:Number = 190;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Header
			const title:TextField = UIUtils.createLabel("SAVE BOT SCRIPT", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

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

			// Folder destination hint
			const folderLbl:TextField = UIUtils.createLabel("Destination: Documents/YouMadBro/Bots/", UIUtils.TEXT_DIM, 9.5);
			folderLbl.x = boxX + 16;
			folderLbl.y = boxY + 44;
			addChild(folderLbl);

			const nameLbl:TextField = UIUtils.createLabel("Script File Name:", UIUtils.TEXT_MUTED, 10.5);
			nameLbl.x = boxX + 16;
			nameLbl.y = boxY + 66;
			addChild(nameLbl);

			saveFileNameInput = new MyTextField(280, 26);
			saveFileNameInput.x = boxX + 16;
			saveFileNameInput.y = boxY + 86;
			saveFileNameInput.text = "my_bot";
			addChild(saveFileNameInput);

			const extLbl:TextField = UIUtils.createLabel(".json", UIUtils.TEXT_MAIN, 11, true);
			extLbl.x = boxX + 16 + 284;
			extLbl.y = boxY + 90;
			addChild(extLbl);

			if (Config.isAndroid) {
				const safExportBtn:MyButton = new MyButton("📁 Export via SAF", 125, 26, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
						saveFileViaSaf();
					});
				safExportBtn.x = boxX + 16;
				safExportBtn.y = boxY + boxH - 42;
				addChild(safExportBtn);
			}

			// Footer Buttons
			const saveActionBtn:MyButton = new MyButton("Save Script", 90, 26, MyButton.TYPE_SUCCESS, function(e:MouseEvent):void {
					saveFile();
				});
			saveActionBtn.x = boxX + boxW - 16 - 90;
			saveActionBtn.y = boxY + boxH - 42;
			addChild(saveActionBtn);

			const cancelBtn:MyButton = new MyButton("Cancel", 64, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					close();
				});
			cancelBtn.x = saveActionBtn.x - 70;
			cancelBtn.y = boxY + boxH - 42;
			addChild(cancelBtn);
		}

		private function saveFileViaSaf():void {
			var rawName:String = saveFileNameInput.trimmedText;
			if (rawName.length == 0) {
				rawName = "my_bot";
			}
			rawName = rawName.replace(/[\/\\:\*\?"<>\|]/g, "_");
			if (rawName.toLowerCase().indexOf(".json") != rawName.length - 5) {
				rawName += ".json";
			}

			var content:String = botEngine != null ? botEngine.exportConfigJSON() : "{}";
			BatteryOptimizer.saveFilePicker(rawName, content, function(success:Boolean, savedName:String):void {
					if (success) {
						if (botEngine != null) {
							botEngine.log("Bot script exported via SAF: " + savedName);
						}
						close();
						showAlert("Export Successful", "Bot script exported successfully:\n" + savedName);
					}
				});
		}

		public function open():void {
			this.visible = true;
			if (parent != null) {
				parent.setChildIndex(this, parent.numChildren - 1);
			}
		}

		public function close():void {
			this.visible = false;
		}

		private function saveFile():void {
			var rawName:String = saveFileNameInput.trimmedText;
			if (rawName.length == 0) {
				showAlert("Invalid Name", "Please enter a valid file name.");
				return;
			}

			// Clean name and ensure .json extension
			rawName = rawName.replace(/[\/\\:\*\?"<>\|]/g, "_");
			if (rawName.toLowerCase().indexOf(".json") == rawName.length - 5) {
				rawName = rawName.substr(0, rawName.length - 5);
			}
			var fileName:String = rawName + ".json";

			var candidateDirs:Array = [];
			try {
				candidateDirs.push(BotLoadModal.getBotDirectory());
			}
			catch (e0:Error) {
			}
			try {
				candidateDirs.push(File.applicationStorageDirectory.resolvePath("YouMadBro/Bots"));
			}
			catch (e1:Error) {
			}
			try {
				candidateDirs.push(File.applicationStorageDirectory);
			}
			catch (e2:Error) {
			}

			var savedFile:File = null;
			var lastError:Error = null;
			var content:String = botEngine != null ? botEngine.exportConfigJSON() : "{}";

			for each (var targetDir:File in candidateDirs) {
				if (targetDir == null)
					continue;
				try {
					if (!targetDir.exists) {
						targetDir.createDirectory();
					}
					var f:File = targetDir.resolvePath(fileName);
					var stream:FileStream = new FileStream();
					stream.open(f, FileMode.WRITE);
					stream.writeUTFBytes(content);
					stream.close();

					savedFile = f;
					break;
				}
				catch (errWrite:Error) {
					lastError = errWrite;
				}
			}

			if (savedFile == null) {
				showAlert("Save Error", "Could not save file: " + (lastError != null ? lastError.message : "Access denied"));
				return;
			}

			if (botEngine != null) {
				botEngine.log("Bot script saved to: " + savedFile.nativePath);
			}

			close();

			if (onSavedCallback != null) {
				onSavedCallback(fileName);
			}

			var displayPath:String = savedFile.nativePath;
			if (displayPath.indexOf("/storage/emulated/0/") == 0) {
				displayPath = displayPath.replace("/storage/emulated/0/", "Internal Storage > ");
			}

			var isPublic:Boolean = (savedFile.nativePath.indexOf("/storage/emulated/0/") == 0 || savedFile.nativePath.indexOf("/sdcard/") == 0);
			if (Config.isAndroid && !isPublic) {
				showAlert("Bot Saved (App Storage)", "Saved to App Storage:\n" + savedFile.name + "\n\n" + displayPath + "\n\n(Tip: Allow 'All files access' in Android Settings to save directly into public Documents folder)");
			}
			else {
				showAlert("Bot Saved", "Successfully saved:\n" + savedFile.name + "\n\n" + displayPath);
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
