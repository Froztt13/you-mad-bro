package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.text.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	import ui.CloseButton;
	import ui.MyTextField;
	import Utils;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class AccountManagerUI extends Sprite {

		private static const SO_KEY:String = "aqw_account_manager";
		private static const XOR_KEY:int = 0x5A;
		private static const PAGE_SIZE:int = 4;

		private static const BTN_W:Number = 136;
		private static const BTN_H:Number = 26;

		private static const MODAL_W:Number = 460;
		private static const MODAL_H:Number = 370;

		private var gameProvider:Function;
		private var gameRef:MovieClip;

		// UI Elements
		private var topBtn:Sprite;
		private var topBtnBg:Shape;
		private var topBtnLabel:TextField;

		private var modalContainer:Sprite;
		private var modalBackdrop:Shape;
		private var modalPanel:Sprite;
		private var modalBg:Shape;

		private var accountsContainer:Sprite;
		private var emptyLabel:TextField;
		private var countLabel:TextField;
		private var paginationBar:Sprite;
		private var pageText:TextField;
		private var prevBtn:Sprite;
		private var nextBtn:Sprite;

		private var usernameInput:MyTextField;
		private var passwordInput:MyTextField;
		private var passToggleBtn:Sprite;
		private var passToggleLabel:TextField;
		private var passVisible:Boolean = false;

		private var saveBtn:Sprite;
		private var grabBtn:Sprite;
		private var statusLabel:TextField;
		private var statusTimer:Timer;

		// Data
		private var accounts:Array = [];
		private var currentPage:int = 0;
		private var revealedPassMap:Object = {};

		public function AccountManagerUI(gameProvider:Function = null) {
			this.gameProvider = gameProvider;

			loadAccounts();
			buildTopButton();
			buildModal();

			this.visible = false; // Hidden until game client loads/attaches

			if (stage != null) {
				onAddedToStage();
			}
			else {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
		}

		public function setGame(game:MovieClip):void {
			this.gameRef = game;
		}

		private function get game():MovieClip {
			if (gameRef != null) {
				return gameRef;
			}
			if (gameProvider != null) {
				try {
					return gameProvider() as MovieClip;
				}
				catch (e:Error) {
				}
			}
			return null;
		}

		private function onAddedToStage(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(Event.RESIZE, onStageResize);
			updatePositions();
		}

		private function onStageResize(e:Event = null):void {
			updatePositions();
		}

		private function updatePositions():void {
			var sw:Number = stage != null ? stage.stageWidth : 960;
			var sh:Number = stage != null ? stage.stageHeight : 550;

			// Top center button
			topBtn.x = int((sw - BTN_W) / 2);
			topBtn.y = 10;

			// Modal backdrop & panel
			if (modalBackdrop != null) {
				modalBackdrop.graphics.clear();
				modalBackdrop.graphics.beginFill(0x000000, 0.6);
				modalBackdrop.graphics.drawRect(-500, -500, sw + 1000, sh + 1000);
				modalBackdrop.graphics.endFill();
			}

			if (modalPanel != null) {
				modalPanel.x = int((sw - MODAL_W) / 2);
				modalPanel.y = int((sh - MODAL_H) / 2);
			}
		}

		public function updateStatus(isLoggedIn:Boolean):void {
			this.visible = !isLoggedIn;
			if (isLoggedIn && modalContainer.visible) {
				closeModal();
			}
		}

		// ==========================================
		// Top Button
		// ==========================================
		private function buildTopButton():void {
			topBtn = new Sprite();
			topBtn.buttonMode = true;
			topBtn.useHandCursor = true;

			topBtnBg = new Shape();
			drawRoundedRect(topBtnBg.graphics, 0, 0, BTN_W, BTN_H, 6, 0x0f172a, 0.95, 0x334155, 1);
			topBtn.addChild(topBtnBg);

			topBtnLabel = createLabel("Account Manager", 0xe2e8f0, 10.5, true, TextFormatAlign.CENTER);
			topBtnLabel.width = BTN_W;
			topBtnLabel.height = BTN_H;
			topBtnLabel.y = 5;
			topBtn.addChild(topBtnLabel);

			topBtn.filters = [new DropShadowFilter(3, 90, 0x000000, 0.5, 6, 6)];

			topBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(topBtnBg.graphics, 0, 0, BTN_W, BTN_H, 6, 0x1e293b, 1.0, 0x475569, 1);
					topBtnLabel.textColor = 0xffffff;
				});

			topBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(topBtnBg.graphics, 0, 0, BTN_W, BTN_H, 6, 0x0f172a, 0.95, 0x334155, 1);
					topBtnLabel.textColor = 0xe2e8f0;
				});

			topBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					toggleModal();
				});

			addChild(topBtn);
		}

		// ==========================================
		// Modal Panel
		// ==========================================
		private function buildModal():void {
			modalContainer = new Sprite();
			modalContainer.visible = false;
			addChild(modalContainer);

			// Backdrop
			modalBackdrop = new Shape();
			modalContainer.addChild(modalBackdrop);
			modalBackdrop.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					closeModal();
				});

			// Panel
			modalPanel = new Sprite();
			modalContainer.addChild(modalPanel);

			modalBg = new Shape();
			drawRoundedRect(modalBg.graphics, 0, 0, MODAL_W, MODAL_H, 8, 0x0f172a, 0.98, 0x334155, 1);
			modalPanel.addChild(modalBg);
			modalPanel.filters = [new DropShadowFilter(12, 90, 0x000000, 0.7, 20, 20)];

			// Header Bar (Draggable)
			const headerBar:Sprite = new Sprite();
			headerBar.graphics.beginFill(0x0a0e1a, 0.98);
			headerBar.graphics.drawRoundRectComplex(0, 0, MODAL_W, 36, 8, 8, 0, 0);
			headerBar.graphics.endFill();
			headerBar.graphics.lineStyle(1, 0x1e293b, 1);
			headerBar.graphics.moveTo(0, 36);
			headerBar.graphics.lineTo(MODAL_W, 36);
			modalPanel.addChild(headerBar);

			headerBar.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					modalPanel.startDrag();
					stage.addEventListener(MouseEvent.MOUSE_UP, onModalDragStop);
				});

			const titleTf:TextField = createLabel("Account Manager", 0xf8fafc, 12, true);
			titleTf.x = 16;
			titleTf.y = 9;
			titleTf.width = 130;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Quick Switcher", 0x64748b, 10, false);
			subTf.x = 142;
			subTf.y = 11;
			subTf.width = 160;
			headerBar.addChild(subTf);

			// Close Button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = MODAL_W - 16 - 22;
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					closeModal();
				});
			modalPanel.addChild(closeBtn);

			if (Config.isAndroid) {
				const safImportBtn:Sprite = createSmallButton("📂 Import", 62, 20, 0x0369a1, 0x0284c7, 0xffffff, 0x38bdf8, 0x075985, 0x0369a1);
				safImportBtn.x = closeBtn.x - 68;
				safImportBtn.y = 8;
				safImportBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						onSafImportAccountsClick();
					});
				modalPanel.addChild(safImportBtn);
			}

			// Section: List Header
			const listHeader:TextField = createLabel("SAVED ACCOUNTS", 0x64748b, 9.5, true);
			listHeader.x = 16;
			listHeader.y = 46;
			listHeader.width = 160;
			modalPanel.addChild(listHeader);

			countLabel = createLabel("0 Accounts", 0x64748b, 9.5, false, TextFormatAlign.RIGHT);
			countLabel.x = MODAL_W - 16 - 120;
			countLabel.y = 46;
			countLabel.width = 120;
			modalPanel.addChild(countLabel);

			// List Background Box
			const listBox:Shape = new Shape();
			drawRoundedRect(listBox.graphics, 16, 64, MODAL_W - 32, 156, 6, 0x070b14, 0.95, 0x1e293b, 1);
			modalPanel.addChild(listBox);

			accountsContainer = new Sprite();
			accountsContainer.x = 22;
			accountsContainer.y = 70;
			modalPanel.addChild(accountsContainer);

			emptyLabel = createLabel("No saved accounts found.\nEnter credentials below or place accounts.json in:\nDocuments/YouMadBro/Accounts/accounts.json", 0x64748b, 10.5, false, TextFormatAlign.CENTER);
			emptyLabel.x = 20;
			emptyLabel.y = 116;
			emptyLabel.width = MODAL_W - 40;
			emptyLabel.height = 50;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;
			modalPanel.addChild(emptyLabel);

			// Pagination Bar
			buildPaginationBar();

			// Section Divider
			const divider:Shape = new Shape();
			divider.graphics.lineStyle(1, 0x1e293b, 1);
			divider.graphics.moveTo(16, 250);
			divider.graphics.lineTo(MODAL_W - 16, 250);
			modalPanel.addChild(divider);

			// Section: Add Account Form
			buildAddForm();
		}

		private function onModalDragStop(e:MouseEvent):void {
			modalPanel.stopDrag();
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, onModalDragStop);
			}
		}

		private function buildPaginationBar():void {
			paginationBar = new Sprite();
			paginationBar.x = 16;
			paginationBar.y = 226;
			modalPanel.addChild(paginationBar);

			const barW:Number = MODAL_W - 32;

			prevBtn = createSmallButton("Prev", 46, 18, 0x1e293b, 0x334155, 0x94a3b8, 0xffffff, 0x334155, 0x475569);
			prevBtn.x = 0;
			prevBtn.y = 0;
			prevBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (currentPage > 0) {
						currentPage--;
						renderAccountsList();
					}
				});
			paginationBar.addChild(prevBtn);

			pageText = createLabel("Page 1 of 1", 0x64748b, 9.5, false, TextFormatAlign.CENTER);
			pageText.x = 52;
			pageText.y = 1;
			pageText.width = barW - 104;
			paginationBar.addChild(pageText);

			nextBtn = createSmallButton("Next", 46, 18, 0x1e293b, 0x334155, 0x94a3b8, 0xffffff, 0x334155, 0x475569);
			nextBtn.x = barW - 46;
			nextBtn.y = 0;
			nextBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					var maxPage:int = Math.max(0, Math.ceil(accounts.length / PAGE_SIZE) - 1);
					if (currentPage < maxPage) {
						currentPage++;
						renderAccountsList();
					}
				});
			paginationBar.addChild(nextBtn);
		}

		private function buildAddForm():void {
			const formTitle:TextField = createLabel("ADD ACCOUNT", 0x64748b, 9.5, true);
			formTitle.x = 16;
			formTitle.y = 256;
			formTitle.width = 150;
			modalPanel.addChild(formTitle);

			// Username Label & Input
			const uLbl:TextField = createLabel("Username:", 0x94a3b8, 10, false);
			uLbl.x = 16;
			uLbl.y = 276;
			uLbl.width = 62;
			modalPanel.addChild(uLbl);

			usernameInput = new MyTextField(120, 22, 11.5);
			usernameInput.x = 78;
			usernameInput.y = 273;
			usernameInput.maxChars = 32;
			usernameInput.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
					if (e.keyCode == 13)
						onSaveAccountClick();
				});
			modalPanel.addChild(usernameInput);

			// Password Label & Input
			const pLbl:TextField = createLabel("Password:", 0x94a3b8, 10, false);
			pLbl.x = 208;
			pLbl.y = 276;
			pLbl.width = 58;
			modalPanel.addChild(pLbl);

			passwordInput = new MyTextField(112, 22, 11.5);
			passwordInput.x = 266;
			passwordInput.y = 273;
			passwordInput.displayAsPassword = true;
			passwordInput.maxChars = 64;
			passwordInput.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
					if (e.keyCode == 13)
						onSaveAccountClick();
				});
			modalPanel.addChild(passwordInput);

			// Toggle Password Visibility Button (Show / Hide text)
			passToggleBtn = createSmallButton("Show", 44, 22, 0x1e293b, 0x334155, 0x94a3b8, 0xffffff, 0x334155, 0x475569);
			passToggleBtn.x = 384;
			passToggleBtn.y = 273;
			passToggleBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					passVisible = !passVisible;
					passwordInput.displayAsPassword = !passVisible;
					updateButtonLabel(passToggleBtn, passVisible ? "Hide" : "Show");
				});
			modalPanel.addChild(passToggleBtn);

			// Action Buttons
			saveBtn = createButton("Save Account", 96, 24, 0x15803d, 0x16a34a, 0xffffff, 0x166534, 0x15803d);
			saveBtn.x = 16;
			saveBtn.y = 306;
			saveBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					onSaveAccountClick();
				});
			modalPanel.addChild(saveBtn);

			grabBtn = createButton("Import from Form", 118, 24, 0x1e293b, 0x334155, 0xcbd5e1, 0x334155, 0x475569);
			grabBtn.x = 118;
			grabBtn.y = 306;
			grabBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					onGrabFromGameClick();
				});
			modalPanel.addChild(grabBtn);

			// Status Label
			statusLabel = createLabel("", 0x4ade80, 9.5, false, TextFormatAlign.RIGHT);
			statusLabel.x = 242;
			statusLabel.y = 309;
			statusLabel.width = MODAL_W - 16 - 242;
			modalPanel.addChild(statusLabel);
		}

		private function toggleModal():void {
			if (modalContainer.visible) {
				closeModal();
			}
			else {
				openModal();
			}
		}

		private function openModal():void {
			modalContainer.visible = true;
			updatePositions();
			loadAccounts(true);
			renderAccountsList();
		}

		private function closeModal():void {
			modalContainer.visible = false;
		}

		private function onSafImportAccountsClick():void {
			BatteryOptimizer.openFilePicker(function(success:Boolean, fileName:String, content:String):void {
					if (!success || content == null || content.length == 0)
						return;
					try {
						var parsed:Object = JSON.parse(content);
						var arr:Array = null;
						if (parsed is Array) {
							arr = parsed as Array;
						}
						else if (parsed && parsed.accounts && parsed.accounts is Array) {
							arr = parsed.accounts as Array;
						}
						if (arr != null && arr.length > 0) {
							var importedCount:int = 0;
							for each (var a:Object in arr) {
								if (a != null && a.username) {
									var existingIdx:int = -1;
									for (var i:int = 0; i < accounts.length; i++) {
										if (accounts[i] && String(accounts[i].username).toLowerCase() == String(a.username).toLowerCase()) {
											existingIdx = i;
											break;
										}
									}
									if (existingIdx >= 0) {
										accounts[existingIdx] = {username: a.username, password: a.password || ""};
									}
									else {
										accounts.push({username: a.username, password: a.password || ""});
									}
									importedCount++;
								}
							}
							saveAccounts();
							renderAccountsList();
							showStatus("Imported " + importedCount + " accounts!", 0x4ade80);
						}
						else {
							showStatus("Invalid accounts JSON", 0xf87171);
						}
					}
					catch (err:Error) {
						showStatus("Error: " + err.message, 0xf87171);
					}
				});
		}

		// ==========================================
		// Account List Rendering
		// ==========================================
		private function renderAccountsList():void {
			while (accountsContainer.numChildren > 0) {
				accountsContainer.removeChildAt(0);
			}

			countLabel.text = accounts.length + (accounts.length == 1 ? " Account" : " Accounts");

			if (accounts.length == 0) {
				emptyLabel.visible = true;
				paginationBar.visible = false;
				return;
			}

			emptyLabel.visible = false;

			var totalPages:int = Math.max(1, Math.ceil(accounts.length / PAGE_SIZE));
			if (currentPage >= totalPages) {
				currentPage = totalPages - 1;
			}
			if (currentPage < 0) {
				currentPage = 0;
			}

			paginationBar.visible = totalPages > 1;
			pageText.text = "Page " + (currentPage + 1) + " of " + totalPages;
			prevBtn.alpha = (currentPage > 0) ? 1.0 : 0.35;
			nextBtn.alpha = (currentPage < totalPages - 1) ? 1.0 : 0.35;

			var startIndex:int = currentPage * PAGE_SIZE;
			var endIndex:int = Math.min(accounts.length, startIndex + PAGE_SIZE);

			var rowY:Number = 0;
			for (var i:int = startIndex; i < endIndex; i++) {
				const acc:Object = accounts[i];
				const accIdx:int = i;
				const row:Sprite = buildAccountRow(acc, accIdx);
				row.y = rowY;
				accountsContainer.addChild(row);
				rowY += 36;
			}
		}

		private function buildAccountRow(acc:Object, index:int):Sprite {
			const row:Sprite = new Sprite();
			const rowW:Number = MODAL_W - 44; // 416
			const rowH:Number = 32;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, rowW, rowH, 4, 0x0f172a, 0.95, 0x1e293b, 1);
			row.addChild(bg);

			// Username
			const uTf:TextField = createLabel(acc.username, 0xf8fafc, 10.5, true);
			uTf.x = 10;
			uTf.y = 8;
			uTf.width = 125;
			row.addChild(uTf);

			// Password Mask / Reveal
			var isRevealed:Boolean = (revealedPassMap[acc.username] == true);
			var passDisplay:String = isRevealed ? decodeStr(acc.password) : "••••••••";

			const pTf:TextField = createLabel(passDisplay, 0x94a3b8, 10, false);
			pTf.x = 140;
			pTf.y = 8;
			pTf.width = 82;
			row.addChild(pTf);

			// Show / Hide Password Button
			const showBtn:Sprite = createSmallButton(isRevealed ? "Hide" : "Show", 42, 20, 0x1e293b, 0x334155, 0x94a3b8, 0xffffff, 0x334155, 0x475569);
			showBtn.x = 226;
			showBtn.y = 6;
			showBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					revealedPassMap[acc.username] = !revealedPassMap[acc.username];
					renderAccountsList();
				});
			row.addChild(showBtn);

			// Login Button
			const loginBtn:Sprite = createSmallButton("Login", 50, 22, 0x059669, 0x10b981, 0xffffff, 0xffffff, 0x047857, 0x059669);
			loginBtn.x = 274;
			loginBtn.y = 5;
			loginBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					onSelectAccount(acc, true);
				});
			row.addChild(loginBtn);

			// Select / Fill Button
			const fillBtn:Sprite = createSmallButton("Select", 48, 22, 0x2563eb, 0x3b82f6, 0xffffff, 0xffffff, 0x1d4ed8, 0x2563eb);
			fillBtn.x = 330;
			fillBtn.y = 5;
			fillBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					onSelectAccount(acc, false);
				});
			row.addChild(fillBtn);

			// Delete Button
			const delBtn:Sprite = createSmallButton("×", 24, 22, 0x3f1d1d, 0x991b1b, 0xf87171, 0xffffff, 0x7f1d1d, 0xef4444);
			delBtn.x = 384;
			delBtn.y = 5;
			delBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					deleteAccount(index);
				});
			row.addChild(delBtn);

			return row;
		}

		// ==========================================
		// Account Actions
		// ==========================================
		private function onSelectAccount(acc:Object, autoLogin:Boolean):void {
			var u:String = acc.username;
			var p:String = decodeStr(acc.password);

			var success:Boolean = fillLoginForm(u, p);

			if (autoLogin) {
				executeLogin(u, p);
				showStatus("Logging in as " + u + "...", 0x38bdf8);
			}
			else {
				showStatus("Credentials filled for " + u, 0x4ade80);
			}

			closeModal();
		}

		private function deleteAccount(index:int):void {
			if (index >= 0 && index < accounts.length) {
				var removedUser:String = accounts[index].username;
				accounts.splice(index, 1);
				saveAccounts();
				renderAccountsList();
				showStatus("Account " + removedUser + " deleted.", 0xf87171);
			}
		}

		private function onSaveAccountClick():void {
			var u:String = Utils.trim(usernameInput.text);
			var p:String = passwordInput.text;

			if (u.length == 0 || p.length == 0) {
				showStatus("Username and password are required.", 0xf87171);
				return;
			}

			// Check if already exists
			var foundIdx:int = -1;
			for (var i:int = 0; i < accounts.length; i++) {
				if (accounts[i].username.toLowerCase() == u.toLowerCase()) {
					foundIdx = i;
					break;
				}
			}

			if (foundIdx > -1) {
				// Update existing
				accounts[foundIdx].password = encodeStr(p);
				accounts[foundIdx].updatedAt = new Date().getTime();
				showStatus("Password for '" + u + "' updated.", 0x4ade80);
			}
			else {
				// Add new
				accounts.push({
							username: u,
							password: encodeStr(p),
							createdAt: new Date().getTime()
						});
				showStatus("Account '" + u + "' saved.", 0x4ade80);
			}

			saveAccounts();
			usernameInput.text = "";
			passwordInput.text = "";
			renderAccountsList();
		}

		private function onGrabFromGameClick():void {
			var g:MovieClip = game;
			if (g != null && "mcLogin" in g && g.mcLogin != null) {
				var u:String = "";
				var p:String = "";
				try {
					if ("ni" in g.mcLogin && g.mcLogin.ni != null && g.mcLogin.ni.text != null) {
						u = Utils.trim(g.mcLogin.ni.text);
					}
					if ("pi" in g.mcLogin && g.mcLogin.pi != null && g.mcLogin.pi.text != null) {
						p = g.mcLogin.pi.text;
					}
				}
				catch (err:Error) {
				}

				if (u.length > 0 || p.length > 0) {
					usernameInput.text = u;
					passwordInput.text = p;
					showStatus("Imported credentials from login form.", 0x4ade80);
					return;
				}
			}
			showStatus("Game login form is empty.", 0xfbbf24);
		}

		private function fillLoginForm(username:String, pass:String):Boolean {
			var g:MovieClip = game;
			var filled:Boolean = false;
			if (g != null && "mcLogin" in g && g.mcLogin != null) {
				try {
					if ("ni" in g.mcLogin && g.mcLogin.ni != null) {
						g.mcLogin.ni.text = username;
						filled = true;
					}
					if ("pi" in g.mcLogin && g.mcLogin.pi != null) {
						g.mcLogin.pi.text = pass;
						filled = true;
					}
				}
				catch (err:Error) {
					trace("Error filling login form: " + err.message);
				}
			}
			return filled;
		}

		private function executeLogin(username:String, pass:String):void {
			fillLoginForm(username, pass);
			var g:MovieClip = game;
			if (g != null) {
				try {
					if ("login" in g && g.login is Function) {
						g.login(username.toLowerCase(), pass);
					}
				}
				catch (err:Error) {
					trace("Error calling game.login: " + err.message);
				}
			}
		}

		// ==========================================
		// Storage & Obfuscation
		// ==========================================
		public static function getAccountsFile():File {
			// 1. Android public /storage/emulated/0/Documents/YouMadBro/Accounts/accounts.json
			try {
				var aDoc:File = new File("/storage/emulated/0/Documents/YouMadBro/Accounts/accounts.json");
				if (BotLoadModal.isWritable(aDoc.parent))
					return aDoc;
			}
			catch (e1:Error) {
			}

			// 2. Android public /sdcard/Documents/YouMadBro/Accounts/accounts.json
			try {
				var aSd:File = new File("/sdcard/Documents/YouMadBro/Accounts/accounts.json");
				if (BotLoadModal.isWritable(aSd.parent))
					return aSd;
			}
			catch (e2:Error) {
			}

			// 3. User Documents (PC / Mac)
			try {
				if (File.userDirectory != null && File.userDirectory.exists) {
					var uDir:File = File.userDirectory.resolvePath("Documents/YouMadBro/Accounts");
					if (BotLoadModal.isWritable(uDir))
						return uDir.resolvePath("accounts.json");
				}
			}
			catch (e3:Error) {
			}

			// 4. Standard documentsDirectory
			try {
				var dDir:File = File.documentsDirectory.resolvePath("YouMadBro/Accounts");
				if (BotLoadModal.isWritable(dDir))
					return dDir.resolvePath("accounts.json");
			}
			catch (e4:Error) {
			}

			return File.applicationStorageDirectory.resolvePath("YouMadBro/Accounts/accounts.json");
		}

		private function loadAccounts(fromUserAction:Boolean = false):Boolean {
			var loadedFromFile:Boolean = false;
			var candidateFiles:Array = [];
			try {
				candidateFiles.push(getAccountsFile());
			}
			catch (ec0:Error) {
			}
			try {
				candidateFiles.push(new File("/storage/emulated/0/Documents/YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy1:Error) {
			}
			try {
				candidateFiles.push(new File("/storage/emulated/0/YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy2:Error) {
			}
			try {
				candidateFiles.push(new File("/sdcard/Documents/YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy3:Error) {
			}
			try {
				candidateFiles.push(new File("/sdcard/YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy4:Error) {
			}
			try {
				if (File.userDirectory != null)
					candidateFiles.push(File.userDirectory.resolvePath("Documents/YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy5:Error) {
			}
			try {
				if (File.documentsDirectory != null)
					candidateFiles.push(File.documentsDirectory.resolvePath("YouMadBro/Accounts/accounts.json"));
			}
			catch (ecy6:Error) {
			}

			for each (var file:File in candidateFiles) {
				if (loadedFromFile)
					break;
				try {
					if (file != null && file.exists) {
						var stream:FileStream = new FileStream();
						stream.open(file, FileMode.READ);
						var content:String = stream.readUTFBytes(stream.bytesAvailable);
						stream.close();

						if (content != null && content.length > 0) {
							var parsed:* = Utils.parseJSON(content);
							var rawList:Array = null;
							if (parsed is Array) {
								rawList = parsed as Array;
							}
							else if (parsed != null && "accounts" in parsed && parsed.accounts is Array) {
								rawList = parsed.accounts as Array;
							}

							if (rawList != null) {
								var newAccounts:Array = [];
								for each (var item:Object in rawList) {
									if (item != null && item.username != null && String(item.username).length > 0) {
										var u:String = Utils.trim(String(item.username));
										var p:String = item.password != null ? String(item.password) : "";
										newAccounts.push({
													username: u,
													password: encodeStr(p),
													createdAt: item.createdAt || new Date().getTime()
												});
									}
								}
								accounts = newAccounts;
								loadedFromFile = true;

								// Backup to SharedObject
								try {
									var so:SharedObject = SharedObject.getLocal(SO_KEY);
									if (so != null && so.data != null) {
										so.data.accounts = accounts;
										so.flush();
									}
								}
								catch (eSo2:Error) {
								}
							}
						}
					}
				}
				catch (eFile:Error) {
					trace("Error reading accounts.json: " + eFile.message);
				}
			}

			// If file didn't exist and not from explicit button click, check SharedObject (migration)
			if (!loadedFromFile && !fromUserAction) {
				try {
					var so2:SharedObject = SharedObject.getLocal(SO_KEY);
					if (so2 != null && so2.data != null && so2.data.accounts is Array) {
						accounts = so2.data.accounts as Array;
						// Auto-save to accounts.json so it's created immediately
						if (accounts.length > 0) {
							saveAccounts();
						}
					}
					else {
						accounts = [];
					}
				}
				catch (eSo:Error) {
					accounts = [];
				}
			}

			return loadedFromFile;
		}

		private function saveAccounts():void {
			// 1. Save to SharedObject (backup)
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null) {
					so.data.accounts = accounts;
					so.flush();
				}
			}
			catch (eSo:Error) {
				trace("Failed to save to SharedObject: " + eSo.message);
			}

			// 2. Save automatically to Documents/Accounts/accounts.json
			try {
				var file:File = getAccountsFile();
				if (file != null) {
					var exportList:Array = [];
					for each (var acc:Object in accounts) {
						if (acc != null && acc.username != null) {
							exportList.push({
										"username": String(acc.username),
										"password": decodeStr(acc.password)
									});
						}
					}
					var jsonStr:String = JSON.stringify(exportList, null, 2);
					var stream:FileStream = new FileStream();
					try {
						stream.open(file, FileMode.WRITE);
						stream.writeUTFBytes(jsonStr);
						stream.close();
					}
					catch (eW:Error) {
						var fallbackFile:File = File.applicationStorageDirectory.resolvePath("YouMadBro/Accounts/accounts.json");
						if (!fallbackFile.parent.exists)
							fallbackFile.parent.createDirectory();
						var streamFb:FileStream = new FileStream();
						streamFb.open(fallbackFile, FileMode.WRITE);
						streamFb.writeUTFBytes(jsonStr);
						streamFb.close();
					}
				}
			}
			catch (eFile:Error) {
				trace("Failed to save accounts.json: " + eFile.message);
			}
		}

		private static function encodeStr(str:String):String {
			if (str == null)
				return "";
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(str);
			var out:String = "";
			for (var i:int = 0; i < bytes.length; i++) {
				var b:int = bytes[i] ^ XOR_KEY;
				var hex:String = b.toString(16);
				if (hex.length < 2)
					hex = "0" + hex;
				out += hex;
			}
			return out;
		}

		private static function decodeStr(hex:String):String {
			if (hex == null || hex.length == 0)
				return "";
			if (hex.length % 2 != 0)
				return hex;
			try {
				var bytes:ByteArray = new ByteArray();
				for (var i:int = 0; i < hex.length; i += 2) {
					var b:int = parseInt(hex.substr(i, 2), 16) ^ XOR_KEY;
					bytes.writeByte(b);
				}
				bytes.position = 0;
				return bytes.readUTFBytes(bytes.length);
			}
			catch (e:Error) {
				return hex;
			}
			return hex;
		}

		// ==========================================
		// UI Component Helpers
		// ==========================================
		private function showStatus(msg:String, color:uint):void {
			if (statusLabel != null) {
				statusLabel.text = msg;
				statusLabel.textColor = color;

				if (statusTimer != null) {
					statusTimer.stop();
				}
				statusTimer = new Timer(3500, 1);
				statusTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
						if (statusLabel != null) {
							statusLabel.text = "";
						}
					});
				statusTimer.start();
			}
		}

		private static function createLabel(text:String, color:uint, size:Number, bold:Boolean, align:String = TextFormatAlign.LEFT):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, align);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}

		private static function createButton(label:String, w:Number, h:Number, bgNormal:uint, bgHover:uint, textColor:uint = 0xffffff, borderColor:uint = 0, borderHover:uint = 0):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			var strokeN:uint = borderColor > 0 ? borderColor : bgNormal;
			var strokeH:uint = borderHover > 0 ? borderHover : bgHover;
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgNormal, 1.0, strokeN, 1);
			btn.addChild(bg);

			const tf:TextField = createLabel(label, textColor, 10, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 15) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgHover, 1.0, strokeH, 1);
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgNormal, 1.0, strokeN, 1);
				});

			return btn;
		}

		private static function createSmallButton(label:String, w:Number, h:Number, bgNormal:uint, bgHover:uint, textColor:uint = 0x94a3b8, textHover:uint = 0xffffff, borderColor:uint = 0x334155, borderHover:uint = 0x475569):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgNormal, 1.0, borderColor, 1);
			btn.addChild(bg);

			const tf:TextField = createLabel(label, textColor, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 14) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgHover, 1.0, borderHover, 1);
					tf.textColor = textHover;
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgNormal, 1.0, borderColor, 1);
					tf.textColor = textColor;
				});

			return btn;
		}

		private static function updateButtonLabel(btn:Sprite, newLabel:String):void {
			for (var i:int = 0; i < btn.numChildren; i++) {
				var child:DisplayObject = btn.getChildAt(i);
				if (child is TextField) {
					var tf:TextField = child as TextField;
					tf.text = newLabel;
					break;
				}
			}
		}

		private static function drawRoundedRect(g:Graphics, x:Number, y:Number, w:Number, h:Number, r:Number, fillColor:uint, fillAlpha:Number, strokeColor:uint = 0, strokeThickness:Number = 0):void {
			g.clear();
			g.beginFill(fillColor, fillAlpha);
			if (strokeThickness > 0) {
				g.lineStyle(strokeThickness, strokeColor, 1.0);
			}
			g.drawRoundRect(x, y, w, h, r);
			g.endFill();
		}
	}
}
