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
		private static const ITEM_HEIGHT:Number = 22;
		private static const ITEM_SPACING:Number = 2;
		private static const SCROLLBAR_WIDTH:Number = 8;
		private static const LIST_Y:Number = 46;
		private static const LIST_HEIGHT:Number = UI_HEIGHT - LIST_Y - PADDING; // 302

		public static var instance:AppLogUI;
		private static var logBuffer:Array = [];

		private var modalBg:Shape;
		private var listContainer:Sprite;
		private var scrollContent:Sprite;
		private var emptyLabel:TextField;
		private var scrollbar:Sprite;
		private var scrollThumb:Sprite;
		private var isDragging:Boolean = false;
		private var dragStartY:Number = 0;
		private var thumbStartY:Number = 0;
		private var scrollY:Number = 0;
		private var maxScrollY:Number = 0;
		private var thumbHeight:Number = 30;

		private var errBtn:Sprite;
		private var botBtn:Sprite;
		private var gameBtn:Sprite;
		private var logBtn:Sprite;
		private var showErr:Boolean = true;
		private var showBot:Boolean = true;
		private var showGame:Boolean = true;
		private var showLog:Boolean = true;

		public static function log(msg:String, type:String = "log"):void {
			if (msg == null)
				return;

			var now:Date = new Date();
			var timeStr:String = pad2(now.hours) + ":" + pad2(now.minutes) + ":" + pad2(now.seconds);

			// Auto detect type if default "log" passed
			if (type == "log") {
				if (msg.indexOf("ERR") > -1 || msg.indexOf("Error") > -1 || msg.indexOf("Exception") > -1 || msg.indexOf("TypeError") > -1) {
					type = "error";
				}
				else if (msg.indexOf("WARN") > -1 || msg.indexOf("Warning") > -1) {
					type = "warn";
				}
				else if (msg.indexOf("[Game]") > -1 || msg.indexOf("[AQW]") > -1) {
					type = "game";
				}
			}

			// Clean single-line preview for the list item
			var preview:String = msg.replace(/[\r\n\t]+/g, " ");
			if (preview.length > 200) {
				preview = preview.substring(0, 200) + "...";
			}

			var entry:Object = {
					msg: preview,
					fullText: "[" + timeStr + "] " + msg,
					type: type,
					time: timeStr
				};

			logBuffer.push(entry);
			if (logBuffer.length > 250) {
				logBuffer.shift();
			}

			trace("[" + type.toUpperCase() + "] [" + timeStr + "] " + msg);

			if (instance != null) {
				instance.refresh();
			}
		}

		public static function error(msg:String):void {
			log(msg, "error");
		}

		public static function warn(msg:String):void {
			log(msg, "warn");
		}

		public static function bot(msg:String):void {
			log(msg, "bot");
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
				instance.refresh();
			}
		}

		public function AppLogUI() {
			instance = this;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			buildUI();
			refresh();

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
			// Background panel
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

			// Title
			const titleTf:TextField = createLabel("App Logs", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 65;
			headerBar.addChild(titleTf);

			// Filter Buttons in Header
			errBtn = createToggleButton("Error", 82, 7, 48, 22, 0xef4444, 0xdc2626, 0xfca5a5, function(val:Boolean):void {
					showErr = val;
					refresh();
				}, true);
			headerBar.addChild(errBtn);

			botBtn = createToggleButton("Bot", 136, 7, 44, 22, 0x2563eb, 0x1d4ed8, 0x93c5fd, function(val:Boolean):void {
					showBot = val;
					refresh();
				}, true);
			headerBar.addChild(botBtn);

			gameBtn = createToggleButton("Game", 186, 7, 48, 22, 0x7c3aed, 0x6d28d9, 0xc4b5fd, function(val:Boolean):void {
					showGame = val;
					refresh();
				}, true);
			headerBar.addChild(gameBtn);

			logBtn = createToggleButton("Log", 240, 7, 42, 22, 0x059669, 0x047857, 0x34d399, function(val:Boolean):void {
					showLog = val;
					refresh();
				}, true);
			headerBar.addChild(logBtn);

			// Copy All Button
			const copyAllBtn:Sprite = createHeaderButton("Copy All", 58, 22);
			copyAllBtn.x = UI_WIDTH - PADDING - 22 - 6 - 46 - 6 - 58; // 410
			copyAllBtn.y = 7;
			copyAllBtn.addEventListener(MouseEvent.CLICK, onCopyAllClick);
			headerBar.addChild(copyAllBtn);

			// Clear Button
			const clearBtn:Sprite = createHeaderButton("Clear", 46, 22);
			clearBtn.x = UI_WIDTH - PADDING - 22 - 6 - 46; // 474
			clearBtn.y = 7;
			clearBtn.addEventListener(MouseEvent.CLICK, onClearClick);
			headerBar.addChild(clearBtn);

			// Close Button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22; // 526
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (parent != null) {
						parent.removeChild(instance);
					}
				});
			headerBar.addChild(closeBtn);

			// Recessed Log Container Box
			const listBox:Shape = new Shape();
			drawRoundedRect(listBox.graphics, PADDING, LIST_Y, UI_WIDTH - PADDING * 2, LIST_HEIGHT, 6, 0x070b14, 0.95, 0x1e293b, 1);
			addChild(listBox);

			listContainer = new Sprite();
			listContainer.x = PADDING + 6;
			listContainer.y = LIST_Y + 6;
			addChild(listContainer);

			const listContentWidth:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4;
			const listContentHeight:Number = LIST_HEIGHT - 12;

			// Mask
			const mask:Shape = new Shape();
			mask.graphics.beginFill(0x000000);
			mask.graphics.drawRect(0, 0, listContentWidth, listContentHeight);
			mask.graphics.endFill();
			listContainer.addChild(mask);

			// Scroll content
			scrollContent = new Sprite();
			scrollContent.mask = mask;
			listContainer.addChild(scrollContent);

			// Empty label
			emptyLabel = createLabel("No logs captured yet.\nErrors, bot actions, game events, and output will appear here.", 0x64748b, 10.5, false, TextFormatAlign.CENTER);
			emptyLabel.x = PADDING;
			emptyLabel.y = LIST_Y + int(LIST_HEIGHT / 2) - 16;
			emptyLabel.width = UI_WIDTH - PADDING * 2;
			emptyLabel.height = 40;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;
			addChild(emptyLabel);

			// Mouse wheel support
			listContainer.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

			// Scrollbar
			scrollbar = new Sprite();
			scrollbar.x = UI_WIDTH - PADDING - 6 - SCROLLBAR_WIDTH;
			scrollbar.y = LIST_Y + 6;
			scrollbar.visible = false;
			addChild(scrollbar);

			const trackBg:Shape = new Shape();
			drawRoundedRect(trackBg.graphics, 0, 0, SCROLLBAR_WIDTH, listContentHeight, 4, 0x070b14, 0.5);
			scrollbar.addChild(trackBg);

			scrollThumb = new Sprite();
			const thumbBg:Shape = new Shape();
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, 30, 4, 0x334155, 0.9);
			scrollThumb.addChild(thumbBg);
			scrollThumb.buttonMode = true;
			scrollThumb.useHandCursor = true;
			scrollbar.addChild(scrollThumb);

			scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
			scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver);
			scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut);
		}

		private function onMouseWheel(e:MouseEvent):void {
			if (maxScrollY > 0) {
				scrollY -= e.delta * 22;
				scrollY = Math.max(0, Math.min(maxScrollY, scrollY));
				updateScrollPosition();
			}
		}

		public function refresh():void {
			if (scrollContent == null)
				return;

			while (scrollContent.numChildren > 0) {
				scrollContent.removeChildAt(0);
			}

			// Filter items
			var visibleItems:Array = [];
			for each (var entry:Object in logBuffer) {
				if (entry.type == "error" && !showErr)
					continue;
				if (entry.type == "bot" && !showBot)
					continue;
				if (entry.type == "game" && !showGame)
					continue;
				if ((entry.type == "log" || entry.type == "warn") && !showLog)
					continue;
				visibleItems.push(entry);
			}

			emptyLabel.visible = (visibleItems.length == 0);

			const listContentWidth:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4;
			const listContentHeight:Number = LIST_HEIGHT - 12;
			const totalHeight:Number = visibleItems.length * (ITEM_HEIGHT + ITEM_SPACING);

			for (var i:int = 0; i < visibleItems.length; i++) {
				const itemData:Object = visibleItems[i];
				const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);

				const item:Sprite = new Sprite();
				item.y = itemY;

				const itemBg:Shape = new Shape();
				drawRoundedRect(itemBg.graphics, 0, 0, listContentWidth, ITEM_HEIGHT, 3, 0x0f172a, 0.6, 0x1e293b, 1);
				item.addChild(itemBg);

				// Badge Configuration
				var badgeColor:uint = 0x059669;
				var badgeTextColor:uint = 0x4ade80;
				var badgeText:String = "LOG";
				var textColor:uint = 0x86efac;

				if (itemData.type == "error") {
					badgeColor = 0xef4444;
					badgeTextColor = 0xfca5a5;
					badgeText = "ERR";
					textColor = 0xfca5a5;
				}
				else if (itemData.type == "warn") {
					badgeColor = 0xf59e0b;
					badgeTextColor = 0xfcd34d;
					badgeText = "WARN";
					textColor = 0xfef08a;
				}
				else if (itemData.type == "bot") {
					badgeColor = 0x2563eb;
					badgeTextColor = 0x93c5fd;
					badgeText = "BOT";
					textColor = 0xbfdbfe;
				}
				else if (itemData.type == "game") {
					badgeColor = 0x7c3aed;
					badgeTextColor = 0xc4b5fd;
					badgeText = "GAME";
					textColor = 0xd8b4fe;
				}

				const badge:Sprite = new Sprite();
				const badgeBg:Shape = new Shape();
				drawRoundedRect(badgeBg.graphics, 0, 0, 32, 16, 3, badgeColor, 0.35, badgeColor, 1);
				badge.addChild(badgeBg);
				const badgeTf:TextField = createLabel(badgeText, badgeTextColor, 8.5, true, TextFormatAlign.CENTER);
				badgeTf.width = 32;
				badgeTf.height = 16;
				badgeTf.y = 1;
				badge.addChild(badgeTf);
				badge.x = 4;
				badge.y = 3;
				item.addChild(badge);

				// Timestamp + Log Message Content
				const labelText:String = "[" + itemData.time + "] " + itemData.msg;
				const label:TextField = createLabel(labelText, textColor, 9.5, false);
				label.width = listContentWidth - 42 - 44;
				label.height = ITEM_HEIGHT;
				label.x = 40;
				label.y = 3;
				item.addChild(label);

				// Per-item Copy Button
				const copyBtn:Sprite = new Sprite();
				copyBtn.buttonMode = true;
				copyBtn.useHandCursor = true;

				const copyBg:Shape = new Shape();
				drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x1e293b, 1.0, 0x334155, 1);
				copyBtn.addChild(copyBg);

				const copyTf:TextField = createLabel("Copy", 0x94a3b8, 8.5, true, TextFormatAlign.CENTER);
				copyTf.width = 36;
				copyTf.height = 16;
				copyTf.y = 1;
				copyBtn.addChild(copyTf);

				copyBtn.x = listContentWidth - 40;
				copyBtn.y = 3;

				copyBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x334155, 1.0, 0x475569, 1);
						copyTf.textColor = 0xffffff;
					});

				copyBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x1e293b, 1.0, 0x334155, 1);
						copyTf.textColor = 0x94a3b8;
					});

				copyBtn.addEventListener(MouseEvent.CLICK, createCopyHandler(itemData.fullText, copyTf));
				item.addChild(copyBtn);

				scrollContent.addChild(item);
			}

			// Scrollbar Calculation
			if (totalHeight > listContentHeight) {
				maxScrollY = totalHeight - listContentHeight;
				thumbHeight = Math.max(24, (listContentHeight / totalHeight) * listContentHeight);

				const tBg:Shape = Shape(scrollThumb.getChildAt(0));
				drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);

				scrollbar.visible = true;
				scrollY = maxScrollY; // Auto-scroll to latest entry
			}
			else {
				scrollbar.visible = false;
				scrollY = 0;
				maxScrollY = 0;
			}
			updateScrollPosition();
		}

		private function updateScrollPosition():void {
			scrollContent.y = -scrollY;
			if (maxScrollY > 0) {
				const listContentHeight:Number = LIST_HEIGHT - 12;
				const maxThumbY:Number = listContentHeight - thumbHeight;
				scrollThumb.y = (scrollY / maxScrollY) * maxThumbY;
			}
		}

		private function onThumbMouseDown(e:MouseEvent):void {
			isDragging = true;
			dragStartY = e.stageY;
			thumbStartY = scrollThumb.y;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			e.stopImmediatePropagation();
		}

		private function onStageMouseMove(e:MouseEvent):void {
			if (!isDragging)
				return;
			const listContentHeight:Number = LIST_HEIGHT - 12;
			const deltaY:Number = e.stageY - dragStartY;
			var newThumbY:Number = thumbStartY + deltaY;
			const maxThumbY:Number = listContentHeight - thumbHeight;
			newThumbY = Math.max(0, Math.min(newThumbY, maxThumbY));
			scrollY = (newThumbY / maxThumbY) * maxScrollY;
			updateScrollPosition();
		}

		private function onStageMouseUp(e:MouseEvent):void {
			isDragging = false;
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			}
		}

		private function onThumbRollOver(e:MouseEvent):void {
			const tBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x475569, 1.0);
		}

		private function onThumbRollOut(e:MouseEvent):void {
			const tBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);
		}

		private function onCopyAllClick(e:MouseEvent):void {
			if (logBuffer.length == 0)
				return;

			var allText:Array = [];
			for each (var entry:Object in logBuffer) {
				allText.push(entry.fullText);
			}

			System.setClipboard(allText.join("\n"));
			var btn:Sprite = Sprite(e.currentTarget);
			var tf:TextField = TextField(btn.getChildAt(1));
			tf.text = "Copied";
			tf.textColor = 0x4ade80;
			var timer:Timer = new Timer(1200, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent):void {
					tf.text = "Copy All";
					tf.textColor = 0x94a3b8;
				});
			timer.start();
		}

		private function onClearClick(e:MouseEvent):void {
			logBuffer.length = 0;
			refresh();
		}

		private function createCopyHandler(textToCopy:String, btnTf:TextField):Function {
			return function(e:MouseEvent):void {
				System.setClipboard(textToCopy);
				btnTf.text = "Done";
				btnTf.textColor = 0x4ade80;
				var timer:Timer = new Timer(1200, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent):void {
						btnTf.text = "Copy";
						btnTf.textColor = 0x94a3b8;
					});
				timer.start();
			};
		}

		private function createToggleButton(
				label:String,
				px:Number,
				py:Number,
				w:Number,
				h:Number,
				activeBg:uint,
				activeBorder:uint,
				activeText:uint,
				callback:Function,
				defaultActive:Boolean = true
			):Sprite {
			const btn:Sprite = new Sprite();
			btn.x = px;
			btn.y = py;
			btn.buttonMode = true;
			btn.useHandCursor = true;

			var active:Boolean = defaultActive;

			const bg:Shape = new Shape();
			if (active) {
				drawRoundedRect(bg.graphics, 0, 0, w, h, 4, activeBg, 1.0, activeBorder, 1);
			}
			else {
				drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
			}
			btn.addChild(bg);

			const tf:TextField = createLabel(label, active ? 0xffffff : 0x94a3b8, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 14) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					active = !active;
					if (active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, activeBg, 1.0, activeBorder, 1);
						tf.textColor = 0xffffff;
					}
					else {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
						tf.textColor = 0x94a3b8;
					}
					callback(active);
				});

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					if (!active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x475569, 1);
						tf.textColor = 0xffffff;
					}
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					if (!active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
						tf.textColor = 0x94a3b8;
					}
				});

			return btn;
		}

		private function createHeaderButton(label:String, w:Number, h:Number):Sprite {
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
