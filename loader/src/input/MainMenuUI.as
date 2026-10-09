package input {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;

	import ui.Layout;
	import ui.Joystick;
	import ui.InfoMessage;
	import ui.MyButton;
	import ui.UIUtils;
	import engine.AutoBattle;
	import engine.AutoQuest;
	import engine.BotEngine;
	import engine.MapCommands;
	import input.BotManagerUI;
	import input.CellJumpUI;
	import input.CustomCharUI;
	import input.PacketLoggerUI;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class MainMenuUI extends Sprite {

		private static const BTN_SIZE:Number = 32;
		private static const BTN_GAP:Number = 4;
		private static const BTN_POS_X:Number = 8;
		private static const BTN_POS_Y:Number = 8;
		private static const BTN_RADIUS:Number = 8;

		private static const MENU_W:Number = 145;
		private static const MENU_ITH:Number = 28;
		private static const MENU_RADIUS:Number = 8;

		private static const EDIT_BAR_W:Number = 216;
		private static const EDIT_BAR_H:Number = 40;

		public function MainMenuUI(game:MovieClip) {
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
		private var gearIcon:Shape;
		private var bankBtn:Sprite;
		private var bankIcon:Shape;
		private var actionMenuBtn:Sprite;
		private var actionIcon:Shape;
		private var botState:int = BotEngine.STATE_IDLE;
		private var autoBattleBtn:Sprite;
		private var autoBattleIcon:Shape;
		private var autoBattleState:int = AutoBattle.STATE_IDLE;
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
			gearIcon = new Shape();
			gearBtn.addChild(gearIcon);

			gearBtn.x = BTN_POS_X;
			gearBtn.y = BTN_POS_Y;
			gearBtn.buttonMode = true;
			gearBtn.useHandCursor = true;

			updateMenuBtnVisual(gearBtn, gearIcon, false, false);

			gearBtn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					updateMenuBtnVisual(gearBtn, gearIcon, true, dropdownOpen);
				});
			gearBtn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					updateMenuBtnVisual(gearBtn, gearIcon, false, dropdownOpen);
				});
			gearBtn.addEventListener(MouseEvent.CLICK, onGearClick);

			addChild(gearBtn);

			dropdown = new Sprite();
			dropdown.visible = false;
			dropdown.filters = [new DropShadowFilter(4, 90, 0x000000, 0.55, 12, 12, 1, 1)];

			dropdown.x = gearBtn.x + BTN_SIZE + 6;
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

			const panelH:Number = items.length * MENU_ITH + 8;

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
			actionIcon = new Shape();
			actionMenuBtn.addChild(actionIcon);

			actionMenuBtn.x = BTN_POS_X;
			actionMenuBtn.y = gearBtn.y + BTN_SIZE + BTN_GAP;
			actionMenuBtn.buttonMode = true;
			actionMenuBtn.useHandCursor = true;

			updateMenuBtnVisual(actionMenuBtn, actionIcon, false, false);

			actionMenuBtn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					var accent:uint = 0;
					if (botState == BotEngine.STATE_RUNNING) {
						accent = 0x10b981;
					}
					else if (botState == BotEngine.STATE_PAUSED) {
						accent = 0xf59e0b;
					}
					updateMenuBtnVisual(actionMenuBtn, actionIcon, true, actionDropdownOpen || botState != BotEngine.STATE_IDLE, accent);
				});
			actionMenuBtn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					var accent:uint = 0;
					if (botState == BotEngine.STATE_RUNNING) {
						accent = 0x10b981;
					}
					else if (botState == BotEngine.STATE_PAUSED) {
						accent = 0xf59e0b;
					}
					updateMenuBtnVisual(actionMenuBtn, actionIcon, false, actionDropdownOpen || botState != BotEngine.STATE_IDLE, accent);
				});
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
				if (botManagerUI.botEngine != null) {
					botManagerUI.botEngine.addStateListener(onBotStateChange);
					onBotStateChange(botManagerUI.botEngine.state);
				}
			}

			// Initialize Custom Char UI
			if (customCharUI == null) {
				customCharUI = new CustomCharUI(game);
				addChild(customCharUI);
				customCharUI.visible = false;
			}

			actionDropdown = new Sprite();
			actionDropdown.visible = false;
			actionDropdown.filters = [new DropShadowFilter(4, 90, 0x000000, 0.55, 12, 12, 1, 1)];

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

			const panelH:Number = items.length * MENU_ITH + 8;

			drawPill(actionDropdown.graphics, MENU_W, panelH, true);

			for (var i:int = 0; i < items.length; i++) {
				const row:Sprite = buildMenuItem(items[i].label, items[i].fn, i, closeActionDropdown);
				actionDropdown.addChild(row);
			}

			actionDropdown.x = actionMenuBtn.x + BTN_SIZE + 6;
			actionDropdown.y = actionMenuBtn.y;
			addChild(actionDropdown);
		}

		private function buildBankButton():void {
			bankBtn = new Sprite();
			bankIcon = new Shape();
			bankBtn.addChild(bankIcon);

			bankBtn.x = BTN_POS_X;
			bankBtn.y = autoBattleBtn.y + BTN_SIZE + BTN_GAP;
			bankBtn.buttonMode = true;
			bankBtn.useHandCursor = true;

			updateMenuBtnVisual(bankBtn, bankIcon, false, false);

			bankBtn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					updateMenuBtnVisual(bankBtn, bankIcon, true, false);
				});
			bankBtn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					updateMenuBtnVisual(bankBtn, bankIcon, false, false);
				});
			bankBtn.addEventListener(MouseEvent.CLICK, onBankClick);

			addChild(bankBtn);
		}

		private function buildAutoBattleButton():void {
			autoBattleBtn = new Sprite();
			autoBattleIcon = new Shape();
			autoBattleBtn.addChild(autoBattleIcon);

			autoBattleBtn.x = BTN_POS_X;
			autoBattleBtn.y = actionMenuBtn.y + BTN_SIZE + BTN_GAP;
			autoBattleBtn.buttonMode = true;
			autoBattleBtn.useHandCursor = true;

			updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, false, false);

			autoBattleBtn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					var accent:uint = 0;
					if (autoBattleState == AutoBattle.STATE_RUNNING) {
						accent = 0xef4444;
					}
					else if (autoBattleState == AutoBattle.STATE_PAUSED) {
						accent = 0xf59e0b;
					}
					updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, true, autoBattleState != AutoBattle.STATE_IDLE, accent);
				});
			autoBattleBtn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					var accent:uint = 0;
					if (autoBattleState == AutoBattle.STATE_RUNNING) {
						accent = 0xef4444;
					}
					else if (autoBattleState == AutoBattle.STATE_PAUSED) {
						accent = 0xf59e0b;
					}
					updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, false, autoBattleState != AutoBattle.STATE_IDLE, accent);
				});
			autoBattleBtn.addEventListener(MouseEvent.CLICK, onAutoBattleClick);

			addChild(autoBattleBtn);
		}

		private function buildMenuItem(lbl:String, fn:Function, idx:int, closeFn:Function = null):Sprite {
			const row:Sprite = new Sprite();

			const hoverBg:Shape = new Shape();
			hoverBg.graphics.beginFill(0x1e293b, 1.0);
			hoverBg.graphics.drawRoundRect(4, 2, MENU_W - 8, MENU_ITH - 4, 5);
			hoverBg.graphics.endFill();
			// Sleek left accent indicator
			hoverBg.graphics.beginFill(0x38bdf8, 1.0);
			hoverBg.graphics.drawRoundRect(4, 5, 2.5, MENU_ITH - 10, 1.5);
			hoverBg.graphics.endFill();
			hoverBg.visible = false;

			row.addChild(hoverBg);

			const tf:TextField = makeLabel(lbl, 0xf1f5f9, 11, false);
			tf.width = MENU_W - 18;
			tf.height = MENU_ITH;
			tf.x = 12;
			tf.y = Math.round((MENU_ITH - 16) / 2);
			tf.alpha = 0.85;

			const fmt:TextFormat = new TextFormat("_sans", 11, 0xf1f5f9, false, null, null, null, null, TextFormatAlign.LEFT);
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

			row.y = 4 + idx * MENU_ITH;
			row.buttonMode = true;
			row.useHandCursor = true;

			row.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
					hoverBg.visible = true;
					tf.textColor = 0xffffff;
					tf.alpha = 1.0;
				});

			row.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
					hoverBg.visible = false;
					tf.textColor = 0xf1f5f9;
					tf.alpha = 0.85;
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

		private function updateMenuBtnVisual(
				btn:Sprite,
				icon:DisplayObject,
				isHover:Boolean = false,
				isActive:Boolean = false,
				accentColor:uint = 0
			):void {
			if (btn == null)
				return;
			const g:Graphics = btn.graphics;
			g.clear();

			var bgColor:uint = 0x0f172a;
			var bgAlpha:Number = 0.85;
			var borderColor:uint = 0x334155;
			var borderAlpha:Number = 0.7;
			var borderThick:Number = 1.0;

			if (accentColor > 0) {
				borderColor = accentColor;
				borderAlpha = 0.95;
				borderThick = 1.5;
				if (accentColor == 0xef4444) {
					bgColor = 0x2e1214;
					bgAlpha = 0.92;
				}
				else if (accentColor == 0xf59e0b) {
					bgColor = 0x2d2212;
					bgAlpha = 0.92;
				}
				else if (accentColor == 0x10b981) {
					bgColor = 0x062e20;
					bgAlpha = 0.92;
				}
			}
			else if (isActive) {
				bgColor = 0x1e293b;
				bgAlpha = 0.96;
				borderColor = 0x38bdf8;
				borderAlpha = 0.95;
				borderThick = 1.5;
			}
			else if (isHover) {
				bgColor = 0x1e293b;
				bgAlpha = 0.92;
				borderColor = 0x64748b;
				borderAlpha = 0.9;
				borderThick = 1.2;
			}

			g.beginFill(bgColor, bgAlpha);
			g.lineStyle(borderThick, borderColor, borderAlpha, true);
			g.drawRoundRect(0, 0, BTN_SIZE, BTN_SIZE, BTN_RADIUS);
			g.endFill();

			// Redraw vector icon with dynamic theme colors
			if (icon is Shape) {
				var iconShape:Shape = Shape(icon);
				if (iconShape == gearIcon) {
					var gearColor:uint = isActive ? 0x38bdf8 : (isHover ? 0xffffff : 0x94a3b8);
					drawGearIcon(gearIcon, gearColor, bgColor);
				}
				else if (iconShape == actionIcon) {
					drawActionIcon(actionIcon, botState, isHover, isActive);
				}
				else if (iconShape == autoBattleIcon) {
					drawAutoBattleIcon(autoBattleIcon, autoBattleState, isHover, isActive);
				}
				else if (iconShape == bankIcon) {
					var bankColor:uint = isHover ? 0xfbbf24 : (isActive ? 0x38bdf8 : 0x94a3b8);
					drawBankIcon(bankIcon, bankColor);
				}
			}
			else if (icon is TextField) {
				TextField(icon).alpha = (isHover || isActive || accentColor > 0) ? 1.0 : 0.75;
			}

			if (accentColor > 0) {
				btn.filters = [
						new DropShadowFilter(2, 90, 0x000000, 0.45, 4, 4, 1, 1),
						new GlowFilter(accentColor, 0.5, 6, 6, 1.2, 1)
					];
			}
			else if (isActive) {
				btn.filters = [
						new DropShadowFilter(2, 90, 0x000000, 0.45, 4, 4, 1, 1),
						new GlowFilter(0x38bdf8, 0.45, 6, 6, 1.2, 1)
					];
			}
			else if (isHover) {
				btn.filters = [
						new DropShadowFilter(2, 90, 0x000000, 0.45, 5, 5, 1, 1),
						new GlowFilter(0x64748b, 0.25, 4, 4, 1, 1)
					];
			}
			else {
				btn.filters = [
						new DropShadowFilter(2, 90, 0x000000, 0.4, 4, 4, 1, 1)
					];
			}
		}

		private function drawGearIcon(s:Shape, color:uint, bgColor:uint):void {
			if (s == null)
				return;
			const g:Graphics = s.graphics;
			g.clear();

			const cx:Number = 16.0;
			const cy:Number = 16.0;
			const teeth:int = 6;
			const rOuter:Number = 7.5;
			const rInner:Number = 5.2;
			const rHole:Number = 2.4;

			g.beginFill(color, 1.0);
			const totalPoints:int = teeth * 4;
			for (var i:int = 0; i < totalPoints; i++) {
				var toothIndex:int = i / 4;
				var step:int = i % 4;
				var baseAng:Number = (toothIndex * 2 * Math.PI) / teeth;
				var halfTooth:Number = 0.18;
				var halfValley:Number = 0.34;

				var ang:Number;
				var r:Number;
				if (step == 0) {
					ang = baseAng - halfTooth;
					r = rOuter;
				}
				else if (step == 1) {
					ang = baseAng + halfTooth;
					r = rOuter;
				}
				else if (step == 2) {
					ang = baseAng + halfValley;
					r = rInner;
				}
				else {
					ang = baseAng + (2 * Math.PI / teeth) - halfValley;
					r = rInner;
				}

				var px:Number = cx + Math.cos(ang) * r;
				var py:Number = cy + Math.sin(ang) * r;
				if (i == 0) {
					g.moveTo(px, py);
				}
				else {
					g.lineTo(px, py);
				}
			}
			g.endFill();

			// Center hole knockout
			g.beginFill(bgColor, 1.0);
			g.drawCircle(cx, cy, rHole);
			g.endFill();
		}

		private function drawActionIcon(
				s:Shape,
				botState:int,
				isHover:Boolean = false,
				isActive:Boolean = false
			):void {
			if (s == null)
				return;
			const g:Graphics = s.graphics;
			g.clear();

			if (botState == BotEngine.STATE_RUNNING) {
				// Modern Cybernetic Bot / Robot icon in glowing emerald green
				const botColor:uint = isHover ? 0x6ee7b7 : 0x34d399;
				const eyeColor:uint = 0xffffff;

				// Antenna stem
				g.lineStyle(1.8, botColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(16.0, 6.2);
				g.lineTo(16.0, 9.5);
				// Antenna tip orb
				g.lineStyle(0, 0, 0);
				g.beginFill(botColor, 1.0);
				g.drawCircle(16.0, 5.0, 1.8);
				g.endFill();

				// Head Chassis
				g.beginFill(0x064e3b, 0.95);
				g.lineStyle(1.8, botColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				g.drawRoundRect(9.0, 9.5, 14.0, 12.5, 4, 4);
				g.endFill();

				// Side Bolts / Ears
				g.lineStyle(0, 0, 0);
				g.beginFill(botColor, 1.0);
				g.drawRoundRect(6.8, 13.0, 2.2, 5.5, 1, 1);
				g.drawRoundRect(23.0, 13.0, 2.2, 5.5, 1, 1);
				g.endFill();

				// Glowing Visor / Eyes
				g.beginFill(eyeColor, 1.0);
				g.drawRoundRect(11.5, 13.0, 3.2, 2.8, 1, 1);
				g.drawRoundRect(17.3, 13.0, 3.2, 2.8, 1, 1);
				g.endFill();

				// Audio-grille / Mouth
				g.lineStyle(1.5, botColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(12.5, 18.2);
				g.lineTo(19.5, 18.2);
				return;
			}

			if (botState == BotEngine.STATE_PAUSED) {
				// Clean amber dual pause bars
				const pauseColor:uint = isHover ? 0xfcd34d : 0xf59e0b;
				g.lineStyle(0, 0, 0);
				g.beginFill(pauseColor, 1.0);
				g.drawRoundRect(10.5, 9.5, 3.5, 13.0, 2, 2);
				g.drawRoundRect(18.0, 9.5, 3.5, 13.0, 2, 2);
				g.endFill();
				return;
			}

			// STATE_IDLE: Sharp faceted lightning bolt
			var boltColor:uint = (isActive || isHover) ? 0x38bdf8 : 0x94a3b8;
			g.lineStyle(0, 0, 0);
			g.beginFill(boltColor, 1.0);
			g.moveTo(17.5, 7.5);
			g.lineTo(11.0, 15.5);
			g.lineTo(15.2, 15.5);
			g.lineTo(13.0, 24.5);
			g.lineTo(21.0, 14.5);
			g.lineTo(16.5, 14.5);
			g.lineTo(17.5, 7.5);
			g.endFill();
		}

		private function drawBankIcon(s:Shape, color:uint):void {
			if (s == null)
				return;
			const g:Graphics = s.graphics;
			g.clear();

			g.beginFill(color, 1.0);

			// Triangular Roof (Pediment)
			g.moveTo(16.0, 7.0);
			g.lineTo(24.5, 12.0);
			g.lineTo(7.5, 12.0);
			g.lineTo(16.0, 7.0);

			// Architrave (beam)
			g.drawRoundRect(7.5, 13.0, 17.0, 1.8, 0.5, 0.5);

			// 3 Classical Columns
			g.drawRoundRect(9.0, 15.8, 2.6, 6.8, 0.5, 0.5);
			g.drawRoundRect(14.7, 15.8, 2.6, 6.8, 0.5, 0.5);
			g.drawRoundRect(20.4, 15.8, 2.6, 6.8, 0.5, 0.5);

			// Base Steps (Stylobate)
			g.drawRoundRect(8.0, 23.4, 16.0, 1.6, 0.5, 0.5);
			g.drawRoundRect(6.5, 25.4, 19.0, 1.8, 0.6, 0.6);

			g.endFill();
		}

		private function drawAutoBattleIcon(
				s:Shape,
				state:int,
				isHover:Boolean = false,
				isActive:Boolean = false
			):void {
			if (s == null)
				return;
			const g:Graphics = s.graphics;
			g.clear();

			if (state == AutoBattle.STATE_PAUSED) {
				// Clean amber dual pause bars
				const pauseColor:uint = isHover ? 0xfcd34d : 0xf59e0b;
				g.lineStyle(0, 0, 0);
				g.beginFill(pauseColor, 1.0);
				g.drawRoundRect(10.5, 9.5, 3.5, 13.0, 2, 2);
				g.drawRoundRect(18.0, 9.5, 3.5, 13.0, 2, 2);
				g.endFill();
				return;
			}

			if (state == AutoBattle.STATE_RUNNING) {
				// Active combat: fiery crimson crossed swords with flame core
				const runBlade:uint = isHover ? 0xff6b6b : 0xef4444;
				const runHilt:uint = 0xfca5a5;

				// Sword 1 (bottom-left to top-right)
				g.lineStyle(1.8, runBlade, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				g.moveTo(11.5, 20.5);
				g.lineTo(22.0, 10.0);
				// Guard 1
				g.lineStyle(2.0, runBlade, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(10.5, 16.5);
				g.lineTo(15.5, 21.5);
				// Pommel 1
				g.lineStyle(1.8, runHilt, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(11.5, 20.5);
				g.lineTo(9.5, 22.5);

				// Sword 2 (bottom-right to top-left)
				g.lineStyle(1.8, runBlade, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				g.moveTo(20.5, 20.5);
				g.lineTo(10.0, 10.0);
				// Guard 2
				g.lineStyle(2.0, runBlade, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(21.5, 16.5);
				g.lineTo(16.5, 21.5);
				// Pommel 2
				g.lineStyle(1.8, runHilt, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
				g.moveTo(20.5, 20.5);
				g.lineTo(22.5, 22.5);

				// Center blazing flame
				g.lineStyle(0, 0, 0);
				g.beginFill(0xfbbf24, 0.95);
				g.moveTo(16.0, 7.0);
				g.curveTo(18.0, 10.5, 18.5, 13.0);
				g.curveTo(19.0, 16.0, 17.5, 17.5);
				g.curveTo(16.0, 18.5, 14.5, 17.5);
				g.curveTo(13.0, 16.0, 13.5, 13.0);
				g.curveTo(14.0, 10.5, 16.0, 7.0);
				g.endFill();

				// Inner flame white core
				g.beginFill(0xffffff, 0.9);
				g.drawEllipse(15.0, 13.0, 2.0, 3.2);
				g.endFill();
				return;
			}

			// STATE_IDLE: Elegant Crossed Swords
			const bladeColor:uint = isHover ? 0xffffff : 0x94a3b8;
			const guardColor:uint = isHover ? 0xe2e8f0 : 0x64748b;
			const hiltColor:uint = isHover ? 0xcbd5e1 : 0x475569;

			// Sword 1 (bottom-left to top-right)
			g.lineStyle(1.8, bladeColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
			g.moveTo(11.5, 20.5);
			g.lineTo(22.0, 10.0);
			// Guard 1
			g.lineStyle(2.0, guardColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
			g.moveTo(10.5, 16.5);
			g.lineTo(15.5, 21.5);
			// Pommel 1
			g.lineStyle(1.8, hiltColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
			g.moveTo(11.5, 20.5);
			g.lineTo(9.5, 22.5);

			// Sword 2 (bottom-right to top-left)
			g.lineStyle(1.8, bladeColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
			g.moveTo(20.5, 20.5);
			g.lineTo(10.0, 10.0);
			// Guard 2
			g.lineStyle(2.0, guardColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
			g.moveTo(21.5, 16.5);
			g.lineTo(16.5, 21.5);
			// Pommel 2
			g.lineStyle(1.8, hiltColor, 1.0, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
			g.moveTo(20.5, 20.5);
			g.lineTo(22.5, 22.5);
		}

		private function drawPill(g:Graphics, w:Number, h:Number, panel:Boolean = false):void {
			g.clear();
			g.beginFill(0x0f172a, panel ? 0.94 : 0.85);
			g.drawRoundRect(0, 0, w, h, panel ? MENU_RADIUS : BTN_RADIUS);
			g.endFill();
			g.lineStyle(1, 0x334155, 0.75, true);
			g.drawRoundRect(0, 0, w, h, panel ? MENU_RADIUS : BTN_RADIUS);
		}

		private function openDropdown():void {
			if (actionDropdownOpen) {
				closeActionDropdown();
			}
			rebuildGearDropdown();
			dropdownOpen = true;
			dropdown.visible = true;
			updateMenuBtnVisual(gearBtn, gearIcon, false, true);

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose, false, 0, true);
		}

		private function closeDropdown():void {
			dropdownOpen = false;
			dropdown.visible = false;
			updateMenuBtnVisual(gearBtn, gearIcon, false, false);

			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose);
		}

		private function openActionDropdown():void {
			if (dropdownOpen) {
				closeDropdown();
			}
			actionDropdownOpen = true;
			actionDropdown.visible = true;
			var accent:uint = (botState == BotEngine.STATE_RUNNING) ? 0x10b981 : ((botState == BotEngine.STATE_PAUSED) ? 0xf59e0b : 0);
			updateMenuBtnVisual(actionMenuBtn, actionIcon, false, true, accent);

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageClickClose, false, 0, true);
		}

		private function closeActionDropdown():void {
			actionDropdownOpen = false;
			actionDropdown.visible = false;
			var accent:uint = (botState == BotEngine.STATE_RUNNING) ? 0x10b981 : ((botState == BotEngine.STATE_PAUSED) ? 0xf59e0b : 0);
			updateMenuBtnVisual(actionMenuBtn, actionIcon, false, botState != BotEngine.STATE_IDLE, accent);

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
			editLayoutBar.filters = [new DropShadowFilter(4, 90, 0x000000, 0.5, 10, 10, 1, 1)];

			const btnW:Number = 96;
			const btnH:Number = 26;
			const btnY:Number = (EDIT_BAR_H - btnH) / 2;

			const resetBtn:MyButton = new MyButton("Reset Layout", btnW, btnH, MyButton.TYPE_DANGER, function(e:MouseEvent):void {
					doResetLayout();
				}, 11, 6);
			resetBtn.x = 8;
			resetBtn.y = btnY;
			editLayoutBar.addChild(resetBtn);

			const saveBtn:MyButton = new MyButton("Save Layout", btnW, btnH, MyButton.TYPE_SUCCESS, function(e:MouseEvent):void {
					doEditLayout();
				}, 11, 6);
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
			autoBattleState = state;
			if (autoBattleIcon != null) {
				switch (state) {
					case AutoBattle.STATE_IDLE:
						updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, false, false, 0);
						break;
					case AutoBattle.STATE_RUNNING:
						updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, false, true, 0xef4444);
						break;
					case AutoBattle.STATE_PAUSED:
						updateMenuBtnVisual(autoBattleBtn, autoBattleIcon, false, true, 0xf59e0b);
						break;
				}
			}
		}

		private function onBotStateChange(state:int):void {
			botState = state;
			if (actionIcon != null) {
				switch (state) {
					case BotEngine.STATE_IDLE:
						updateMenuBtnVisual(actionMenuBtn, actionIcon, false, actionDropdownOpen, 0);
						break;
					case BotEngine.STATE_RUNNING:
						updateMenuBtnVisual(actionMenuBtn, actionIcon, false, true, 0x10b981);
						break;
					case BotEngine.STATE_PAUSED:
						updateMenuBtnVisual(actionMenuBtn, actionIcon, false, true, 0xf59e0b);
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
