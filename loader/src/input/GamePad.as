package input {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.system.System;
	import flash.ui.Keyboard;

	import ui.Layout;
	import ui.Joystick;
	import ui.InfoMessage;
	import ui.MyButton;
	import engine.AutoBattle;
	import engine.AutoQuest;
	import engine.MapCommands;
	import input.BotManagerUI;
	import input.CellJumpUI;
	import input.CustomCharUI;
	import input.PacketLoggerUI;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class GamePad extends Sprite {

		private static const MENU_W:Number = 110;
		private static const MENU_ITH:Number = 26;
		private static const GEAR_SIZE:Number = 28;
		private static const EDIT_BAR_W:Number = 200;
		private static const EDIT_BAR_H:Number = 36;

		public function GamePad(game:MovieClip) {
			this.game = game;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private var game:MovieClip;
		private var padContainer:Sprite;
		private var padVisible:Boolean = false;
		private var joystick:Joystick;

		private var walkCtrl:WalkController;
		private var layout:Layout;
		private var gearBtn:Sprite;
		private var bankBtn:Sprite;
		private var actionMenuBtn:Sprite;
		private var autoBattleBtn:Sprite;
		private var autoBattleLabel:TextField;
		private var dropdown:Sprite;
		private var actionDropdown:Sprite;
		private var dropdownOpen:Boolean = false;
		private var actionDropdownOpen:Boolean = false;

		private var showPadTf:TextField;
		private var editLayoutTf:TextField;
		private var editLayoutBar:Sprite;

		private var fullscreenTf:TextField;

		private var autoBattle:AutoBattle;
		private var autoQuest:AutoQuest;
		private var mapCommands:MapCommands;
		private var questUI:QuestTreeUI;
		private var autoQuestUI:AutoQuestUI;
		private var cellJumpUI:CellJumpUI;
		private var loggerUI:PacketLoggerUI;
		private var botManagerUI:BotManagerUI;
		private var customCharUI:CustomCharUI;

		private function buildGearMenu():void {
			gearBtn = new Sprite();

			drawPill(gearBtn.graphics, GEAR_SIZE, GEAR_SIZE);

			const gl:TextField = makeLabel("⚙", 0xffffff, 14, true);

			gl.width = GEAR_SIZE;
			gl.height = GEAR_SIZE;
			gl.y = 4.5;
			gl.alpha = 0.7;

			gearBtn.addChild(gl);
			gearBtn.x = 5;
			gearBtn.y = 5;
			gearBtn.buttonMode = true;
			gearBtn.useHandCursor = true;
			gearBtn.addEventListener(MouseEvent.CLICK, onGearClick);

			addChild(gearBtn);

			dropdown = new Sprite();
			dropdown.visible = false;

			dropdown.x = gearBtn.x + GEAR_SIZE + 2;
			dropdown.y = gearBtn.y;
			addChild(dropdown);

			rebuildGearDropdown();
		}

		private function rebuildGearDropdown():void {
			while (dropdown.numChildren > 0) {
				dropdown.removeChildAt(0);
			}

			const items:Array = [];

			if (!Config.isAndroid) {
				items.push({
							label: "Fullscreen",
							fn: doToggleFullscreen
						});
			}

			if (Config.isAndroid) {
				items.push({
							label: padVisible ? "Hide Game Pad" : "Show Game Pad",
							fn: doHideUI
						});

				if (padVisible) {
					items.push({
								label: layout.editMode ? "Save Layout" : "Edit Layout",
								fn: doEditLayout
							});
				}

				items.push({
							label: "Battery Unrestricted",
							fn: Main.requestBatteryOptimization
						});
				items.push({
							label: "Picture-in-Picture",
							fn: doEnterPip
						});
			}

			items.push({
						label: "App Log",
						fn: openAppLog
					});
			items.push({
						label: "Packet Logger",
						fn: openLogger
					});

			const panelH:Number = items.length * MENU_ITH + 6;

			drawPill(dropdown.graphics, MENU_W, panelH, true);

			for (var i:int = 0; i < items.length; i++) {
				const row:Sprite = buildMenuItem(items[i].label, items[i].fn, i);
				dropdown.addChild(row);
			}
		}

		private function doToggleFullscreen():void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			else {
				stage.displayState = StageDisplayState.NORMAL;
			}

			if (fullscreenTf != null) {
				fullscreenTf.text = (stage.displayState == StageDisplayState.NORMAL) ? "Fullscreen" : "Exit Fullscreen";
			}
		}

		private function buildActionButton():void {
			actionMenuBtn = new Sprite();

			drawPill(actionMenuBtn.graphics, GEAR_SIZE, GEAR_SIZE);

			const al:TextField = makeLabel("⚡", 0xffffff, 14, true);

			al.width = GEAR_SIZE;
			al.height = GEAR_SIZE;
			al.y = 4.5;
			al.alpha = 0.7;

			actionMenuBtn.addChild(al);
			actionMenuBtn.x = 5;
			actionMenuBtn.y = gearBtn.y + GEAR_SIZE + 2;
			actionMenuBtn.buttonMode = true;
			actionMenuBtn.useHandCursor = true;
			actionMenuBtn.addEventListener(MouseEvent.CLICK, onActionClick);

			addChild(actionMenuBtn);

			// Initialize Auto Quest UI
			if (autoQuestUI == null) {
				autoQuestUI = new AutoQuestUI(autoQuest);
				addChild(autoQuestUI);
				autoQuestUI.visible = false;
			}

			// Initialize Quest Tree UI
			if (questUI == null) {
				questUI = new QuestTreeUI(game, autoQuest);
				addChild(questUI);
				questUI.visible = false;
			}

			// Initialize Cell Jump UI
			if (cellJumpUI == null) {
				cellJumpUI = new CellJumpUI(mapCommands);
				addChild(cellJumpUI);
				cellJumpUI.visible = false;
			}

			// Initialize Logger UI
			if (loggerUI == null) {
				loggerUI = new PacketLoggerUI();
				addChild(loggerUI);
				loggerUI.visible = false;
			}

			// Initialize Bot Manager UI
			if (botManagerUI == null) {
				botManagerUI = new BotManagerUI(game);
				addChild(botManagerUI);
				botManagerUI.visible = false;
				botManagerUI.addEventListener(Event.CLOSE, function(e:Event):void {
						if (autoQuestUI != null) {
							autoQuestUI.visible = false;
						}
					});
			}

			// Initialize Custom Char UI
			if (customCharUI == null) {
				customCharUI = new CustomCharUI(game);
				addChild(customCharUI);
				customCharUI.visible = false;
			}

			actionDropdown = new Sprite();
			actionDropdown.visible = false;

			const items:Array = [
					{
						label: "Bot Manager",
						fn: openBotManager
					},
					{
						label: "Quest Loader",
						fn: openQuestTree
					},
					{
						label: "Custom Char",
						fn: openCustomChar
					},
					{
						label: "Cell Jump",
						fn: openCellJump
					},
					// {
					// label: "Walk Speed",
					// fn: doWalkSpeed
					// },
					{
						label: "Lag Killer",
						fn: doLagKiller
					},
					{
						label: "Set Spawnpoint",
						fn: setSpawnPoint
					},
					{
						label: "Hide Players",
						fn: doHidePlayers
					}
				];

			const panelH:Number = items.length * MENU_ITH + 6;

			drawPill(actionDropdown.graphics, MENU_W, panelH, true);

			for (var i:int = 0; i < items.length; i++) {
				const row:Sprite = buildMenuItem(items[i].label, items[i].fn, i, closeActionDropdown);
				actionDropdown.addChild(row);
			}

			actionDropdown.x = actionMenuBtn.x + GEAR_SIZE + 2;
			actionDropdown.y = actionMenuBtn.y;
			addChild(actionDropdown);
		}

		private function buildBankButton():void {
			bankBtn = new Sprite();

			drawPill(bankBtn.graphics, GEAR_SIZE, GEAR_SIZE);

			const bl:TextField = makeLabel("🏛️", 0xffffff, 14, true);

			bl.width = GEAR_SIZE;
			bl.height = GEAR_SIZE;
			bl.y = 4.5;
			bl.alpha = 0.7;

			bankBtn.addChild(bl);
			bankBtn.x = 5;
			bankBtn.y = autoBattleBtn.y + GEAR_SIZE + 2;
			bankBtn.buttonMode = true;
			bankBtn.useHandCursor = true;
			bankBtn.addEventListener(MouseEvent.CLICK, onBankClick);

			addChild(bankBtn);
		}

		private function buildAutoBattleButton():void {
			autoBattleBtn = new Sprite();

			drawPill(autoBattleBtn.graphics, GEAR_SIZE, GEAR_SIZE);

			autoBattleLabel = makeLabel("🔥", 0xffffff, 14, true);

			autoBattleLabel.width = GEAR_SIZE;
			autoBattleLabel.height = GEAR_SIZE;
			autoBattleLabel.y = 4.5;
			autoBattleLabel.alpha = 0.7;

			autoBattleBtn.addChild(autoBattleLabel);
			autoBattleBtn.x = 5;
			autoBattleBtn.y = actionMenuBtn.y + GEAR_SIZE + 2;
			autoBattleBtn.buttonMode = true;
			autoBattleBtn.useHandCursor = true;
			autoBattleBtn.addEventListener(MouseEvent.CLICK, onAutoBattleClick);

			addChild(autoBattleBtn);
		}

		private function buildMenuItem(lbl:String, fn:Function, idx:int, closeFn:Function = null):Sprite {
			const row:Sprite = new Sprite();

			const hoverBg:Shape = new Shape();
			hoverBg.graphics.beginFill(0xffffff, 0.08);
			hoverBg.graphics.drawRoundRect(3, 0, MENU_W - 6, MENU_ITH, 4);
			hoverBg.graphics.endFill();
			hoverBg.visible = false;

			row.addChild(hoverBg);

			const tf:TextField = makeLabel(lbl, 0xffffff, 10, false);
			tf.width = MENU_W - 10;
			tf.height = MENU_ITH;
			tf.x = 5;
			tf.y = 6;
			tf.alpha = 0.7;

			const fmt:TextFormat = new TextFormat("_sans", 10, 0xffffff, false, null, null, null, null, TextFormatAlign.LEFT);
			tf.defaultTextFormat = fmt;
			tf.text = lbl;

			row.addChild(tf);

			if (lbl == "Fullscreen") {
				fullscreenTf = tf;
				if (stage != null && stage.displayState != StageDisplayState.NORMAL) {
					fullscreenTf.text = "Exit Fullscreen";
				}
			}
			else if (lbl == "Show Game Pad" || lbl == "Hide Game Pad") {
				showPadTf = tf;
			}
			else if (lbl == "Edit Layout" || lbl == "Save Layout") {
				editLayoutTf = tf;
			}

			row.y = 3 + idx * MENU_ITH;
			row.buttonMode = true;
			row.useHandCursor = true;

			row.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					hoverBg.visible = true;
				});

			row.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					hoverBg.visible = false;
				});

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (closeFn != null) {
						closeFn();
					}
					else {
						closeDropdown();
					}
					fn();
					e.stopImmediatePropagation();
				});

			return row;
		}

		private function drawPill(g:Graphics, w:Number, h:Number, panel:Boolean = false):void {
			g.clear();
			g.beginFill(0x111111, 0.75);
			g.drawRoundRect(0, 0, w, h, panel ? 6 : 8);
			g.endFill();
			g.lineStyle(1, 0x888888, 0.4);
			g.drawRoundRect(0, 0, w, h, panel ? 6 : 8);
		}

		private function openDropdown():void {
			rebuildGearDropdown();
			dropdownOpen = true;
			dropdown.visible = true;

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose, false, 0, true);
		}

		private function closeDropdown():void {
			dropdownOpen = false;
			dropdown.visible = false;

			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose);
		}

		private function openActionDropdown():void {
			actionDropdownOpen = true;
			actionDropdown.visible = true;

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose, false, 0, true);
		}

		private function closeActionDropdown():void {
			actionDropdownOpen = false;
			actionDropdown.visible = false;

			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose);
		}

		private function doHideUI():void {
			padVisible = !padVisible;
			padContainer.visible = padVisible;

			if (showPadTf != null) {
				showPadTf.text = padVisible ? "Hide Game Pad" : "Show Game Pad";
			}

			if (dropdownOpen) {
				rebuildGearDropdown();
			}
		}

		private function doEditLayout():void {
			if (!padVisible && !layout.editMode) {
				doHideUI();
			}

			layout.toggleEdit();
			updateEditLayoutUI();
		}

		private function doResetLayout():void {
			layout.resetToDefaults();
			updateEditLayoutUI();
		}

		private function doEnterPip():void {
			if (Config.isAndroid) {
				closeDropdown();
				try {
					if (BatteryOptimizer.isPipSupported()) {
						var entered:Boolean = BatteryOptimizer.enterPipMode();
						if (!entered) {
							showInfoAlert("Picture-in-Picture", "Could not enter PiP mode.");
						}
					}
					else {
						showInfoAlert("Picture-in-Picture", "PiP mode is not supported on this device (Android 8.0+ required).");
					}
				}
				catch (ePip:Error) {
					showInfoAlert("Picture-in-Picture Error", "Error: " + ePip.message);
				}
			}
		}

		private function showInfoAlert(title:String, desc:String):void {
			const alert:InfoMessage = new InfoMessage(title, desc);
			if (stage != null) {
				stage.addChild(alert);
			}
			else {
				addChild(alert);
			}
		}

		private function updateEditLayoutUI():void {
			if (editLayoutTf != null) {
				editLayoutTf.text = layout.editMode ? "Save Layout" : "Edit Layout";
			}

			if (layout.editMode) {
				showEditLayoutBar();
			}
			else {
				hideEditLayoutBar();
			}
		}

		private function showEditLayoutBar():void {
			if (editLayoutBar == null) {
				buildEditLayoutBar();
			}

			if (stage != null) {
				editLayoutBar.x = (stage.stageWidth - EDIT_BAR_W) / 2;
				editLayoutBar.y = 8;
			}
			setChildIndex(editLayoutBar, numChildren - 1);
			editLayoutBar.visible = true;
		}

		private function hideEditLayoutBar():void {
			if (editLayoutBar != null) {
				editLayoutBar.visible = false;
			}
		}

		private function buildEditLayoutBar():void {
			editLayoutBar = new Sprite();

			drawPill(editLayoutBar.graphics, EDIT_BAR_W, EDIT_BAR_H, true);

			const btnW:Number = 88;
			const btnH:Number = 24;
			const btnY:Number = (EDIT_BAR_H - btnH) / 2;

			const resetBtn:MyButton = new MyButton("Reset Layout", btnW, btnH, MyButton.TYPE_DANGER, function(e:MouseEvent):void {
					doResetLayout();
				});
			resetBtn.x = 8;
			resetBtn.y = btnY;
			editLayoutBar.addChild(resetBtn);

			const saveBtn:MyButton = new MyButton("Save Layout", btnW, btnH, MyButton.TYPE_SUCCESS, function(e:MouseEvent):void {
					doEditLayout();
				});
			saveBtn.x = resetBtn.x + btnW + 8;
			saveBtn.y = btnY;
			editLayoutBar.addChild(saveBtn);

			addChild(editLayoutBar);
		}

		private function doWalkSpeed():void {
			game.world.WALKSPEED = game.world.WALKSPEED != 24 ? 24 : 12;
			game.chatF.pushMsg("server", "Walkspeed: " + game.world.WALKSPEED, "SERVER", "", 0);
		}

		private function doLagKiller():void {
			game.world.visible = !game.world.visible;
		}

		private function applyQuality():void {
			const next:String = StageQuality.LOW;

			if (stage != null) {
				stage.quality = next;
			}
			if (game != null && game.stage != null) {
				game.stage.quality = next;
			}
		}

		private function setSpawnPoint():void {
			mapCommands.setSpawnPoint();
			var spawnMsg:String = "Spawnpoint: " + mapCommands.getMyCell() + " " + mapCommands.getMyPad();
			game.chatF.pushMsg("server", spawnMsg, "SERVER", "", 0);
		}

		private function doHidePlayers():void {
			game.litePreference.data.bHidePlayers = !game.litePreference.data.bHidePlayers;
			game.litePreference.flush();
			for each (var player:Object in game.world.avatars) {
				if (player.pMC && !player.isMyAvatar) {
					player.pMC.mcChar.visible = !game.litePreference.data.bHidePlayers;
					player.pMC.pname.visible = true;
					player.pMC.shadow.visible = true;
				}
			}
		}

		private function openQuestTree():void {
			if (questUI == null)
				return;

			if (questUI.visible) {
				questUI.visible = false;
				return;
			}

			questUI.refresh();
			questUI.visible = true;

			try {
				setChildIndex(questUI, numChildren - 1);
			}
			catch (err:Error) {
			}

			if (stage != null) {
				questUI.x = int((stage.stageWidth - 350) / 2);
				questUI.y = int((stage.stageHeight - 440) / 2);
			}
		}

		private function openAutoQuest():void {
			openQuestTree();
		}

		private function openBotManager():void {
			if (botManagerUI == null)
				return;

			if (botManagerUI.visible) {
				botManagerUI.visible = false;
				if (autoQuestUI != null) {
					autoQuestUI.visible = false;
				}
				return;
			}

			botManagerUI.toggle();

			if (stage != null) {
				const combinedWidth:Number = 620 + 10 + 200; // 830
				const startX:Number = Math.max(10, int((stage.stageWidth - combinedWidth) / 2));
				const yPos:Number = Math.max(10, int((stage.stageHeight - 380) / 2));
				botManagerUI.x = startX;
				botManagerUI.y = yPos;

				if (autoQuestUI != null) {
					autoQuestUI.x = startX + 620 + 10;
					autoQuestUI.y = yPos;
				}
			}

			if (autoQuestUI != null) {
				autoQuestUI.visible = true;
				try {
					setChildIndex(autoQuestUI, numChildren - 1);
				}
				catch (err:Error) {
				}
			}
		}

		private function openCustomChar():void {
			if (customCharUI != null) {
				customCharUI.toggle();
			}
		}

		private function openCellJump():void {
			if (cellJumpUI != null && cellJumpUI.visible) {
				cellJumpUI.visible = false;
				return;
			}

			cellJumpUI.refresh();
			cellJumpUI.visible = true;
		}

		private function openLogger():void {
			if (loggerUI != null && loggerUI.visible) {
				loggerUI.visible = false;
				return;
			}

			if (loggerUI == null) {
				loggerUI = new PacketLoggerUI();
				addChild(loggerUI);
			}

			setChildIndex(loggerUI, numChildren - 1);
			loggerUI.visible = true;
			if (stage != null) {
				loggerUI.x = (stage.stageWidth - 500) / 2;
				loggerUI.y = (stage.stageHeight - 350) / 2;
			}
		}

		private function openAppLog():void {
			AppLogUI.toggle(stage);
		}

		private function onKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.F2) {
				openLogger();
			}
			else if (e.keyCode == Keyboard.F3) {
				openAppLog();
			}
		}

		private function doTestInfo():void {
			const alert:InfoMessage = new InfoMessage("Test Title", "This is a test description for the InfoMessage popup to verify layout and centering.");
			addChild(alert);
		}

		private function makeLabel(text:String, color:uint, size:int, bold:Boolean = false):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;

			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, TextFormatAlign.CENTER);
			tf.defaultTextFormat = fmt;
			tf.text = text;

			return tf;
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);

			padContainer = new Sprite();

			addChild(padContainer);
			padContainer.visible = false;

			joystick = new Joystick();
			walkCtrl = new WalkController(game, joystick);

			joystick.x = Joystick.DEFAULT_X;
			joystick.y = Joystick.DEFAULT_Y;

			padContainer.addChild(joystick);

			layout = new Layout();
			layout.register("joystick", joystick, Joystick.DEFAULT_X, Joystick.DEFAULT_Y);
			layout.load();

			autoBattle = new AutoBattle(game, onAutoBattleStateChange);
			autoQuest = new AutoQuest(game);
			mapCommands = new MapCommands(game);

			buildGearMenu();
			buildActionButton();
			buildAutoBattleButton();
			buildBankButton();

			applyQuality();

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
		}

		private function onGearClick(e:MouseEvent):void {
			if (dropdownOpen) {
				closeDropdown();
			}
			else {
				openDropdown();
			}

			e.stopImmediatePropagation();
		}

		private function onBankClick(e:MouseEvent):void {
			game.world.toggleBank();
			e.stopImmediatePropagation();
		}

		private function onActionClick(e:MouseEvent):void {
			if (actionDropdownOpen) {
				closeActionDropdown();
			}
			else {
				openActionDropdown();
			}

			e.stopImmediatePropagation();
		}

		private function onAutoBattleClick(e:MouseEvent):void {
			autoBattle.toggle();
			e.stopImmediatePropagation();
		}

		private function onStageClickClose(e:MouseEvent):void {
			if (dropdownOpen && !dropdown.hitTestPoint(e.stageX, e.stageY) && !gearBtn.hitTestPoint(e.stageX, e.stageY)) {
				closeDropdown();
			}
			if (actionDropdownOpen && !actionDropdown.hitTestPoint(e.stageX, e.stageY) && !actionMenuBtn.hitTestPoint(e.stageX, e.stageY)) {
				closeActionDropdown();
			}
			if (questUI != null && questUI.visible && !questUI.hitTestPoint(e.stageX, e.stageY) && (autoQuestUI != null && !autoQuestUI.hitTestPoint(e.stageX, e.stageY))) {
				questUI.visible = false;
				autoQuestUI.visible = false;
			}
			if (loggerUI != null && loggerUI.visible && !loggerUI.hitTestPoint(e.stageX, e.stageY)) {
				loggerUI.visible = false;
			}
		}

		private function onAutoBattleStateChange(state:int):void {
			if (autoBattleLabel != null) {
				switch (state) {
					case AutoBattle.STATE_IDLE:
						autoBattleLabel.text = "🔥";
						break;
					case AutoBattle.STATE_RUNNING:
						autoBattleLabel.text = "🚫";
						break;
					case AutoBattle.STATE_PAUSED:
						autoBattleLabel.text = "⏸️";
						break;
				}
			}
		}

		private function onDown(e:MouseEvent):void {
			if (!padVisible || layout.editMode) {
				return;
			}

			if (joystick.hitTest(e.stageX, e.stageY)) {
				joystick.move(e.stageX, e.stageY);
				stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}

		private function onMove(e:MouseEvent):void {
			if (joystick.dirX != 0 || joystick.dirY != 0) {
				joystick.move(e.stageX, e.stageY);
			}
		}

		private function onUp(e:MouseEvent):void {
			if (joystick.dirX == 0 && joystick.dirY == 0) {
				return;
			}

			joystick.snapHome();

			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

			walkCtrl.stop();
		}

		private function onEnterFrame(e:Event):void {
			walkCtrl.update();
		}

	}
}
