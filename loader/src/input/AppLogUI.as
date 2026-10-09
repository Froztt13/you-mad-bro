package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.system.System;
	import flash.text.*;
	import flash.utils.Timer;

	import ui.CloseButton;

	public class AppLogUI extends Sprite {

		private static const UI_WIDTH:Number = 560;
		private static const UI_HEIGHT:Number = 360;
		private static const PADDING:Number = 12;
		private static const HEADER_HEIGHT:Number = 36;
		private static const SCROLLBAR_WIDTH:Number = 8;
		private static const LIST_Y:Number = 46;
		private static const LIST_HEIGHT:Number = UI_HEIGHT - LIST_Y - PADDING; // 302

		public static var instance:AppLogUI;
		private static var logBuffer:Array = [];

		private var modalBg:Shape;
		private var logField:TextField;
		private var scrollbar:Sprite;
		private var scrollThumb:Sprite;
		private var isDraggingThumb:Boolean = false;
		private var dragStartY:Number = 0;
		private var thumbStartY:Number = 0;

		public static function log(msg:String):void {
			var now:Date = new Date();
			var timeStr:String = pad2(now.hours) + ":" + pad2(now.minutes) + ":" + pad2(now.seconds);
			var entry:String = "[" + timeStr + "] " + msg;

			logBuffer.push(entry);
			if (logBuffer.length > 500) {
				logBuffer.shift();
			}

			trace(entry);

			if (instance != null && instance.logField != null) {
				instance.logField.appendText(entry + "\n");
				instance.logField.scrollV = instance.logField.maxScrollV;
				instance.updateScrollbar();
			}
		}

		private static function pad2(n:int):String {
			return (n < 10) ? "0" + n : String(n);
		}

		public static function toggle(parentContainer:DisplayObjectContainer = null):void {
			if (instance == null) {
				instance = new AppLogUI();
			}

			if (instance.parent != null) {
				instance.parent.removeChild(instance);
			}
			else if (parentContainer != null) {
				parentContainer.addChild(instance);
				instance.visible = true;
				if (instance.stage != null) {
					instance.x = Math.max(10, (instance.stage.stageWidth - UI_WIDTH) / 2);
					instance.y = Math.max(10, (instance.stage.stageHeight - UI_HEIGHT) / 2);
				}
			}
		}

		public function AppLogUI() {
			instance = this;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			buildUI();
			populateInitialLogs();

			x = Math.max(10, (stage.stageWidth - UI_WIDTH) / 2);
			y = Math.max(10, (stage.stageHeight - UI_HEIGHT) / 2);

			addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown);
		}

		private function onPanelMouseDown(e:MouseEvent):void {
			if (e.target == this || e.target == modalBg) {
				startDrag();
				stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
			}
		}

		private function onPanelMouseUp(e:MouseEvent):void {
			stopDrag();
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
			}
		}

		private function buildUI():void {
			// Background
			modalBg = new Shape();
			drawRoundedRect(modalBg.graphics, 0, 0, UI_WIDTH, UI_HEIGHT, 8, 0x0f172a, 0.98, 0x334155, 1);
			modalBg.filters = [new DropShadowFilter(12, 90, 0x000000, 0.7, 18, 18)];
			addChild(modalBg);

			// Header Bar (Draggable)
			const headerBar:Sprite = new Sprite();
			headerBar.graphics.beginFill(0x0a0e1a, 0.98);
			headerBar.graphics.drawRoundRectComplex(0, 0, UI_WIDTH, HEADER_HEIGHT, 8, 8, 0, 0);
			headerBar.graphics.endFill();
			headerBar.graphics.lineStyle(1, 0x1e293b, 1);
			headerBar.graphics.moveTo(0, HEADER_HEIGHT);
			headerBar.graphics.lineTo(UI_WIDTH, HEADER_HEIGHT);
			addChild(headerBar);

			headerBar.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					startDrag();
					stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
				});

			// Title & Subtitle
			const titleTf:TextField = createLabel("Console Log", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 95;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Live Output", 0x64748b, 9.5, false);
			subTf.x = 108;
			subTf.y = 11;
			subTf.width = 80;
			headerBar.addChild(subTf);

			// Copy button
			const copyBtn:Sprite = createHeaderBtn("Copy", 48, 22);
			copyBtn.x = UI_WIDTH - PADDING - 22 - 6 - 48 - 6 - 48; // 418
			copyBtn.y = 7;
			copyBtn.addEventListener(MouseEvent.CLICK, onCopyClick);
			headerBar.addChild(copyBtn);

			// Clear button
			const clearBtn:Sprite = createHeaderBtn("Clear", 48, 22);
			clearBtn.x = UI_WIDTH - PADDING - 22 - 6 - 48; // 472
			clearBtn.y = 7;
			clearBtn.addEventListener(MouseEvent.CLICK, onClearClick);
			headerBar.addChild(clearBtn);

			// Close button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22; // 526
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (parent != null) {
						parent.removeChild(instance);
					}
				});
			headerBar.addChild(closeBtn);

			// Recessed Container Box
			const logBox:Shape = new Shape();
			drawRoundedRect(logBox.graphics, PADDING, LIST_Y, UI_WIDTH - PADDING * 2, LIST_HEIGHT, 6, 0x070b14, 0.95, 0x1e293b, 1);
			addChild(logBox);

			// Log text field area
			const fieldWidth:Number = UI_WIDTH - (PADDING * 2) - 12 - SCROLLBAR_WIDTH - 4;
			const fieldHeight:Number = LIST_HEIGHT - 12;

			logField = new TextField();
			logField.defaultTextFormat = new TextFormat("_typewriter", 10.5, 0x4ade80);
			logField.x = PADDING + 6;
			logField.y = LIST_Y + 6;
			logField.width = fieldWidth;
			logField.height = fieldHeight;
			logField.multiline = true;
			logField.wordWrap = true;
			logField.selectable = true;
			logField.background = false;
			logField.border = false;
			logField.addEventListener(Event.SCROLL, onFieldScroll);
			addChild(logField);

			// Scrollbar
			scrollbar = new Sprite();
			scrollbar.x = UI_WIDTH - PADDING - 6 - SCROLLBAR_WIDTH;
			scrollbar.y = LIST_Y + 6;
			scrollbar.visible = false;
			addChild(scrollbar);

			const track:Shape = new Shape();
			drawRoundedRect(track.graphics, 0, 0, SCROLLBAR_WIDTH, fieldHeight, 4, 0x070b14, 0.5);
			scrollbar.addChild(track);

			scrollThumb = new Sprite();
			const thumbShape:Shape = new Shape();
			drawRoundedRect(thumbShape.graphics, 0, 0, SCROLLBAR_WIDTH, 30, 4, 0x334155, 0.9);
			scrollThumb.addChild(thumbShape);
			scrollThumb.buttonMode = true;
			scrollThumb.useHandCursor = true;
			scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
			scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver);
			scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut);
			scrollbar.addChild(scrollThumb);
		}

		private function populateInitialLogs():void {
			if (logField == null)
				return;
			logField.text = logBuffer.join("\n") + (logBuffer.length > 0 ? "\n" : "");
			logField.scrollV = logField.maxScrollV;
			updateScrollbar();
		}

		private function onCopyClick(e:MouseEvent):void {
			if (logField != null && logField.text.length > 0) {
				System.setClipboard(logField.text);
				var btn:Sprite = Sprite(e.currentTarget);
				var tf:TextField = TextField(btn.getChildAt(1));
				tf.text = "Copied";
				tf.textColor = 0x4ade80;
				var timer:Timer = new Timer(1200, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent):void {
						tf.text = "Copy";
						tf.textColor = 0x94a3b8;
					});
				timer.start();
			}
		}

		private function onClearClick(e:MouseEvent):void {
			logBuffer.length = 0;
			if (logField != null) {
				logField.text = "";
				updateScrollbar();
			}
		}

		private function onFieldScroll(e:Event):void {
			updateScrollbar();
		}

		private function updateScrollbar():void {
			if (logField == null || scrollbar == null || scrollThumb == null)
				return;

			var totalLines:int = logField.maxScrollV + logField.bottomScrollV - logField.scrollV;
			var visibleLines:int = logField.bottomScrollV - logField.scrollV + 1;

			if (logField.maxScrollV <= 1) {
				scrollbar.visible = false;
				return;
			}

			scrollbar.visible = true;
			var trackH:Number = LIST_HEIGHT - 12;
			var thumbH:Number = Math.max(24, (visibleLines / totalLines) * trackH);

			var thumbBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbH, 4, 0x334155, 0.9);

			var maxScroll:int = logField.maxScrollV;
			var progress:Number = (logField.scrollV - 1) / Math.max(1, maxScroll - 1);
			scrollThumb.y = progress * (trackH - thumbH);
		}

		private function onThumbMouseDown(e:MouseEvent):void {
			isDraggingThumb = true;
			dragStartY = stage.mouseY;
			thumbStartY = scrollThumb.y;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onThumbMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);
			e.stopPropagation();
		}

		private function onThumbMouseMove(e:MouseEvent):void {
			if (!isDraggingThumb)
				return;

			var trackH:Number = LIST_HEIGHT - 12;
			var thumbH:Number = scrollThumb.height;
			var maxThumbY:Number = trackH - thumbH;
			var deltaY:Number = stage.mouseY - dragStartY;
			var newY:Number = Math.max(0, Math.min(maxThumbY, thumbStartY + deltaY));
			scrollThumb.y = newY;

			var progress:Number = (maxThumbY > 0) ? newY / maxThumbY : 0;
			logField.scrollV = 1 + Math.round(progress * (logField.maxScrollV - 1));
		}

		private function onThumbMouseUp(e:MouseEvent):void {
			isDraggingThumb = false;
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);
			}
		}

		private function onThumbRollOver(e:MouseEvent):void {
			var thumbBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, scrollThumb.height, 4, 0x475569, 1.0);
		}

		private function onThumbRollOut(e:MouseEvent):void {
			var thumbBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, scrollThumb.height, 4, 0x334155, 0.9);
		}

		private static function createHeaderBtn(label:String, w:Number, h:Number):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
			btn.addChild(bg);

			const tf:TextField = createLabel(label, 0x94a3b8, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 14) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x475569, 1);
					tf.textColor = 0xffffff;
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
					tf.textColor = 0x94a3b8;
				});

			return btn;
		}

		private static function createLabel(text:String, color:uint, size:Number, bold:Boolean = false, align:String = TextFormatAlign.LEFT):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, align);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
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
