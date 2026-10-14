package input.bot_manager.modals {

	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	import ui.MyButton;
	import ui.ScrollContainer;
	import ui.UIUtils;

	public class BotFileExplorer extends Sprite {

		private var compWidth:Number;
		private var compHeight:Number;
		private var actionLabel:String;
		private var actionBtnType:String;

		private var onFileAction:Function;
		private var onFolderChanged:Function;
		private var onFileSelect:Function;

		private var loadListScroll:ScrollContainer;
		private var loadEmptyLabel:TextField;

		private var currentDir:File = null;
		private var selectedFileName:String = "";
		private var currentFiles:Array = [];
		private var currentFolders:Array = [];
		private var fileRowBgs:Array = [];

		public function BotFileExplorer(
				w:Number,
				h:Number,
				actionLabel:String = "Load",
				actionBtnType:String = MyButton.TYPE_PRIMARY,
				onFileAction:Function = null,
				onFolderChanged:Function = null,
				onFileSelect:Function = null
			) {
			super();
			this.compWidth = w;
			this.compHeight = h;
			this.actionLabel = actionLabel;
			this.actionBtnType = actionBtnType;
			this.onFileAction = onFileAction;
			this.onFolderChanged = onFolderChanged;
			this.onFileSelect = onFileSelect;

			buildUI();
		}

		private function buildUI():void {
			loadListScroll = new ScrollContainer(compWidth, compHeight, 10, true);
			addChild(loadListScroll);

			loadEmptyLabel = UIUtils.createLabel(
					"No bot files (.json) found.",
					UIUtils.TEXT_DIM,
					11,
					false,
					TextFormatAlign.CENTER
				);
			loadEmptyLabel.width = compWidth - 16;
			loadEmptyLabel.x = 8;
			loadEmptyLabel.y = 50;
			loadEmptyLabel.multiline = true;
			loadEmptyLabel.wordWrap = true;
		}

		public function getCurrentDir():File {
			return currentDir;
		}

		public function setCurrentDir(dir:File):void {
			currentDir = dir;
			refreshList();
			if (onFolderChanged != null) {
				onFolderChanged(currentDir);
			}
		}

		public function getSelectedFileName():String {
			return selectedFileName;
		}

		public function setSelectedFileName(name:String):void {
			selectedFileName = name != null ? name : "";
			highlightSelected();
		}

		public function getFiles():Array {
			return currentFiles;
		}

		public function getDisplayPath():String {
			return BotLoadModal.getDisplayPath(currentDir);
		}

		public function canGoUp():Boolean {
			return currentDir != null;
		}

		public function goUp():void {
			if (currentDir == null) {
				return;
			}
			try {
				var parentDir:File = currentDir.parent;
				var isRoot:Boolean = false;
				if (parentDir == null || !parentDir.exists) {
					isRoot = true;
				}
				else {
					var rootDirs:Array = BotLoadModal.getAllBotDirectories();
					for each (var root:File in rootDirs) {
						if (root != null && (parentDir.nativePath == root.nativePath || currentDir.nativePath == root.nativePath)) {
							isRoot = true;
							break;
						}
					}
				}

				if (isRoot) {
					currentDir = null;
				}
				else {
					currentDir = parentDir;
				}
			}
			catch (e:Error) {
				currentDir = null;
			}

			refreshList();
			if (onFolderChanged != null) {
				onFolderChanged(currentDir);
			}
		}

		public function navigateTo(dir:File):void {
			if (dir != null && dir.exists && dir.isDirectory) {
				currentDir = dir;
				refreshList();
				if (onFolderChanged != null) {
					onFolderChanged(currentDir);
				}
			}
		}

		public function hasFileNamed(rawName:String):Boolean {
			if (rawName == null || rawName.length == 0) {
				return false;
			}
			var clean:String = rawName.toLowerCase();
			if (clean.indexOf(".json") == clean.length - 5) {
				clean = clean.substr(0, clean.length - 5);
			}
			for each (var f:File in currentFiles) {
				if (f == null || f.name == null) {
					continue;
				}
				var fn:String = f.name.toLowerCase();
				if (fn.indexOf(".json") == fn.length - 5) {
					fn = fn.substr(0, fn.length - 5);
				}
				if (fn == clean) {
					return true;
				}
			}
			return false;
		}

		public function getFileNamed(rawName:String):File {
			if (rawName == null || rawName.length == 0) {
				return null;
			}
			var clean:String = rawName.toLowerCase();
			if (clean.indexOf(".json") == clean.length - 5) {
				clean = clean.substr(0, clean.length - 5);
			}
			for each (var f:File in currentFiles) {
				if (f == null || f.name == null) {
					continue;
				}
				var fn:String = f.name.toLowerCase();
				if (fn.indexOf(".json") == fn.length - 5) {
					fn = fn.substr(0, fn.length - 5);
				}
				if (fn == clean) {
					return f;
				}
			}
			return null;
		}

		public function refreshList():void {
			loadListScroll.clearContent();
			fileRowBgs = [];
			currentFiles = [];
			currentFolders = [];

			var scanDirs:Array = (currentDir != null) ? [currentDir] : BotLoadModal.getAllBotDirectories();
			var seenFolderNames:Object = {};
			var seenFileNames:Object = {};

			for each (var dir:File in scanDirs) {
				try {
					if (dir != null && dir.exists && dir.isDirectory) {
						var list:Array = dir.getDirectoryListing();
						for each (var f:File in list) {
							if (f == null) {
								continue;
							}
							var fn:String = f.name;
							if (fn == null || fn.length == 0 || fn.charAt(0) == "." || fn.charAt(0) == "_") {
								continue;
							}

							if (f.isDirectory) {
								var folderKey:String = fn.toLowerCase();
								if (!seenFolderNames[folderKey]) {
									seenFolderNames[folderKey] = true;
									currentFolders.push(f);
								}
							}
							else {
								var nameLower:String = fn.toLowerCase();
								var extLower:String = f.extension != null ? f.extension.toLowerCase() : "";
								var isBot:Boolean = (extLower == "json" || extLower == "txt");
								if (!isBot && nameLower.length > 5) {
									isBot = (nameLower.substr(nameLower.length - 5) == ".json" || nameLower.substr(nameLower.length - 4) == ".txt");
								}

								if (isBot && !seenFileNames[nameLower]) {
									seenFileNames[nameLower] = true;
									currentFiles.push(f);
								}
							}
						}
					}
				}
				catch (eDir:Error) {
				}
			}

			currentFolders.sortOn("name", Array.CASEINSENSITIVE);
			currentFiles.sortOn("name", Array.CASEINSENSITIVE);

			const rowW:Number = loadListScroll.contentWidth;
			const rowH:Number = 30;
			const gap:Number = 4;
			var rowIndex:int = 0;

			if (canGoUp()) {
				var upRow:Sprite = createUpRow(rowW, rowH);
				upRow.y = rowIndex * (rowH + gap);
				loadListScroll.addItem(upRow);
				rowIndex++;
			}

			if (currentFolders.length == 0 && currentFiles.length == 0) {
				if (canGoUp()) {
					loadEmptyLabel.text = "This folder is empty.\nNo bot files (.json) found.";
					loadEmptyLabel.y = rowIndex * (rowH + gap) + 30;
					loadListScroll.addItem(loadEmptyLabel);
					loadEmptyLabel.visible = true;
					loadListScroll.updateScroll(rowIndex * (rowH + gap) + 100);
					return;
				}
				else {
					var primaryDir:File = BotLoadModal.getBotDirectory();
					var displayDir:String = primaryDir != null ? primaryDir.nativePath : "Documents/YouMadBro/Bots";
					if (displayDir.indexOf("/storage/emulated/0/") == 0) {
						displayDir = displayDir.replace("/storage/emulated/0/", "Internal Storage > ");
					}
					loadEmptyLabel.text = "No bot files (.json) found.\n\n" +
						"Place .json files in:\n" + displayDir + "\n\n" +
						"(Ensure Storage / Documents permission is allowed in Settings)";
					loadEmptyLabel.y = 50;
					loadListScroll.addItem(loadEmptyLabel);
					loadEmptyLabel.visible = true;
					return;
				}
			}

			loadEmptyLabel.visible = false;

			for each (var folderItem:File in currentFolders) {
				var fRow:Sprite = createFolderRow(folderItem, rowW, rowH);
				fRow.y = rowIndex * (rowH + gap);
				loadListScroll.addItem(fRow);
				rowIndex++;
			}

			for each (var fileItem:File in currentFiles) {
				var row:Sprite = createFileRow(fileItem, rowW, rowH);
				row.y = rowIndex * (rowH + gap);
				loadListScroll.addItem(row);
				rowIndex++;
			}

			loadListScroll.updateScroll(rowIndex * (rowH + gap));
			highlightSelected();
		}

		private function createUpRow(w:Number, h:Number):Sprite {
			var row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			var bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, UIUtils.BG_RECESSED, 0.95, UIUtils.BORDER_SUBTLE, 1);
			row.addChild(bg);

			var label:TextField = UIUtils.createLabel("⬆  .. (Back / Up)", UIUtils.TEXT_MUTED, 11, true);
			label.x = 8;
			label.y = 6;
			label.width = w - 80;
			label.height = 20;
			label.mouseEnabled = false;
			row.addChild(label);

			var btnUp:MyButton = new MyButton("Back", 58, 22, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					goUp();
				}, 10.5);
			btnUp.x = w - 66;
			btnUp.y = 4;
			row.addChild(btnUp);

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (e.target != btnUp && !btnUp.contains(e.target as DisplayObject)) {
						goUp();
					}
				});

			return row;
		}

		private function createFolderRow(f:File, w:Number, h:Number):Sprite {
			var row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			var bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, UIUtils.BG_DARK, 0.9, UIUtils.BORDER_SUBTLE, 1);
			row.addChild(bg);

			var nameLabel:TextField = UIUtils.createLabel("📁  " + f.name, 0xFFE082, 11, true);
			nameLabel.x = 8;
			nameLabel.y = 6;
			nameLabel.width = w - 80;
			nameLabel.height = 20;
			nameLabel.mouseEnabled = false;
			row.addChild(nameLabel);

			var btnOpen:MyButton = new MyButton("Open", 58, 22, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					navigateTo(f);
				}, 10.5);
			btnOpen.x = w - 66;
			btnOpen.y = 4;
			row.addChild(btnOpen);

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (e.target != btnOpen && !btnOpen.contains(e.target as DisplayObject)) {
						navigateTo(f);
					}
				});

			return row;
		}

		private function createFileRow(f:File, w:Number, h:Number):Sprite {
			var row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			var bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, UIUtils.BG_DARK, 0.9, UIUtils.BORDER_SUBTLE, 1);
			row.addChild(bg);

			fileRowBgs.push({
				name: f.name,
				shape: bg,
				w: w,
				h: h
			});

			var displayName:String = f.name;
			var nameLabel:TextField = UIUtils.createLabel("📄  " + displayName, UIUtils.TEXT_WHITE, 11, true);
			nameLabel.x = 8;
			nameLabel.y = 6;
			nameLabel.width = w - 80;
			nameLabel.height = 20;
			nameLabel.mouseEnabled = false;
			row.addChild(nameLabel);

			var btnAction:MyButton = new MyButton(actionLabel, 58, 22, actionBtnType, function(e:MouseEvent):void {
					selectedFileName = f.name;
					highlightSelected();
					if (onFileAction != null) {
						onFileAction(f);
					}
					else if (onFileSelect != null) {
						onFileSelect(f);
					}
				}, 10.5);
			btnAction.x = w - 66;
			btnAction.y = 4;
			row.addChild(btnAction);

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (e.target != btnAction && !btnAction.contains(e.target as DisplayObject)) {
						selectedFileName = f.name;
						highlightSelected();
						if (onFileSelect != null) {
							onFileSelect(f);
						}
					}
				});

			return row;
		}

		private function highlightSelected():void {
			var selLower:String = selectedFileName != null ? selectedFileName.toLowerCase() : "";
			for each (var item:Object in fileRowBgs) {
				if (item == null || item.shape == null) {
					continue;
				}
				var fn:String = String(item.name).toLowerCase();
				var isSel:Boolean = (selLower.length > 0 && (fn == selLower || fn == (selLower + ".json")));
				var bgCol:uint = isSel ? UIUtils.BG_HOVER : UIUtils.BG_DARK;
				var borderCol:uint = isSel ? UIUtils.BORDER_FOCUS : UIUtils.BORDER_SUBTLE;
				var strokeThick:Number = isSel ? 1.5 : 1.0;
				UIUtils.drawRoundedRect(item.shape.graphics, 0, 0, item.w, item.h, 4, bgCol, 0.95, borderCol, strokeThick);
			}
		}
	}
}
