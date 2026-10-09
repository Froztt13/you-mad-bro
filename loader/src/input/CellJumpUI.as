package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	import engine.MapCommands;
	import ui.CloseButton;
	import ui.ScrollContainer;

	public class CellJumpUI extends Sprite {

		private static const UI_WIDTH:Number = 360;
		private static const UI_HEIGHT:Number = 280;
		private static const PADDING:Number = 12;
		private static const HEADER_HEIGHT:Number = 36;
		private static const ITEM_HEIGHT:Number = 22;
		private static const ITEM_SPACING:Number = 2;
		private static const SCROLLBAR_WIDTH:Number = 10;
		private static const COL_WIDTH:Number = 163; // (360 - 24 - 10) / 2
		private static const LIST_Y:Number = 62;
		private static const LIST_HEIGHT:Number = UI_HEIGHT - LIST_Y - PADDING; // 206

		private var mapCommands:MapCommands;
		private var modalBg:Shape;

		// Cell & Pad scroll containers
		private var cellScroll:ScrollContainer;
		private var padScroll:ScrollContainer;

		// State & Polling components
		private var currentCellName:String = "";
		private var currentPadName:String = "";
		private var currentAvailablePads:Array = [];
		private var pollTimer:Timer;
		private var padRefreshTimer:Timer;
		private var lastKnownCell:String = "";
		private var lastKnownPad:String = "";
		private var lastKnownPadsHash:String = "";
		private var pendingPadCorrection:Boolean = false;
		private var targetJumpCell:String = "";

		public function CellJumpUI(mapCommands:MapCommands) {
			this.mapCommands = mapCommands;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}

		private function onAddedToStage(e:Event):void {
			if (modalBg == null) {
				buildUI();
			}
			refresh();
			startPolling();
		}

		private function onRemovedFromStage(e:Event):void {
			stopPolling();
			if (padRefreshTimer != null && padRefreshTimer.running) {
				padRefreshTimer.stop();
			}
		}

		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (value) {
				startPolling();
				schedulePadRefresh();
			}
			else {
				stopPolling();
				if (padRefreshTimer != null && padRefreshTimer.running) {
					padRefreshTimer.stop();
				}
			}
		}

		private function onPanelMouseDown(e:MouseEvent):void {
			if (e.target == this || e.target == modalBg) {
				this.startDrag();
				stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
			}
		}

		private function onPanelMouseUp(e:MouseEvent):void {
			this.stopDrag();
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
			this.addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown);

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

			const titleTf:TextField = createLabel("Cell Jump", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 80;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Fast Travel", 0x64748b, 9.5, false);
			subTf.x = 86;
			subTf.y = 11;
			subTf.width = 80;
			headerBar.addChild(subTf);

			// Refresh button
			const refreshBtn:Sprite = new Sprite();
			refreshBtn.buttonMode = true;
			refreshBtn.useHandCursor = true;
			const refBg:Shape = new Shape();
			drawRoundedRect(refBg.graphics, 0, 0, 52, 22, 4, 0x1e293b, 1.0, 0x334155, 1);
			refreshBtn.addChild(refBg);

			const refLabel:TextField = createLabel("Refresh", 0x94a3b8, 9.5, true, TextFormatAlign.CENTER);
			refLabel.width = 52;
			refLabel.height = 22;
			refLabel.y = 4;
			refreshBtn.addChild(refLabel);

			refreshBtn.x = UI_WIDTH - PADDING - 22 - 6 - 52;
			refreshBtn.y = 7;
			refreshBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(refBg.graphics, 0, 0, 52, 22, 4, 0x334155, 1.0, 0x475569, 1);
					refLabel.textColor = 0xffffff;
				});
			refreshBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(refBg.graphics, 0, 0, 52, 22, 4, 0x1e293b, 1.0, 0x334155, 1);
					refLabel.textColor = 0x94a3b8;
				});
			refreshBtn.addEventListener(MouseEvent.CLICK, onRefreshClick, false, 0, true);
			headerBar.addChild(refreshBtn);

			// Close button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22;
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			headerBar.addChild(closeBtn);

			// --- Section Headers ---
			const cellHeader:TextField = createLabel("CELLS", 0x64748b, 9.5, true);
			cellHeader.x = PADDING;
			cellHeader.y = 44;
			cellHeader.width = COL_WIDTH;
			addChild(cellHeader);

			const padHeader:TextField = createLabel("PADS", 0x64748b, 9.5, true);
			padHeader.x = PADDING + COL_WIDTH + 10;
			padHeader.y = 44;
			padHeader.width = COL_WIDTH;
			addChild(padHeader);

			// --- Cell List Box & Scroll Container ---
			cellScroll = new ScrollContainer(COL_WIDTH, LIST_HEIGHT, SCROLLBAR_WIDTH, true, 4, 4);
			cellScroll.x = PADDING;
			cellScroll.y = LIST_Y;
			addChild(cellScroll);

			// --- Pad List Box & Scroll Container ---
			const padBoxX:Number = PADDING + COL_WIDTH + 10;
			padScroll = new ScrollContainer(COL_WIDTH, LIST_HEIGHT, SCROLLBAR_WIDTH, true, 4, 4);
			padScroll.x = padBoxX;
			padScroll.y = LIST_Y;
			addChild(padScroll);

			// Center position on stage if unassigned
			if (stage != null && x == 0 && y == 0) {
				x = (stage.stageWidth - UI_WIDTH) / 2;
				y = (stage.stageHeight - UI_HEIGHT) / 2;
			}
		}

		public function refresh():void {
			refreshCells();
			refreshPads();
		}

		private function refreshCells():void {
			try {
				var json:String = mapCommands != null ? mapCommands.getCells() : "[]";
				var cells:Array = JSON.parse(json) as Array;
				if (cells == null)
					cells = [];
				var currentCell:String = mapCommands != null ? mapCommands.getMyCell() : "";
				currentCellName = currentCell;
				lastKnownCell = currentCell;

				var savedScrollY:Number = cellScroll != null ? cellScroll.scrollY : 0;

				cellScroll.clearContent();

				const itemW:Number = cellScroll.contentWidth;
				for (var i:int = 0; i < cells.length; i++) {
					const cell:String = cells[i];
					const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);
					const isCurrent:Boolean = (cell.toLowerCase() == currentCell.toLowerCase());

					const item:Sprite = new Sprite();
					item.y = itemY;
					item.buttonMode = true;
					item.useHandCursor = true;
					item.name = cell;

					const bgCol:uint = isCurrent ? 0x1d4ed8 : 0x0f172a;
					const borderCol:uint = isCurrent ? 0x3b82f6 : 0x1e293b;
					const textCol:uint = isCurrent ? 0xffffff : 0xcbd5e1;

					const itemBg:Shape = new Shape();
					drawRoundedRect(itemBg.graphics, 0, 0, itemW, ITEM_HEIGHT, 4, bgCol, 0.9, borderCol, 1);
					item.addChild(itemBg);

					const label:TextField = createLabel(cell, textCol, 10, isCurrent);
					label.width = itemW - 12;
					label.height = ITEM_HEIGHT;
					label.x = 8;
					label.y = 3;
					item.addChild(label);

					item.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
							var targetItem:Sprite = Sprite(e.currentTarget);
							if (targetItem.name.toLowerCase() != currentCellName.toLowerCase()) {
								var bg:Shape = Shape(targetItem.getChildAt(0));
								drawRoundedRect(bg.graphics, 0, 0, cellScroll.contentWidth, ITEM_HEIGHT, 4, 0x1e293b, 1.0, 0x334155, 1);
								var lbl:TextField = TextField(targetItem.getChildAt(1));
								lbl.textColor = 0xffffff;
							}
						});

					item.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
							var targetItem:Sprite = Sprite(e.currentTarget);
							if (targetItem.name.toLowerCase() != currentCellName.toLowerCase()) {
								var bg:Shape = Shape(targetItem.getChildAt(0));
								drawRoundedRect(bg.graphics, 0, 0, cellScroll.contentWidth, ITEM_HEIGHT, 4, 0x0f172a, 0.9, 0x1e293b, 1);
								var lbl:TextField = TextField(targetItem.getChildAt(1));
								lbl.textColor = 0xcbd5e1;
							}
						});

					item.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
							var clickedItem:Sprite = Sprite(e.currentTarget);
							var targetCell:String = clickedItem.name;
							var currentPad:String = (mapCommands != null) ? mapCommands.getMyPad() : "Spawn";
							if (currentPad == null || currentPad.length == 0)
								currentPad = "Spawn";

							if (mapCommands != null) {
								mapCommands.jump(targetCell, currentPad);
							}

							lastKnownCell = targetCell;
							targetJumpCell = targetCell;
							pendingPadCorrection = true;
							updateCellHighlight(targetCell);

							schedulePadRefresh();
						});

					cellScroll.addItem(item);
				}

				cellScroll.updateScroll(cells.length * (ITEM_HEIGHT + ITEM_SPACING));
				cellScroll.scrollY = savedScrollY;
			}
			catch (error:Error) {
				// safe fail
			}
		}

		private function updateCellHighlight(activeCell:String):void {
			if (activeCell == null || activeCell.length == 0)
				return;
			currentCellName = activeCell;
			if (cellScroll == null || cellScroll.content == null)
				return;

			const itemW:Number = cellScroll.contentWidth;
			for (var i:int = 0; i < cellScroll.content.numChildren; i++) {
				var item:Sprite = cellScroll.content.getChildAt(i) as Sprite;
				if (item == null)
					continue;

				var isCurrent:Boolean = (item.name.toLowerCase() == activeCell.toLowerCase());
				var bgCol:uint = isCurrent ? 0x1d4ed8 : 0x0f172a;
				var borderCol:uint = isCurrent ? 0x3b82f6 : 0x1e293b;
				var textCol:uint = isCurrent ? 0xffffff : 0xcbd5e1;

				if (item.numChildren > 0) {
					var bg:Shape = item.getChildAt(0) as Shape;
					if (bg != null) {
						drawRoundedRect(bg.graphics, 0, 0, itemW, ITEM_HEIGHT, 4, bgCol, 0.9, borderCol, 1);
					}
				}
				if (item.numChildren > 1) {
					var lbl:TextField = item.getChildAt(1) as TextField;
					if (lbl != null) {
						lbl.textColor = textCol;
						var fmt:TextFormat = lbl.defaultTextFormat;
						fmt.bold = isCurrent;
						lbl.defaultTextFormat = fmt;
						lbl.setTextFormat(fmt);
					}
				}
			}
		}

		private function refreshPads():void {
			try {
				const pads:Array = ["Center", "Spawn", "Left", "Right", "Top", "Bottom", "Up", "Down"];
				const currentPad:String = mapCommands != null ? mapCommands.getMyPad() : "";
				currentPadName = currentPad;
				lastKnownPad = currentPad;

				var availablePads:Array = mapCommands != null ? mapCommands.getAvailablePads() : [];
				if (availablePads == null)
					availablePads = [];
				currentAvailablePads = availablePads;
				lastKnownPadsHash = availablePads.join(",");

				padScroll.clearContent();

				const itemW:Number = padScroll.contentWidth;
				for (var i:int = 0; i < pads.length; i++) {
					const pad:String = pads[i];
					const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);
					const isCurrent:Boolean = (pad.toLowerCase() == currentPad.toLowerCase());
					const isAvailable:Boolean = (availablePads.indexOf(pad.toLowerCase()) != -1);

					const item:Sprite = new Sprite();
					item.y = itemY;
					item.buttonMode = true;
					item.useHandCursor = true;
					item.name = pad;

					var bgCol:uint = 0x0f172a;
					var borderCol:uint = 0x1e293b;
					var textCol:uint = 0x94a3b8;

					if (isCurrent) {
						bgCol = 0x1d4ed8;
						borderCol = 0x3b82f6;
						textCol = 0xffffff;
					}
					else if (isAvailable) {
						bgCol = 0x064e3b;
						borderCol = 0x059669;
						textCol = 0xa7f3d0;
					}

					const itemBg:Shape = new Shape();
					drawRoundedRect(itemBg.graphics, 0, 0, itemW, ITEM_HEIGHT, 4, bgCol, 0.9, borderCol, 1);
					item.addChild(itemBg);

					const label:TextField = createLabel(pad, textCol, 10, isCurrent);
					label.width = itemW - 12;
					label.height = ITEM_HEIGHT;
					label.x = 8;
					label.y = 3;
					item.addChild(label);

					item.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
							var targetItem:Sprite = Sprite(e.currentTarget);
							if (targetItem.name.toLowerCase() != currentPadName.toLowerCase()) {
								var bg:Shape = Shape(targetItem.getChildAt(0));
								var isAv:Boolean = (currentAvailablePads.indexOf(targetItem.name.toLowerCase()) != -1);
								var hoverBg:uint = isAv ? 0x047857 : 0x1e293b;
								var hoverBorder:uint = isAv ? 0x10b981 : 0x334155;
								drawRoundedRect(bg.graphics, 0, 0, padScroll.contentWidth, ITEM_HEIGHT, 4, hoverBg, 1.0, hoverBorder, 1);
								var lbl:TextField = TextField(targetItem.getChildAt(1));
								lbl.textColor = 0xffffff;
							}
						});

					item.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
							var targetItem:Sprite = Sprite(e.currentTarget);
							if (targetItem.name.toLowerCase() != currentPadName.toLowerCase()) {
								var bg:Shape = Shape(targetItem.getChildAt(0));
								var isAv:Boolean = (currentAvailablePads.indexOf(targetItem.name.toLowerCase()) != -1);
								var baseBg:uint = isAv ? 0x064e3b : 0x0f172a;
								var baseBorder:uint = isAv ? 0x059669 : 0x1e293b;
								var baseText:uint = isAv ? 0xa7f3d0 : 0x94a3b8;
								drawRoundedRect(bg.graphics, 0, 0, padScroll.contentWidth, ITEM_HEIGHT, 4, baseBg, 0.9, baseBorder, 1);
								var lbl:TextField = TextField(targetItem.getChildAt(1));
								lbl.textColor = baseText;
							}
						});

					item.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
							var clickedItem:Sprite = Sprite(e.currentTarget);
							var targetPad:String = clickedItem.name;
							var currentCell:String = (mapCommands != null) ? mapCommands.getMyCell() : "";

							if (mapCommands != null) {
								mapCommands.jump(currentCell, targetPad);
							}

							lastKnownPad = targetPad;
							pendingPadCorrection = false;
							schedulePadRefresh();
						});

					padScroll.addItem(item);
				}

				padScroll.updateScroll(pads.length * (ITEM_HEIGHT + ITEM_SPACING));
			}
			catch (error:Error) {
				// safe fail
			}
		}

		private function schedulePadRefresh():void {
			refreshPads();

			if (padRefreshTimer == null) {
				padRefreshTimer = new Timer(150, 6);
				padRefreshTimer.addEventListener(TimerEvent.TIMER, onPadRefreshTick, false, 0, true);
			}
			padRefreshTimer.reset();
			padRefreshTimer.start();
		}

		private function onPadRefreshTick(e:TimerEvent):void {
			if (mapCommands == null)
				return;

			var curCell:String = mapCommands.getMyCell();
			var curPad:String = mapCommands.getMyPad();
			var availPads:Array = mapCommands.getAvailablePads();
			var padsHash:String = (availPads != null) ? availPads.join(",") : "";

			if (curCell != null && curCell.length > 0) {
				lastKnownCell = curCell;
				updateCellHighlight(curCell);
			}
			lastKnownPad = curPad;
			lastKnownPadsHash = padsHash;

			checkAndCorrectPad(curCell, curPad, availPads);

			refreshPads();
		}

		private function checkAndCorrectPad(curCell:String, curPad:String, availPads:Array):void {
			if (!pendingPadCorrection)
				return;
			if (availPads == null || availPads.length == 0)
				return;

			// Jika sedang menuju target jump cell, tunggu sampai cell cocok (atau targetCell tidak diset)
			if (targetJumpCell != "" && curCell != "" && curCell.toLowerCase() != targetJumpCell.toLowerCase()) {
				return;
			}

			// Cek apakah pad terakhir player termasuk dalam availablePads (green pads)
			if (!isPadInAvailable(curPad, availPads)) {
				var fallbackPad:String = chooseFallbackPad(availPads);
				if (fallbackPad != null && fallbackPad.length > 0 && mapCommands != null) {
					mapCommands.jump(curCell, fallbackPad);
					lastKnownPad = fallbackPad;
					currentPadName = fallbackPad;
				}
			}
			pendingPadCorrection = false;
		}

		private function isPadInAvailable(pad:String, availablePads:Array):Boolean {
			if (pad == null || pad.length == 0 || availablePads == null)
				return false;
			const padLower:String = pad.toLowerCase();
			for each (var p:String in availablePads) {
				if (p != null && p.toLowerCase() == padLower) {
					return true;
				}
			}
			return false;
		}

		private function chooseFallbackPad(availablePads:Array):String {
			if (availablePads == null || availablePads.length == 0)
				return "Spawn";

			const priority:Array = ["spawn", "center", "left", "right", "top", "bottom", "up", "down"];
			for each (var pref:String in priority) {
				for each (var p:String in availablePads) {
					if (p != null && p.toLowerCase() == pref) {
						return capitalizeFirst(p);
					}
				}
			}

			return capitalizeFirst(availablePads[0]);
		}

		private function capitalizeFirst(str:String):String {
			if (str == null || str.length == 0)
				return "";
			return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
		}

		private function startPolling():void {
			if (pollTimer == null) {
				pollTimer = new Timer(350);
				pollTimer.addEventListener(TimerEvent.TIMER, onPollTimer, false, 0, true);
			}
			if (!pollTimer.running) {
				pollTimer.start();
			}
		}

		private function stopPolling():void {
			if (pollTimer != null && pollTimer.running) {
				pollTimer.stop();
			}
		}

		private function onPollTimer(e:TimerEvent):void {
			if (!visible || stage == null || mapCommands == null)
				return;

			var curCell:String = mapCommands.getMyCell();
			var curPad:String = mapCommands.getMyPad();
			var availPads:Array = mapCommands.getAvailablePads();
			var padsHash:String = (availPads != null) ? availPads.join(",") : "";

			if (curCell != lastKnownCell || curPad != lastKnownPad || padsHash != lastKnownPadsHash) {
				lastKnownCell = curCell;
				lastKnownPad = curPad;
				lastKnownPadsHash = padsHash;
				if (curCell != null && curCell.length > 0) {
					updateCellHighlight(curCell);
				}

				checkAndCorrectPad(curCell, curPad, availPads);

				refreshPads();
			}
		}

		private function onRefreshClick(e:MouseEvent):void {
			refresh();
		}

		private function onCloseClick(e:MouseEvent):void {
			visible = false;
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
