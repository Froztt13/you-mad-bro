package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.text.*;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	import engine.AutoBattle;
	import ui.UIUtils;

	public class FabOverlay extends Sprite {

		public static const SO_KEY:String = "aqw_fab_settings";
		public static const PREF_FAB_BUTTONS:String = "fab_buttons";
		public static const PREF_FAB_VISIBLE:String = "fab_visible";

		public static const BTN_SIZE:Number = 46;

		public static var instance:FabOverlay;

		private var game:Object;
		private var buttonsData:Array = [];
		private var buttonSprites:Array = [];

		public function FabOverlay(game:Object) {
			instance = this;
			this.game = game;

			loadConfig();
			rebuildButtons();

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			if (stage != null) {
				stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			}
			clampAllButtonsToStage();
		}

		private function onStageResize(e:Event):void {
			clampAllButtonsToStage();
		}

		public function clampAllButtonsToStage():void {
			for (var i:int = 0; i < buttonsData.length; i++) {
				var data:Object = buttonsData[i];
				if (isNaN(data.x))
					data.x = 100;
				if (isNaN(data.y))
					data.y = 100;
			}
			updateSpritePositions();
		}

		public function getButtonsData():Array {
			return buttonsData;
		}

		public function setButtonsData(newData:Array):void {
			buttonsData = [];
			for each (var item:Object in newData) {
				buttonsData.push({
					id: item.id || ("fab_" + Math.random().toString().substr(2, 6)),
					label: String(item.label || "Key"),
					action: String(item.action || "key"),
					key: String(item.key || "1"),
					keyCode: int(item.keyCode || getKeyCodeForString(item.key)),
					x: Number(item.x || 100),
					y: Number(item.y || 100)
				});
			}
			saveConfig();
			rebuildButtons();
		}

		public function resetToDefaults():void {
			buttonsData = getDefaultButtons();
			saveConfig();
			rebuildButtons();
		}

		public static function getDefaultButtons():Array {
			return [
				{ id: "fab_space", label: "Space", action: "key", key: "Space", keyCode: 32, x: 905, y: 280 },
				{ id: "fab_bot", label: "On/Off", action: "toggle_bot", key: "", keyCode: 0, x: 905, y: 410 },
				{ id: "fab_leave", label: "Leave", action: "leave_combat", key: "", keyCode: 0, x: 905, y: 345 }
			];
		}

		public function loadConfig():void {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null && so.data.hasOwnProperty(PREF_FAB_BUTTONS) && so.data[PREF_FAB_BUTTONS] is Array) {
					var rawList:Array = so.data[PREF_FAB_BUTTONS];
					var isOldDefaults:Boolean = (rawList.length == 8 && rawList[0] != null && rawList[0].label == "1" && rawList[1] != null && rawList[1].label == "2");
					if (rawList.length > 0 && !isOldDefaults) {
						buttonsData = [];
						for each (var it:Object in rawList) {
							buttonsData.push({
								id: it.id || ("fab_" + Math.random().toString().substr(2, 6)),
								label: String(it.label || "Key"),
								action: String(it.action || "key"),
								key: String(it.key || "1"),
								keyCode: int(it.keyCode || getKeyCodeForString(it.key)),
								x: Number(it.x || 100),
								y: Number(it.y || 100)
							});
						}
						return;
					}
				}
			}
			catch (e:Error) {
			}

			buttonsData = getDefaultButtons();
		}

		public static function loadVisibility():Boolean {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null && so.data.hasOwnProperty(PREF_FAB_VISIBLE)) {
					return Boolean(so.data[PREF_FAB_VISIBLE]);
				}
			}
			catch (e:Error) {
			}
			return false;
		}

		public static function saveVisibility(v:Boolean):void {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null) {
					so.data[PREF_FAB_VISIBLE] = v;
					so.flush();
				}
			}
			catch (e:Error) {
			}
		}

		public function saveConfig():void {
			try {
				var so:SharedObject = SharedObject.getLocal(SO_KEY);
				if (so != null && so.data != null) {
					so.data[PREF_FAB_BUTTONS] = buttonsData;
					so.data[PREF_FAB_VISIBLE] = this.visible;
					so.flush();
				}
			}
			catch (e:Error) {
			}
		}

		public function rebuildButtons():void {
			for each (var s:Sprite in buttonSprites) {
				if (s.parent != null) {
					s.parent.removeChild(s);
				}
			}
			buttonSprites = [];

			for (var i:int = 0; i < buttonsData.length; i++) {
				var data:Object = buttonsData[i];
				var btn:Sprite = createFabButtonSprite(data, i);
				addChild(btn);
				buttonSprites.push(btn);
			}
		}

		private function updateSpritePositions():void {
			for (var i:int = 0; i < buttonSprites.length; i++) {
				if (i < buttonsData.length) {
					var btn:Sprite = buttonSprites[i];
					btn.x = buttonsData[i].x;
					btn.y = buttonsData[i].y;
				}
			}
		}

		private function createFabButtonSprite(data:Object, index:int):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;
			btn.x = data.x;
			btn.y = data.y;

			const bgShape:Shape = new Shape();
			drawFabBg(bgShape.graphics, false, false);
			btn.addChild(bgShape);

			// Main Label
			var act:String = String(data.action || "key").toLowerCase();
			var labelStr:String = String(data.label || "Key");
			var fontSize:Number = (labelStr.length > 5) ? 9 : ((labelStr.length > 3) ? 10.5 : 13);
			const labelTf:TextField = UIUtils.createLabel(labelStr, 0xffffff, fontSize, true, TextFormatAlign.CENTER);
			labelTf.width = BTN_SIZE;
			labelTf.height = BTN_SIZE;
			labelTf.y = int((BTN_SIZE - (fontSize + 6)) / 2);
			btn.addChild(labelTf);

			// Sub key hint label (tiny in bottom-right corner)
			var hintStr:String = "";
			if (act != "key" && act != "") {
				if (act == "bot") hintStr = "MGR";
				else if (act == "toggle_bot" || act == "start_bot") hintStr = "BOT";
				else if (act == "leave_combat" || act == "combat") hintStr = "EXIT";
				else if (act == "loader" || act == "grabber") hintStr = "LDR";
				else if (act == "cell") hintStr = "JMP";
				else if (act == "lag") hintStr = "LAG";
				else if (act == "bank") hintStr = "BNK";
				else if (act == "logger" || act == "packet") hintStr = "LOG";
			}
			else {
				hintStr = getKeyShortName(data.key);
			}

			if (hintStr != "" && hintStr.toUpperCase() != labelStr.toUpperCase() && labelStr.length <= 3) {
				const hintTf:TextField = UIUtils.createLabel(hintStr, 0x38bdf8, 7.5, true, TextFormatAlign.RIGHT);
				hintTf.width = BTN_SIZE - 4;
				hintTf.height = 12;
				hintTf.y = BTN_SIZE - 13;
				btn.addChild(hintTf);
			}

			btn.filters = [new DropShadowFilter(4, 90, 0x000000, 0.6, 8, 8)];

			// Drag vs Tap gesture handling
			var startX:Number = 0;
			var startY:Number = 0;
			var isMouseDown:Boolean = false;

			var onMouseUp:Function = function(e:Event = null):void {
				if (!isMouseDown)
					return;
				isMouseDown = false;
				btn.stopDrag();

				if (stage != null) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
				}

				drawFabBg(bgShape.graphics, false, false);

				var dx:Number = btn.x - startX;
				var dy:Number = btn.y - startY;
				var distSq:Number = dx * dx + dy * dy;

				if (distSq > 25) {
					// Drag finished: save new position
					data.x = btn.x;
					data.y = btn.y;
					saveConfig();
				}
				else {
					// Snap back to exact start position (avoid tiny finger jitter drift)
					btn.x = startX;
					btn.y = startY;
					// Click / Tap detected: trigger action
					flashButton(bgShape);
					triggerButton(data);
				}
			};

			btn.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				isMouseDown = true;
				startX = btn.x;
				startY = btn.y;

				setChildIndex(btn, numChildren - 1);
				btn.startDrag();

				drawFabBg(bgShape.graphics, true, true);

				if (stage != null) {
					stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
					stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp, false, 0, true);
				}
				e.stopImmediatePropagation();
			});

			btn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				if (!isMouseDown)
					drawFabBg(bgShape.graphics, true, false);
			});

			btn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
				if (!isMouseDown)
					drawFabBg(bgShape.graphics, false, false);
			});

			return btn;
		}

		private function drawFabBg(g:Graphics, isHover:Boolean, isPressed:Boolean):void {
			g.clear();
			var fillColor:uint = isPressed ? 0x1e293b : 0x0f172a;
			var fillAlpha:Number = isPressed ? 0.95 : 0.88;
			var strokeColor:uint = isPressed ? 0x38bdf8 : (isHover ? 0x60a5fa : 0x334155);
			var strokeThickness:Number = isPressed ? 2.0 : 1.5;

			g.beginFill(fillColor, fillAlpha);
			g.lineStyle(strokeThickness, strokeColor, 1.0);
			g.drawRoundRect(0, 0, BTN_SIZE, BTN_SIZE, 12, 12);
			g.endFill();
		}

		private function flashButton(bgShape:Shape):void {
			bgShape.filters = [new GlowFilter(0x38bdf8, 0.9, 12, 12, 2, 2)];
			flash.utils.setTimeout(function():void {
				if (bgShape != null) {
					bgShape.filters = [];
				}
			}, 120);
		}

		public function triggerButton(data:Object):void {
			if (data == null)
				return;

			var act:String = String(data.action || "").toLowerCase();

			// Auto-detect action if not explicitly set
			if (act == "" || act == "key") {
				var checkKey:String = String(data.key || "").toLowerCase();
				if (checkKey == "bot" || checkKey == "bot manager") act = "bot";
				else if (checkKey == "toggle bot" || checkKey == "start bot" || checkKey == "stop bot") act = "toggle_bot";
				else if (checkKey == "leave combat" || checkKey == "combat" || checkKey == "exit combat") act = "leave_combat";
				else if (checkKey == "loader" || checkKey == "grabber" || checkKey == "loader / grabber") act = "loader";
				else if (checkKey == "cell" || checkKey == "cell jump") act = "cell";
				else if (checkKey == "lag" || checkKey == "lag killer") act = "lag";
				else if (checkKey == "bank") act = "bank";
				else if (checkKey == "logger" || checkKey == "packet logger") act = "logger";
			}

			// 1. Feature toggles
			if (act == "bot") {
				MainMenuUI.sOpenBotManager();
				return;
			}
			if (act == "toggle_bot" || act == "start_bot" || act == "bot_toggle") {
				MainMenuUI.sToggleBot();
				return;
			}
			if (act == "leave_combat" || act == "combat" || act == "exit_combat") {
				MainMenuUI.sLeaveCombat();
				return;
			}
			if (act == "loader" || act == "grabber") {
				MainMenuUI.sOpenQuestTree();
				return;
			}
			if (act == "cell") {
				MainMenuUI.sOpenCellJump();
				return;
			}
			if (act == "lag") {
				MainMenuUI.sDoLagKiller();
				return;
			}
			if (act == "bank") {
				MainMenuUI.sToggleBank();
				return;
			}
			if (act == "logger" || act == "packet") {
				MainMenuUI.sOpenLogger();
				return;
			}

			// 2. Keyboard hotkeys
			var keyCode:int = int(data.keyCode);
			var keyStr:String = String(data.key || "").toUpperCase();

			// Dispatch keyboard event to stage
			if (stage != null) {
				var charCode:int = 0;
				if (keyStr.length == 1) {
					charCode = keyStr.charCodeAt(0);
				}
				else if (keyCode == Keyboard.SPACE) {
					charCode = 32;
				}
				else if (keyCode == Keyboard.ESCAPE) {
					charCode = 27;
				}
				else if (keyCode == Keyboard.ENTER) {
					charCode = 13;
				}
				else if (keyCode >= 48 && keyCode <= 57) {
					charCode = keyCode;
				}

				var target:InteractiveObject = (stage.focus != null) ? stage.focus : stage;
				target.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, charCode, keyCode));
				target.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, charCode, keyCode));
			}

			// Direct game actions for guaranteed responsiveness
			if (game != null && game.world != null) {
				try {
					// Skill 1-5 (keyCode 49 to 53)
					if (keyCode >= 49 && keyCode <= 53) {
						var skillIdx:int = keyCode - 49;
						AutoBattle.useSkill(game, skillIdx);
					}
					// Rest (key T / keyCode 84)
					else if (keyCode == 84 || keyStr == "T") {
						if ("rest" in game.world) {
							game.world.rest();
						}
					}
					// Jump (Space / keyCode 32)
					else if (keyCode == 32 || keyStr == "SPACE") {
						if (game.world.myAvatar != null && "jump" in game.world.myAvatar) {
							game.world.myAvatar.jump();
						}
					}
					// Cancel target (Esc / keyCode 27)
					else if (keyCode == 27 || keyStr == "ESC") {
						if ("cancelTarget" in game.world) {
							game.world.cancelTarget();
						}
					}
				}
				catch (e:Error) {
				}
			}
		}

		public static function getKeyCodeForString(str:String):int {
			if (str == null || str.length == 0)
				return 0;
			var s:String = str.toUpperCase().replace(/\s+/g, "");
			if (s == "SPACE" || s == "SPC")
				return Keyboard.SPACE;
			if (s == "ESC" || s == "ESCAPE")
				return Keyboard.ESCAPE;
			if (s == "ENTER" || s == "RETURN")
				return Keyboard.ENTER;
			if (s == "TAB")
				return Keyboard.TAB;
			if (s == "UP")
				return Keyboard.UP;
			if (s == "DOWN")
				return Keyboard.DOWN;
			if (s == "LEFT")
				return Keyboard.LEFT;
			if (s == "RIGHT")
				return Keyboard.RIGHT;

			// If raw integer string
			var num:int = int(s);
			if (num > 0 && String(num) == s) {
				if (num >= 0 && num <= 9) {
					return 48 + num; // '0' is 48, '1' is 49
				}
				return num;
			}

			// Single character
			if (s.length == 1) {
				var code:int = s.charCodeAt(0);
				return code;
			}

			return 0;
		}

		public static function getKeyShortName(str:String):String {
			if (str == null)
				return "";
			var s:String = str.toUpperCase().replace(/\s+/g, "");
			if (s == "SPACE" || s == "32")
				return "SPC";
			if (s == "ESCAPE" || s == "27")
				return "ESC";
			if (s == "ENTER" || s == "13")
				return "ENT";
			return str;
		}
	}
}
