package ui {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.Keyboard;
	import flash.utils.*;

	public class ChatPreviewUI extends Sprite {
		private static const BOX_W:Number = 480;
		private static const BOX_H:Number = 36;

		private var game:MovieClip;
		private var currentInput:TextField;
		private var lastText:String = "";

		private var bgShape:Shape;
		private var badgeContainer:Sprite;
		private var badgeLabel:TextField;
		private var previewTf:TextField;
		private var clearBtn:Sprite;
		private var sendBtn:Sprite;

		private var blinkTick:int = 0;
		private var cursorVisible:Boolean = true;
		private var hideTimeoutId:uint = 0;

		public function ChatPreviewUI(game:MovieClip) {
			this.game = game;
			this.visible = false;

			buildUI();

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

			stage.addEventListener(FocusEvent.FOCUS_IN, onFocusIn, true);
			stage.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, true);
			stage.addEventListener(Event.RESIZE, onResize);

			updatePosition();
		}

		private function buildUI():void {
			// 1. Background Box (Glassmorphic dark cyber pill)
			bgShape = new Shape();
			redrawBackground();
			addChild(bgShape);

			// Drop shadow & subtle cyan glow
			this.filters = [
					new DropShadowFilter(3, 90, 0x000000, 0.65, 8, 8, 1, 2),
					new GlowFilter(0x0284c7, 0.40, 6, 6, 1, 2)
				];

			// 2. Left Badge (💬 Chat / Input)
			badgeContainer = new Sprite();
			badgeContainer.x = 6;
			badgeContainer.y = 6;

			const bgBadge:Shape = new Shape();
			bgBadge.graphics.beginFill(0x1e293b, 0.85);
			bgBadge.graphics.drawRoundRect(0, 0, 52, 24, 6);
			bgBadge.graphics.endFill();
			bgBadge.graphics.lineStyle(1, 0x38bdf8, 0.4);
			bgBadge.graphics.drawRoundRect(0, 0, 52, 24, 6);
			badgeContainer.addChild(bgBadge);

			badgeLabel = new TextField();
			badgeLabel.defaultTextFormat = new TextFormat("_sans", 10, 0x38bdf8, true, null, null, null, null, TextFormatAlign.CENTER);
			badgeLabel.text = "💬 Chat";
			badgeLabel.width = 52;
			badgeLabel.height = 20;
			badgeLabel.y = 3;
			badgeLabel.selectable = false;
			badgeLabel.mouseEnabled = false;
			badgeContainer.addChild(badgeLabel);

			addChild(badgeContainer);

			// 3. Text Display Field (Middle)
			previewTf = new TextField();
			previewTf.x = 64;
			previewTf.y = 6;
			previewTf.width = 338;
			previewTf.height = 24;
			previewTf.selectable = false;
			previewTf.mouseEnabled = false;

			const tfFormat:TextFormat = new TextFormat("_sans", 13, 0xffffff, false);
			previewTf.defaultTextFormat = tfFormat;
			previewTf.text = "";

			addChild(previewTf);

			// 4. Clear Button ("✕")
			clearBtn = buildButton("✕", 24, 24, 0x1e293b, 0x94a3b8, onClearClick);
			clearBtn.x = 408;
			clearBtn.y = 6;
			addChild(clearBtn);

			// 5. Send Button ("➤")
			sendBtn = buildButton("➤", 38, 24, 0x0284c7, 0xffffff, onSendClick, true);
			sendBtn.x = 436;
			sendBtn.y = 6;
			addChild(sendBtn);
		}

		private function redrawBackground():void {
			const g:Graphics = bgShape.graphics;
			g.clear();

			// Dark obsidian / slate glassmorphic fill
			g.beginFill(0x090d16, 0.92);
			g.drawRoundRect(0, 0, BOX_W, BOX_H, 8);
			g.endFill();

			// Top highlight border & glowing cyan rim
			g.lineStyle(1.4, 0x38bdf8, 0.65);
			g.drawRoundRect(0, 0, BOX_W, BOX_H, 8);
		}

		private function buildButton(
				label:String,
				w:Number,
				h:Number,
				bgCol:uint,
				txtCol:uint,
				clickHandler:Function,
				isPrimary:Boolean = false
			):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			bg.graphics.beginFill(bgCol, isPrimary ? 0.95 : 0.75);
			bg.graphics.drawRoundRect(0, 0, w, h, 6);
			bg.graphics.endFill();
			bg.graphics.lineStyle(1, isPrimary ? 0x38bdf8 : 0x475569, 0.6);
			bg.graphics.drawRoundRect(0, 0, w, h, 6);
			btn.addChild(bg);

			const tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", 11, txtCol, true, null, null, null, null, TextFormatAlign.CENTER);
			tf.text = label;
			tf.width = w;
			tf.height = h;
			tf.y = (h - 18) / 2;
			tf.selectable = false;
			tf.mouseEnabled = false;
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					btn.alpha = 0.85;
				});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					btn.alpha = 1.0;
				});
			btn.addEventListener(MouseEvent.CLICK, clickHandler);

			return btn;
		}

		private function updatePosition():void {
			if (stage != null) {
				this.x = (stage.stageWidth - BOX_W) / 2;
				this.y = 10;
			}
		}

		private function onResize(e:Event):void {
			updatePosition();
		}

		// =========================================================================
		// Focus & Input Detection
		// =========================================================================

		private function isInGame():Boolean {
			try {
				if (game != null && game.world != null && game.world.myAvatar != null) {
					return true;
				}
			}
			catch (e:Error) {
			}
			return false;
		}

		private function isLoginField(tf:TextField):Boolean {
			if (tf == null)
				return false;

			if (tf.displayAsPassword)
				return true;

			try {
				if (game != null && "mcLogin" in game && game.mcLogin != null) {
					if (tf == game.mcLogin.ni || tf == game.mcLogin.pi || game.mcLogin.contains(tf)) {
						return true;
					}
				}
			}
			catch (e:Error) {
			}

			var tfName:String = (tf.name != null) ? tf.name.toLowerCase() : "";
			if (tfName == "ni" || tfName == "pi" || tfName.indexOf("user") != -1 || tfName.indexOf("pass") != -1 || tfName.indexOf("login") != -1) {
				return true;
			}

			var curr:DisplayObject = tf.parent;
			while (curr != null) {
				var pName:String = (curr.name != null) ? curr.name.toLowerCase() : "";
				if (pName.indexOf("login") != -1 || pName.indexOf("accountmanager") != -1) {
					return true;
				}
				curr = curr.parent;
			}

			return false;
		}

		private function isChatInput(tf:TextField):Boolean {
			if (tf == null)
				return false;

			try {
				if (game != null && game.ui != null && game.ui.mcInterface != null) {
					if (tf == game.ui.mcInterface.te || tf == game.ui.mcInterface.ncText) {
						return true;
					}
				}
			}
			catch (e:Error) {
			}

			if (tf.name == "te" || tf.name == "ncText") {
				return true;
			}

			return false;
		}

		private function shouldShowFor(tf:TextField):Boolean {
			if (tf == null || tf.type != TextFieldType.INPUT) {
				return false;
			}

			// Don't activate for our own preview textfield if it ever were to receive focus
			if (tf == previewTf) {
				return false;
			}

			// Never show on login UI or before entering the game world
			if (!isInGame()) {
				return false;
			}

			// Never show for login or password fields
			if (isLoginField(tf)) {
				return false;
			}

			// Always activate for game chat input
			if (isChatInput(tf)) {
				return true;
			}

			// Also activate for any in-game input field located in the lower portion of screen (which keyboard covers)
			try {
				var globalPt:Point = tf.localToGlobal(new Point(0, 0));
				if (globalPt.y > 200) {
					return true;
				}
			}
			catch (e:Error) {
			}

			return false;
		}

		private function onFocusIn(e:FocusEvent):void {
			if (hideTimeoutId != 0) {
				clearTimeout(hideTimeoutId);
				hideTimeoutId = 0;
			}

			var tf:TextField = e.target as TextField;
			if (shouldShowFor(tf)) {
				currentInput = tf;
				badgeLabel.text = isChatInput(tf) ? "💬 Chat" : "✏️ Input";
				lastText = currentInput.text;
				show();
			}
		}

		private function onFocusOut(e:FocusEvent):void {
			if (hideTimeoutId != 0) {
				clearTimeout(hideTimeoutId);
			}

			// Slight delay to prevent flickering when clicking internal preview buttons (Clear / Send)
			hideTimeoutId = setTimeout(function():void {
					hideTimeoutId = 0;
					if (stage == null || stage.focus == null || !shouldShowFor(stage.focus as TextField)) {
						hide();
					}
				}, 180);
		}

		private function onKeyDown(e:KeyboardEvent):void {
			if (!visible || currentInput == null)
				return;

			if (e.keyCode == Keyboard.ENTER) {
				// After brief delay allowing AQW to process the chat submission
				setTimeout(function():void {
						if (currentInput == null || currentInput.text == "" || stage == null || stage.focus != currentInput) {
							hide();
						}
						else {
							updateTextDisplay();
						}
					}, 120);
			}
		}

		// =========================================================================
		// Real-time Text Synchronization & Cursor
		// =========================================================================

		private function show():void {
			updatePosition();
			this.visible = true;

			if (parent != null) {
				parent.setChildIndex(this, parent.numChildren - 1);
			}

			blinkTick = 0;
			cursorVisible = true;
			updateTextDisplay();

			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function hide():void {
			this.visible = false;
			currentInput = null;
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void {
			if (!visible || currentInput == null || !isInGame()) {
				hide();
				return;
			}

			// Ensure focus is still maintained
			if (stage != null && (stage.focus == null || stage.focus != currentInput)) {
				hide();
				return;
			}

			// Keep on top of display list if game adds any elements
			if (parent != null && parent.getChildIndex(this) < parent.numChildren - 1) {
				parent.setChildIndex(this, parent.numChildren - 1);
			}

			// Blinking cursor tick (every ~15 frames at 30fps = 500ms)
			blinkTick++;
			if (blinkTick >= 15) {
				blinkTick = 0;
				cursorVisible = !cursorVisible;
				updateTextDisplay();
			}

			// Check for text changes in real-time
			var rawText:String = currentInput.text;
			if (rawText != lastText) {
				lastText = rawText;
				updateTextDisplay();
			}
		}

		private function updateTextDisplay():void {
			if (currentInput == null)
				return;

			var raw:String = currentInput.text;
			var cursor:String = cursorVisible ? "▎" : "";

			if (raw.length == 0 || raw == "> ") {
				// Placeholder state
				previewTf.text = (raw.length > 0 ? raw : "") + cursor + " (Text preview...)";
				previewTf.textColor = 0x64748b;
			}
			else {
				// Active text state
				previewTf.text = raw + cursor;
				previewTf.textColor = 0xffffff;
			}

			// Auto scroll horizontally to show latest typed characters
			previewTf.scrollH = previewTf.maxScrollH;
		}

		// =========================================================================
		// Action Handlers (Clear & Send)
		// =========================================================================

		private function onClearClick(e:MouseEvent):void {
			if (currentInput != null) {
				try {
					currentInput.text = "";
					currentInput.dispatchEvent(new Event(Event.CHANGE));
				}
				catch (err:Error) {
				}

				lastText = "";
				updateTextDisplay();
			}
			e.stopImmediatePropagation();
		}

		private function onSendClick(e:MouseEvent):void {
			if (currentInput == null)
				return;

			var sent:Boolean = false;

			// Method 1: Click AQW's bsend button if available
			try {
				if (game != null && game.ui != null && game.ui.mcInterface != null && game.ui.mcInterface.bsend != null) {
					game.ui.mcInterface.bsend.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					sent = true;
				}
			}
			catch (err1:Error) {
			}

			// Method 2: If bsend not found, dispatch Enter key event to the input field
			if (!sent && currentInput != null) {
				try {
					currentInput.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 13, Keyboard.ENTER));
					currentInput.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 13, Keyboard.ENTER));
				}
				catch (err2:Error) {
				}
			}

			if (stage != null) {
				stage.focus = null;
			}

			hide();
			e.stopImmediatePropagation();
		}
	}
}
