package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.*;
	import flash.ui.Keyboard;

	import engine.AutoQuest;
	import ui.CloseButton;
	import ui.MyButton;
	import ui.MyTextField;

	public class QuestTreeUI extends Sprite {

		private static const UI_WIDTH:Number = 350;
		private static const UI_HEIGHT:Number = 440;
		private static const PADDING:Number = 12;
		private static const HEADER_HEIGHT:Number = 36;
		private static const ITEM_HEIGHT:Number = 24;
		private static const ITEM_SPACING:Number = 3;
		private static const SCROLLBAR_WIDTH:Number = 8;
		private static const LIST_Y:Number = 64;
		private static const LIST_HEIGHT:Number = 286;
		private static const LIST_VISIBLE_HEIGHT:Number = LIST_HEIGHT - 12; // 274
		private static const INNER_CONTENT_WIDTH:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4; // 302

		public static var instance:QuestTreeUI;
		private var game:Object;
		private var autoQuest:AutoQuest;

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

		private var questIdInput:MyTextField;
		private var countInput:MyTextField;
		private var loadQuestBtn:MyButton;

		private var optionsMenu:Sprite;
		private var currentQuestID:int;

		public function QuestTreeUI(game:Object, autoQuest:AutoQuest) {
			instance = this;
			this.game = game;
			this.autoQuest = autoQuest;

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			buildUI();
			this.addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown);
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

			const titleTf:TextField = createLabel("Quest Tree", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 80;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Browser", 0x64748b, 9.5, false);
			subTf.x = 88;
			subTf.y = 11;
			subTf.width = 60;
			headerBar.addChild(subTf);

			// Refresh button
			const refreshBtn:MyButton = new MyButton("Refresh", 52, 22, MyButton.TYPE_MUTED, onRefreshClick);
			refreshBtn.x = UI_WIDTH - PADDING - 22 - 6 - 52; // 258
			refreshBtn.y = 7;
			headerBar.addChild(refreshBtn);

			// Close button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22; // 316
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			headerBar.addChild(closeBtn);

			// Section 1 Header: Available Quests
			const listHeader:TextField = createLabel("AVAILABLE QUESTS", 0x64748b, 9.5, true);
			listHeader.x = PADDING;
			listHeader.y = 46;
			listHeader.width = 160;
			addChild(listHeader);

			// Recessed Quest List Box
			const listBox:Shape = new Shape();
			drawRoundedRect(listBox.graphics, PADDING, LIST_Y, UI_WIDTH - PADDING * 2, LIST_HEIGHT, 6, 0x070b14, 0.95, 0x1e293b, 1);
			addChild(listBox);

			listContainer = new Sprite();
			listContainer.x = PADDING + 6;
			listContainer.y = LIST_Y + 6;
			addChild(listContainer);

			// Mask
			const mask:Shape = new Shape();
			mask.graphics.beginFill(0x000000);
			mask.graphics.drawRect(0, 0, INNER_CONTENT_WIDTH, LIST_VISIBLE_HEIGHT);
			mask.graphics.endFill();
			listContainer.addChild(mask);

			// Scroll content
			scrollContent = new Sprite();
			scrollContent.mask = mask;
			listContainer.addChild(scrollContent);

			// Empty label
			emptyLabel = createLabel("No quests available.\nEnter Quest ID below to load.", 0x64748b, 10.5, false, TextFormatAlign.CENTER);
			emptyLabel.x = PADDING;
			emptyLabel.y = LIST_Y + int(LIST_HEIGHT / 2) - 16;
			emptyLabel.width = UI_WIDTH - PADDING * 2;
			emptyLabel.height = 36;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;
			addChild(emptyLabel);

			// Scrollbar
			scrollbar = new Sprite();
			scrollbar.x = UI_WIDTH - PADDING - 6 - SCROLLBAR_WIDTH;
			scrollbar.y = LIST_Y + 6;
			scrollbar.visible = false;
			addChild(scrollbar);

			const trackBg:Shape = new Shape();
			drawRoundedRect(trackBg.graphics, 0, 0, SCROLLBAR_WIDTH, LIST_VISIBLE_HEIGHT, 4, 0x070b14, 0.5);
			scrollbar.addChild(trackBg);

			scrollThumb = new Sprite();
			const thumbBg:Shape = new Shape();
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);
			scrollThumb.addChild(thumbBg);
			scrollThumb.buttonMode = true;
			scrollThumb.useHandCursor = true;
			scrollbar.addChild(scrollThumb);

			scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown, false, 0, true);
			scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver, false, 0, true);
			scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut, false, 0, true);

			// Divider Line above Load section
			const divider:Shape = new Shape();
			divider.graphics.lineStyle(1, 0x1e293b, 1);
			divider.graphics.moveTo(PADDING, 358);
			divider.graphics.lineTo(UI_WIDTH - PADDING, 358);
			addChild(divider);

			// Section 2 Header: Load Quests
			const loadHeader:TextField = createLabel("LOAD QUESTS", 0x64748b, 9.5, true);
			loadHeader.x = PADDING;
			loadHeader.y = 366;
			loadHeader.width = 160;
			addChild(loadHeader);

			// Load Form Controls (y = 384)
			const inputHeight:Number = 26;

			questIdInput = new MyTextField(110, inputHeight, 12.5);
			questIdInput.x = PADDING;
			questIdInput.y = 384;
			questIdInput.maxChars = 128;
			questIdInput.restrict = "0-9,";
			questIdInput.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown, false, 0, true);
			addChild(questIdInput);

			// Dec button (-)
			const decBtn:Sprite = createSmallButton("-", 22, inputHeight, 0xef4444);
			decBtn.x = 128;
			decBtn.y = 384;
			decBtn.addEventListener(MouseEvent.CLICK, onDecClick, false, 0, true);
			addChild(decBtn);

			// Count input
			countInput = new MyTextField(36, inputHeight, 12.5, TextFormatAlign.CENTER, true);
			countInput.text = "0";
			countInput.x = 152;
			countInput.y = 384;
			countInput.restrict = "0-9";
			addChild(countInput);

			// Inc button (+)
			const incBtn:Sprite = createSmallButton("+", 22, inputHeight, 0x4ade80);
			incBtn.x = 190;
			incBtn.y = 384;
			incBtn.addEventListener(MouseEvent.CLICK, onIncClick, false, 0, true);
			addChild(incBtn);

			// Load button
			loadQuestBtn = new MyButton("Load", 118, inputHeight, MyButton.TYPE_SUCCESS, onLoadClick);
			loadQuestBtn.x = 220;
			loadQuestBtn.y = 384;
			addChild(loadQuestBtn);

			buildOptionsMenu();

			// Center
			if (stage != null && x == 0 && y == 0) {
				x = (stage.stageWidth - UI_WIDTH) / 2;
				y = (stage.stageHeight - UI_HEIGHT) / 2;
			}
		}

		public function refresh():void {
			while (scrollContent.numChildren > 0) {
				scrollContent.removeChildAt(0);
			}

			var quests:Array = autoQuest.getQuestTree();
			if (quests == null || quests.length == 0) {
				emptyLabel.visible = true;
				scrollbar.visible = false;
				return;
			}

			emptyLabel.visible = false;

			const totalContentHeight:Number = quests.length * (ITEM_HEIGHT + ITEM_SPACING);

			for (var i:int = 0; i < quests.length; i++) {
				const questData:Object = quests[i];
				const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);
				const questID:int = questData.QuestID;

				const item:Sprite = new Sprite();
				item.y = itemY;

				const itemBg:Shape = new Shape();
				drawRoundedRect(itemBg.graphics, 0, 0, INNER_CONTENT_WIDTH, ITEM_HEIGHT, 4, 0x0f172a, 0.8, 0x1e293b, 1);
				item.addChild(itemBg);

				// Quest ID Badge (clickable to copy)
				const idContainer:Sprite = new Sprite();
				idContainer.x = 4;
				idContainer.y = 3;
				idContainer.name = String(questID);

				const idBg:Shape = new Shape();
				drawRoundedRect(idBg.graphics, 0, 0, 48, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
				idContainer.addChild(idBg);

				const idLabel:TextField = createLabel(String(questID), 0x38bdf8, 9.5, true, TextFormatAlign.CENTER);
				idLabel.width = 48;
				idLabel.height = 18;
				idLabel.y = 1;
				idContainer.addChild(idLabel);

				idContainer.buttonMode = true;
				idContainer.useHandCursor = true;
				idContainer.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						var target:Sprite = Sprite(e.currentTarget);
						var bg:Shape = Shape(target.getChildAt(0));
						drawRoundedRect(bg.graphics, 0, 0, 48, 18, 3, 0x0284c7, 1.0, 0x38bdf8, 1);
						TextField(target.getChildAt(1)).textColor = 0xffffff;
					});
				idContainer.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						var target:Sprite = Sprite(e.currentTarget);
						var bg:Shape = Shape(target.getChildAt(0));
						drawRoundedRect(bg.graphics, 0, 0, 48, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
						TextField(target.getChildAt(1)).textColor = 0x38bdf8;
					});
				idContainer.addEventListener(MouseEvent.CLICK, onQuestIdClick);
				item.addChild(idContainer);

				// Quest Name
				const nameLabel:TextField = createLabel(String(questData.sName), 0xf1f5f9, 10, false);
				nameLabel.x = 56;
				nameLabel.y = 4;
				nameLabel.width = INNER_CONTENT_WIDTH - 56 - 48;
				nameLabel.height = 16;
				item.addChild(nameLabel);

				// Option button (Dropdown)
				const optBtn:Sprite = new Sprite();
				optBtn.buttonMode = true;
				optBtn.useHandCursor = true;
				const optBg:Shape = new Shape();
				drawRoundedRect(optBg.graphics, 0, 0, 20, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
				optBtn.addChild(optBg);

				const optLabel:TextField = createLabel("⋮", 0x94a3b8, 12, true, TextFormatAlign.CENTER);
				optLabel.width = 20;
				optLabel.height = 18;
				optLabel.y = -1;
				optBtn.addChild(optLabel);

				optBtn.x = INNER_CONTENT_WIDTH - 44;
				optBtn.y = 3;
				optBtn.name = "optBtn-" + String(questID);
				optBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						var btn:Sprite = Sprite(e.currentTarget);
						drawRoundedRect(Shape(btn.getChildAt(0)).graphics, 0, 0, 20, 18, 3, 0x334155, 1.0, 0x475569, 1);
						TextField(btn.getChildAt(1)).textColor = 0xffffff;
					});
				optBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						var btn:Sprite = Sprite(e.currentTarget);
						drawRoundedRect(Shape(btn.getChildAt(0)).graphics, 0, 0, 20, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
						TextField(btn.getChildAt(1)).textColor = 0x94a3b8;
					});
				optBtn.addEventListener(MouseEvent.CLICK, onOptBtnClick);
				item.addChild(optBtn);

				// Add to AutoQuest button (+)
				const addBtn:Sprite = new Sprite();
				addBtn.buttonMode = true;
				addBtn.useHandCursor = true;
				const addBg:Shape = new Shape();
				drawRoundedRect(addBg.graphics, 0, 0, 20, 18, 3, 0x15803d, 1.0, 0x166534, 1);
				addBtn.addChild(addBg);

				const addLabel:TextField = createLabel("+", 0xffffff, 11, true, TextFormatAlign.CENTER);
				addLabel.width = 20;
				addLabel.height = 18;
				addLabel.y = 1;
				addBtn.addChild(addLabel);

				addBtn.x = INNER_CONTENT_WIDTH - 22;
				addBtn.y = 3;
				addBtn.name = "addBtn-" + String(questID);
				addBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						var btn:Sprite = Sprite(e.currentTarget);
						drawRoundedRect(Shape(btn.getChildAt(0)).graphics, 0, 0, 20, 18, 3, 0x16a34a, 1.0, 0x22c55e, 1);
					});
				addBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						var btn:Sprite = Sprite(e.currentTarget);
						drawRoundedRect(Shape(btn.getChildAt(0)).graphics, 0, 0, 20, 18, 3, 0x15803d, 1.0, 0x166534, 1);
					});
				addBtn.addEventListener(MouseEvent.CLICK, onAddQuestClick);
				addBtn.visible = !AutoQuestUI.instance || !AutoQuestUI.instance.hasQuestId(String(questID));
				item.addChild(addBtn);

				scrollContent.addChild(item);
			}

			if (totalContentHeight > LIST_VISIBLE_HEIGHT) {
				maxScrollY = totalContentHeight - LIST_VISIBLE_HEIGHT;
				scrollY = 0;
				thumbHeight = Math.max(24, (LIST_VISIBLE_HEIGHT / totalContentHeight) * LIST_VISIBLE_HEIGHT);

				const tBg:Shape = Shape(scrollThumb.getChildAt(0));
				drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);

				scrollThumb.y = 0;
				scrollbar.visible = true;
			}
			else {
				scrollbar.visible = false;
				scrollY = 0;
				maxScrollY = 0;
			}

			updateScrollPosition();
		}

		public function onQuestRemoved(questId:String):void {
			for (var i:int = 0; i < scrollContent.numChildren; i++) {
				var item:Sprite = scrollContent.getChildAt(i) as Sprite;
				if (item != null) {
					var addBtn:Sprite = item.getChildByName("addBtn-" + questId) as Sprite;
					if (addBtn != null) {
						addBtn.visible = true;
						break;
					}
				}
			}
		}

		private function updateScrollPosition():void {
			scrollContent.y = -scrollY;
			if (maxScrollY > 0) {
				const maxThumbY:Number = LIST_VISIBLE_HEIGHT - thumbHeight;
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
			const deltaY:Number = e.stageY - dragStartY;
			var newThumbY:Number = thumbStartY + deltaY;
			const maxThumbY:Number = LIST_VISIBLE_HEIGHT - thumbHeight;
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
			var thumbBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x475569, 1.0);
		}

		private function onThumbRollOut(e:MouseEvent):void {
			var thumbBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);
		}

		private function onQuestIdClick(e:MouseEvent):void {
			var clickedId:String = Sprite(e.currentTarget).name;
			copyToClipboard(clickedId);
			e.stopImmediatePropagation();
		}

		private function onAddQuestClick(e:MouseEvent):void {
			var btn:Sprite = Sprite(e.currentTarget);
			var questID:String = btn.name.split("-")[1];

			if (AutoQuestUI.instance != null) {
				AutoQuestUI.instance.addQuestId(questID);
				btn.visible = false;
			}
			e.stopImmediatePropagation();
		}

		private function onRefreshClick(e:MouseEvent):void {
			refresh();
			e.stopImmediatePropagation();
		}

		private function onCloseClick(e:MouseEvent):void {
			visible = false;
			cleanup();
			e.stopImmediatePropagation();
		}

		private function onLoadClick(e:MouseEvent):void {
			loadQuestsFromInput();
			e.stopImmediatePropagation();
		}

		private function onInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				loadQuestsFromInput();
				e.preventDefault();
			}
		}

		private function createSmallButton(labelStr:String, w:Number, h:Number, textColor:uint = 0xffffff):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
			btn.addChild(bg);

			const isSymbol:Boolean = (labelStr == "-" || labelStr == "+");
			const fontSize:Number = isSymbol ? 15 : 11;
			const tf:TextField = createLabel(labelStr, textColor, fontSize, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = (labelStr == "-") ? int((h - 22) / 2) : int((h - 20) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x475569, 1);
				});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
				});

			return btn;
		}

		private function onDecClick(e:MouseEvent):void {
			var val:int = int(countInput.text);
			if (val > 0)
				countInput.text = String(val - 1);
		}

		private function onIncClick(e:MouseEvent):void {
			var val:int = int(countInput.text);
			countInput.text = String(val + 1);
		}

		private function loadQuestsFromInput():void {
			if (!questIdInput)
				return;
			var ids:String = questIdInput.text;
			if (ids == null)
				return;
			ids = ids.replace(/\s+/g, "");
			if (ids.length == 0)
				return;

			var count:int = int(countInput.text);
			if (count > 0 && !isNaN(Number(ids))) {
				var startId:int = int(ids);
				var idList:Array = [];
				for (var i:int = 0; i <= count; i++) {
					idList.push(String(startId + i));
				}
				autoQuest.loadMultiple(idList.join(","));
			}
			else {
				autoQuest.loadMultiple(ids);
			}
		}

		private function buildOptionsMenu():void {
			optionsMenu = new Sprite();
			optionsMenu.visible = false;

			const menuBg:Shape = new Shape();
			drawRoundedRect(menuBg.graphics, 0, 0, 104, 90, 6, 0x0f172a, 0.98, 0x334155, 1);
			optionsMenu.addChild(menuBg);
			optionsMenu.filters = [new DropShadowFilter(8, 90, 0x000000, 0.7, 12, 12)];

			const acceptBtn:Sprite = createMenuButton("Accept", 0x15803d, 0x16a34a, 6, 6);
			acceptBtn.addEventListener(MouseEvent.CLICK, onAcceptMenuClick);
			optionsMenu.addChild(acceptBtn);

			const completeBtn:Sprite = createMenuButton("Complete", 0x2563eb, 0x3b82f6, 6, 33);
			completeBtn.addEventListener(MouseEvent.CLICK, onCompleteMenuClick);
			optionsMenu.addChild(completeBtn);

			const loadBtn:Sprite = createMenuButton("Load", 0xd97706, 0xf59e0b, 6, 60);
			loadBtn.addEventListener(MouseEvent.CLICK, onLoadMenuClick);
			optionsMenu.addChild(loadBtn);

			addChild(optionsMenu);
		}

		private function createMenuButton(labelStr:String, normalCol:uint, hoverCol:uint, xPos:Number, yPos:Number):Sprite {
			const btn:Sprite = new Sprite();
			btn.x = xPos;
			btn.y = yPos;
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, 92, 22, 4, normalCol, 1.0);
			btn.addChild(bg);

			const tf:TextField = createLabel(labelStr, 0xffffff, 10, true, TextFormatAlign.CENTER);
			tf.width = 92;
			tf.height = 22;
			tf.y = 3;
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, 92, 22, 4, hoverCol, 1.0);
				});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, 92, 22, 4, normalCol, 1.0);
				});

			return btn;
		}

		private function onOptBtnClick(e:MouseEvent):void {
			var btn:Sprite = Sprite(e.currentTarget);
			currentQuestID = int(btn.name.split("-")[1]);

			var pt:Point = this.globalToLocal(btn.localToGlobal(new Point(0, 0)));
			optionsMenu.x = pt.x - 108;
			optionsMenu.y = pt.y;
			optionsMenu.visible = true;

			stage.addEventListener(MouseEvent.CLICK, onStageClick);
			e.stopImmediatePropagation();
		}

		private function onStageClick(e:MouseEvent):void {
			if (optionsMenu.visible && !optionsMenu.hitTestPoint(e.stageX, e.stageY)) {
				optionsMenu.visible = false;
				stage.removeEventListener(MouseEvent.CLICK, onStageClick);
			}
		}

		private function onAcceptMenuClick(e:MouseEvent):void {
			autoQuest.accept(currentQuestID);
			optionsMenu.visible = false;
			e.stopImmediatePropagation();
		}

		private function onCompleteMenuClick(e:MouseEvent):void {
			autoQuest.tryToComplete(currentQuestID);
			optionsMenu.visible = false;
			e.stopImmediatePropagation();
		}

		private function onLoadMenuClick(e:MouseEvent):void {
			autoQuest.load(String(currentQuestID));
			optionsMenu.visible = false;
			e.stopImmediatePropagation();
		}

		private function cleanup():void {
			while (scrollContent.numChildren > 0) {
				scrollContent.removeChildAt(0);
			}
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

		private function copyToClipboard(text:String):void {
			System.setClipboard(text);
		}
	}
}
