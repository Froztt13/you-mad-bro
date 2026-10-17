package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.*;
	import flash.ui.Keyboard;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	import engine.AutoQuest;
	import ui.CloseButton;
	import ui.MyButton;
	import ui.MyTextField;

	public class QuestTreeUI extends Sprite {

		public static const MODE_QUEST:String = "quest";
		public static const MODE_SHOP:String = "shop";

		private static const UI_WIDTH:Number = 350;
		private static const UI_HEIGHT:Number = 448;
		private static const PADDING:Number = 12;
		private static const HEADER_HEIGHT:Number = 36;
		private static const ITEM_HEIGHT:Number = 24;
		private static const ITEM_SPACING:Number = 3;
		private static const SCROLLBAR_WIDTH:Number = 8;
		private static const LIST_Y:Number = 68;
		private static const LIST_HEIGHT:Number = 288;
		private static const LIST_VISIBLE_HEIGHT:Number = LIST_HEIGHT - 12; // 276
		private static const INNER_CONTENT_WIDTH:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4; // 302

		public static var instance:QuestTreeUI;
		public static var loadedShops:Array = [];

		private var game:Object;
		private var autoQuest:AutoQuest;

		private var currentMode:String = MODE_QUEST;
		private var selectedShop:Object = null;

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

		// Radio button components
		private var questRadioBtn:Sprite;
		private var shopRadioBtn:Sprite;
		private var questRadioDot:Shape;
		private var shopRadioDot:Shape;
		private var questRadioLabel:TextField;
		private var shopRadioLabel:TextField;
		private var modeCountLabel:TextField;

		// Quest Load Controls
		private var questLoadContainer:Sprite;
		private var questIdInput:MyTextField;
		private var countInput:MyTextField;
		private var loadQuestBtn:MyButton;
		private var acceptQuestBtn:MyButton;
		private var questHelpTf:TextField;
		private var acceptProgressBar:Sprite;
		private var acceptProgressFill:Shape;
		private var isAccepting:Boolean = false;
		private var acceptTimerId:uint = 0;

		// Shop Load Controls
		private var shopLoadContainer:Sprite;
		private var shopIdInput:MyTextField;
		private var loadShopBtn:MyButton;

		// Options Menu
		private var optionsMenu:Sprite;

		// Confirmation Modal Components
		private var confirmModal:Sprite;
		private var confirmTitle:TextField;
		private var confirmMessage:TextField;
		private var confirmOkBtn:MyButton;
		private var confirmCancelBtn:MyButton;
		private var onConfirmAction:Function;

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
			if (confirmModal != null && confirmModal.visible)
				return;
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
					if (confirmModal != null && confirmModal.visible)
						return;
					startDrag();
					stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
				});

			const titleTf:TextField = createLabel("Loader / Grabber", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 110;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Quest & Shop", 0x64748b, 9.5, false);
			subTf.x = 118;
			subTf.y = 11;
			subTf.width = 75;
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

			// Radio Button Bar (Quest vs Shop)
			buildRadioBar();

			// Recessed List Box
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
			divider.graphics.moveTo(PADDING, 364);
			divider.graphics.lineTo(UI_WIDTH - PADDING, 364);
			addChild(divider);

			// Bottom Section: Quest Load Controls
			buildQuestLoadSection();

			// Bottom Section: Shop Load Controls
			buildShopLoadSection();

			// Options Menu
			buildOptionsMenu();

			// Confirmation Modal
			buildConfirmModal();

			// Center panel
			if (stage != null && x == 0 && y == 0) {
				x = (stage.stageWidth - UI_WIDTH) / 2;
				y = (stage.stageHeight - UI_HEIGHT) / 2;
			}

			// Initial state
			setMode(MODE_QUEST);
		}

		private function buildRadioBar():void {
			const radioContainer:Sprite = new Sprite();
			radioContainer.x = PADDING;
			radioContainer.y = 44;
			addChild(radioContainer);

			// Radio 1: Quest
			questRadioBtn = new Sprite();
			questRadioBtn.buttonMode = true;
			questRadioBtn.useHandCursor = true;

			const qOuterCircle:Shape = new Shape();
			drawCircle(qOuterCircle.graphics, 7, 7, 6.5, 0x1e293b, 1.0, 0x475569, 1.5);
			questRadioBtn.addChild(qOuterCircle);

			questRadioDot = new Shape();
			drawCircle(questRadioDot.graphics, 7, 7, 3.5, 0x38bdf8, 1.0);
			questRadioBtn.addChild(questRadioDot);

			questRadioLabel = createLabel("Quest", 0xf8fafc, 11, true);
			questRadioLabel.x = 18;
			questRadioLabel.y = -1;
			questRadioBtn.addChild(questRadioLabel);

			questRadioBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					setMode(MODE_QUEST);
				});
			radioContainer.addChild(questRadioBtn);

			// Radio 2: Shop
			shopRadioBtn = new Sprite();
			shopRadioBtn.x = 88;
			shopRadioBtn.buttonMode = true;
			shopRadioBtn.useHandCursor = true;

			const sOuterCircle:Shape = new Shape();
			drawCircle(sOuterCircle.graphics, 7, 7, 6.5, 0x1e293b, 1.0, 0x475569, 1.5);
			shopRadioBtn.addChild(sOuterCircle);

			shopRadioDot = new Shape();
			drawCircle(shopRadioDot.graphics, 7, 7, 3.5, 0x38bdf8, 1.0);
			shopRadioDot.visible = false;
			shopRadioBtn.addChild(shopRadioDot);

			shopRadioLabel = createLabel("Shop", 0x94a3b8, 11, false);
			shopRadioLabel.x = 18;
			shopRadioLabel.y = -1;
			shopRadioBtn.addChild(shopRadioLabel);

			shopRadioBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					setMode(MODE_SHOP);
				});
			radioContainer.addChild(shopRadioBtn);

			// Mode Count label (right side)
			modeCountLabel = createLabel("", 0x64748b, 9.5, false, TextFormatAlign.RIGHT);
			modeCountLabel.x = UI_WIDTH - PADDING - 120;
			modeCountLabel.y = 44;
			modeCountLabel.width = 120;
			addChild(modeCountLabel);
		}

		private function buildQuestLoadSection():void {
			questLoadContainer = new Sprite();
			questLoadContainer.y = 372;
			addChild(questLoadContainer);

			const loadHeader:TextField = createLabel("LOAD QUESTS", 0x64748b, 9.5, true);
			loadHeader.x = PADDING;
			loadHeader.y = 0;
			loadHeader.width = 160;
			questLoadContainer.addChild(loadHeader);

			const inputHeight:Number = 26;

			questIdInput = new MyTextField(96, inputHeight, 12);
			questIdInput.x = PADDING;
			questIdInput.y = 16;
			questIdInput.maxChars = 128;
			questIdInput.restrict = "0-9,";
			questIdInput.addEventListener(KeyboardEvent.KEY_DOWN, onQuestInputKeyDown, false, 0, true);
			questLoadContainer.addChild(questIdInput);

			// Dec button (-)
			const decBtn:Sprite = createSmallButton("-", 20, inputHeight, 0xef4444);
			decBtn.x = 113;
			decBtn.y = 16;
			decBtn.addEventListener(MouseEvent.CLICK, onDecClick, false, 0, true);
			questLoadContainer.addChild(decBtn);

			// Count input
			countInput = new MyTextField(30, inputHeight, 12, TextFormatAlign.CENTER, true);
			countInput.text = "0";
			countInput.x = 137;
			countInput.y = 16;
			countInput.restrict = "0-9";
			questLoadContainer.addChild(countInput);

			// Inc button (+)
			const incBtn:Sprite = createSmallButton("+", 20, inputHeight, 0x4ade80);
			incBtn.x = 171;
			incBtn.y = 16;
			incBtn.addEventListener(MouseEvent.CLICK, onIncClick, false, 0, true);
			questLoadContainer.addChild(incBtn);

			// Load button
			loadQuestBtn = new MyButton("Load", 68, inputHeight, MyButton.TYPE_SUCCESS, onLoadQuestClick);
			loadQuestBtn.x = 198;
			loadQuestBtn.y = 16;
			questLoadContainer.addChild(loadQuestBtn);

			// Accept button
			acceptQuestBtn = new MyButton("Accept", 68, inputHeight, MyButton.TYPE_PRIMARY, onAcceptQuestClick);
			acceptQuestBtn.x = 270;
			acceptQuestBtn.y = 16;
			questLoadContainer.addChild(acceptQuestBtn);

			questHelpTf = createLabel("Enter Quest ID or ID + count for range", 0x475569, 8.5, false);
			questHelpTf.x = PADDING;
			questHelpTf.y = 45;
			questHelpTf.width = UI_WIDTH - PADDING * 2;
			questLoadContainer.addChild(questHelpTf);

			// Progress bar for quest accepting
			acceptProgressBar = new Sprite();
			acceptProgressBar.x = PADDING;
			acceptProgressBar.y = 63;
			acceptProgressBar.visible = false;

			const barWidth:Number = UI_WIDTH - PADDING * 2;
			acceptProgressBar.graphics.beginFill(0x1e293b, 1.0);
			acceptProgressBar.graphics.drawRoundRect(0, 0, barWidth, 4, 3, 3);
			acceptProgressBar.graphics.endFill();

			acceptProgressFill = new Shape();
			acceptProgressBar.addChild(acceptProgressFill);
			updateAcceptProgress(0);

			questLoadContainer.addChild(acceptProgressBar);
		}

		private function buildShopLoadSection():void {
			shopLoadContainer = new Sprite();
			shopLoadContainer.y = 372;
			shopLoadContainer.visible = false;
			addChild(shopLoadContainer);

			const loadHeader:TextField = createLabel("LOAD SHOP", 0x64748b, 9.5, true);
			loadHeader.x = PADDING;
			loadHeader.y = 0;
			loadHeader.width = 160;
			shopLoadContainer.addChild(loadHeader);

			const inputHeight:Number = 26;

			shopIdInput = new MyTextField(170, inputHeight, 12);
			shopIdInput.x = PADDING;
			shopIdInput.y = 16;
			shopIdInput.maxChars = 10;
			shopIdInput.restrict = "0-9";
			shopIdInput.addEventListener(KeyboardEvent.KEY_DOWN, onShopInputKeyDown, false, 0, true);
			shopLoadContainer.addChild(shopIdInput);

			loadShopBtn = new MyButton("Load Shop", 146, inputHeight, MyButton.TYPE_SUCCESS, function(e:MouseEvent):void {
					loadShopFromInput();
				});
			loadShopBtn.x = PADDING + 170 + 10; // 192
			loadShopBtn.y = 16;
			shopLoadContainer.addChild(loadShopBtn);

			const helpTf:TextField = createLabel("Enter Shop ID to load items & preview in-game", 0x475569, 8.5, false);
			helpTf.x = PADDING;
			helpTf.y = 46;
			helpTf.width = 280;
			shopLoadContainer.addChild(helpTf);
		}

		public function setMode(mode:String):void {
			currentMode = mode;
			selectedShop = null;

			// Update Radio Buttons
			if (currentMode == MODE_QUEST) {
				questRadioDot.visible = true;
				questRadioLabel.textColor = 0xf8fafc;
				shopRadioDot.visible = false;
				shopRadioLabel.textColor = 0x94a3b8;

				questLoadContainer.visible = true;
				shopLoadContainer.visible = false;
			}
			else {
				questRadioDot.visible = false;
				questRadioLabel.textColor = 0x94a3b8;
				shopRadioDot.visible = true;
				shopRadioLabel.textColor = 0xf8fafc;

				questLoadContainer.visible = false;
				shopLoadContainer.visible = true;
			}

			checkAndCacheCurrentShop();
			refresh();
		}

		private function checkAndCacheCurrentShop():void {
			if (game != null && game.world != null) {
				if (game.world.shopinfo != null && game.world.shopinfo.items != null) {
					cacheShop(game.world.shopinfo);
				}
				if (game.world.hairshopinfo != null && game.world.hairshopinfo.items != null) {
					cacheShop(game.world.hairshopinfo);
				}
			}
		}

		private function cacheShop(shopObj:Object):void {
			if (shopObj == null || shopObj.ShopID == null)
				return;
			var exists:Boolean = false;
			for (var i:int = 0; i < loadedShops.length; i++) {
				if (loadedShops[i].ShopID == shopObj.ShopID) {
					loadedShops[i] = shopObj;
					exists = true;
					break;
				}
			}
			if (!exists) {
				loadedShops.push(shopObj);
			}
		}

		public function refresh():void {
			while (scrollContent.numChildren > 0) {
				scrollContent.removeChildAt(0);
			}

			if (currentMode == MODE_QUEST) {
				refreshQuestView();
			}
			else {
				refreshShopView();
			}
		}

		private function refreshQuestView():void {
			var quests:Array = autoQuest.getQuestTree();
			var count:int = (quests != null) ? quests.length : 0;
			modeCountLabel.text = count + " Quests Loaded";

			if (quests == null || quests.length == 0) {
				emptyLabel.text = "No quests available.\nEnter Quest ID below to load.";
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
				optBtn.addEventListener(MouseEvent.CLICK, onQuestOptBtnClick);
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

			setupScrollbar(totalContentHeight);
		}

		private function refreshShopView():void {
			checkAndCacheCurrentShop();

			if (selectedShop != null) {
				renderShopItemsView();
			}
			else {
				renderShopsListView();
			}
		}

		private function renderShopsListView():void {
			modeCountLabel.text = loadedShops.length + " Shops Loaded";

			if (loadedShops.length == 0) {
				emptyLabel.text = "No shops loaded.\nEnter Shop ID below to load.";
				emptyLabel.visible = true;
				scrollbar.visible = false;
				return;
			}

			emptyLabel.visible = false;

			const totalContentHeight:Number = loadedShops.length * (ITEM_HEIGHT + ITEM_SPACING);

			for (var i:int = 0; i < loadedShops.length; i++) {
				const shop:Object = loadedShops[i];
				const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);
				const shopID:int = int(shop.ShopID);
				const itemCount:int = (shop.items != null) ? shop.items.length : 0;
				const shopName:String = (shop.sName != null && shop.sName != "") ? String(shop.sName) : ("Shop #" + shopID);

				const item:Sprite = new Sprite();
				item.y = itemY;

				const itemBg:Shape = new Shape();
				drawRoundedRect(itemBg.graphics, 0, 0, INNER_CONTENT_WIDTH, ITEM_HEIGHT, 4, 0x0f172a, 0.8, 0x1e293b, 1);
				item.addChild(itemBg);

				// Shop ID Badge
				const idContainer:Sprite = new Sprite();
				idContainer.x = 4;
				idContainer.y = 3;
				idContainer.name = String(shopID);

				const idBg:Shape = new Shape();
				drawRoundedRect(idBg.graphics, 0, 0, 48, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
				idContainer.addChild(idBg);

				const idLabel:TextField = createLabel(String(shopID), 0xf59e0b, 9.5, true, TextFormatAlign.CENTER);
				idLabel.width = 48;
				idLabel.height = 18;
				idLabel.y = 1;
				idContainer.addChild(idLabel);

				idContainer.buttonMode = true;
				idContainer.useHandCursor = true;
				idContainer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						copyToClipboard(Sprite(e.currentTarget).name);
						e.stopImmediatePropagation();
					});
				item.addChild(idContainer);

				// Shop Name & count
				const nameLabel:TextField = createLabel(shopName + " (" + itemCount + " items)", 0xf1f5f9, 10, false);
				nameLabel.x = 56;
				nameLabel.y = 4;
				nameLabel.width = INNER_CONTENT_WIDTH - 56 - 68;
				nameLabel.height = 16;
				item.addChild(nameLabel);

				// View Items Button
				const viewBtn:Sprite = new Sprite();
				viewBtn.buttonMode = true;
				viewBtn.useHandCursor = true;
				const vBg:Shape = new Shape();
				drawRoundedRect(vBg.graphics, 0, 0, 40, 18, 3, 0x2563eb, 1.0, 0x3b82f6, 1);
				viewBtn.addChild(vBg);

				const vLabel:TextField = createLabel("View", 0xffffff, 9.5, true, TextFormatAlign.CENTER);
				vLabel.width = 40;
				vLabel.height = 18;
				vLabel.y = 1;
				viewBtn.addChild(vLabel);

				viewBtn.x = INNER_CONTENT_WIDTH - 66;
				viewBtn.y = 3;
				viewBtn.addEventListener(MouseEvent.CLICK, (function(s:Object):Function {
							return function(e:MouseEvent):void {
								selectedShop = s;
								refresh();
								e.stopImmediatePropagation();
							};
						})(shop));
				item.addChild(viewBtn);

				// Option button (⋮)
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

				optBtn.x = INNER_CONTENT_WIDTH - 22;
				optBtn.y = 3;
				optBtn.addEventListener(MouseEvent.CLICK, (function(s:Object):Function {
							return function(e:MouseEvent):void {
								onShopRowOptBtnClick(e, s);
							};
						})(shop));
				item.addChild(optBtn);

				scrollContent.addChild(item);
			}

			setupScrollbar(totalContentHeight);
		}

		private function renderShopItemsView():void {
			emptyLabel.visible = false;
			var items:Array = (selectedShop.items != null) ? selectedShop.items : [];
			modeCountLabel.text = items.length + " Items";

			// Top Back Button Row
			const headerRow:Sprite = new Sprite();
			headerRow.y = 0;

			const backBtn:Sprite = new Sprite();
			backBtn.buttonMode = true;
			backBtn.useHandCursor = true;
			const bBg:Shape = new Shape();
			drawRoundedRect(bBg.graphics, 0, 0, 68, 20, 3, 0x334155, 1.0, 0x475569, 1);
			backBtn.addChild(bBg);

			const bLabel:TextField = createLabel("← Back", 0xf8fafc, 9.5, true, TextFormatAlign.CENTER);
			bLabel.width = 68;
			bLabel.height = 20;
			bLabel.y = 2;
			backBtn.addChild(bLabel);

			backBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					selectedShop = null;
					refresh();
					e.stopImmediatePropagation();
				});
			headerRow.addChild(backBtn);

			const sTitle:String = "#" + selectedShop.ShopID + " " + ((selectedShop.sName != null) ? selectedShop.sName : "");
			const shopTitleTf:TextField = createLabel(sTitle, 0x38bdf8, 10, true);
			shopTitleTf.x = 76;
			shopTitleTf.y = 2;
			shopTitleTf.width = INNER_CONTENT_WIDTH - 76;
			headerRow.addChild(shopTitleTf);

			scrollContent.addChild(headerRow);

			const startY:Number = 26;
			const totalContentHeight:Number = startY + items.length * (ITEM_HEIGHT + ITEM_SPACING);

			for (var i:int = 0; i < items.length; i++) {
				const shopItem:Object = items[i];
				const itemY:Number = startY + i * (ITEM_HEIGHT + ITEM_SPACING);
				const itemID:int = int(shopItem.ItemID);
				const itemName:String = String(shopItem.sName);
				const isCoins:Boolean = (shopItem.bCoins == 1 || shopItem.bCoins == true);
				const costStr:String = String(shopItem.iCost) + (isCoins ? " AC" : " G");
				const costColor:uint = isCoins ? 0x38bdf8 : 0xfacc15;

				const item:Sprite = new Sprite();
				item.y = itemY;

				const itemBg:Shape = new Shape();
				drawRoundedRect(itemBg.graphics, 0, 0, INNER_CONTENT_WIDTH, ITEM_HEIGHT, 4, 0x0f172a, 0.8, 0x1e293b, 1);
				item.addChild(itemBg);

				// Item ID Badge
				const idContainer:Sprite = new Sprite();
				idContainer.x = 4;
				idContainer.y = 3;
				idContainer.name = String(itemID);

				const idBg:Shape = new Shape();
				drawRoundedRect(idBg.graphics, 0, 0, 48, 18, 3, 0x1e293b, 1.0, 0x334155, 1);
				idContainer.addChild(idBg);

				const idLabel:TextField = createLabel(String(itemID), 0x94a3b8, 9, true, TextFormatAlign.CENTER);
				idLabel.width = 48;
				idLabel.height = 18;
				idLabel.y = 1;
				idContainer.addChild(idLabel);

				idContainer.buttonMode = true;
				idContainer.useHandCursor = true;
				idContainer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						copyToClipboard(Sprite(e.currentTarget).name);
						e.stopImmediatePropagation();
					});
				item.addChild(idContainer);

				// Item Name
				const nameLabel:TextField = createLabel(itemName, 0xf1f5f9, 9.5, false);
				nameLabel.x = 56;
				nameLabel.y = 4;
				nameLabel.width = INNER_CONTENT_WIDTH - 56 - 80;
				nameLabel.height = 16;
				item.addChild(nameLabel);

				// Cost Badge
				const costLabel:TextField = createLabel(costStr, costColor, 9, true, TextFormatAlign.RIGHT);
				costLabel.x = INNER_CONTENT_WIDTH - 80;
				costLabel.y = 4;
				costLabel.width = 54;
				costLabel.height = 16;
				item.addChild(costLabel);

				// Option button (⋮)
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

				optBtn.x = INNER_CONTENT_WIDTH - 22;
				optBtn.y = 3;
				optBtn.addEventListener(MouseEvent.CLICK, (function(it:Object):Function {
							return function(e:MouseEvent):void {
								onShopItemOptBtnClick(e, it);
							};
						})(shopItem));
				item.addChild(optBtn);

				scrollContent.addChild(item);
			}

			setupScrollbar(totalContentHeight);
		}

		private function setupScrollbar(totalContentHeight:Number):void {
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
			if (confirmModal != null && confirmModal.visible)
				return;
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
			var questName:String = "";
			var quests:Array = autoQuest.getQuestTree();
			if (quests != null) {
				for (var i:int = 0; i < quests.length; i++) {
					if (String(quests[i].QuestID) == questID) {
						questName = String(quests[i].sName);
						break;
					}
				}
			}

			var displayMsg:String = "Add this quest to Auto Quest?\n\n[" + questID + "] " + (questName != "" ? questName : "Quest #" + questID);

			showConfirmModal("ADD QUEST TO AUTO QUEST", displayMsg, "Add Quest", function():void {
					if (AutoQuestUI.instance != null) {
						AutoQuestUI.instance.addQuestId(questID);
						btn.visible = false;
					}
				});

			e.stopImmediatePropagation();
		}

		private function onRefreshClick(e:MouseEvent):void {
			checkAndCacheCurrentShop();
			refresh();
			e.stopImmediatePropagation();
		}

		private function onCloseClick(e:MouseEvent):void {
			visible = false;
			hideConfirmModal();
			cleanup();
			e.stopImmediatePropagation();
		}

		private function onLoadQuestClick(e:MouseEvent):void {
			loadQuestsFromInput();
			e.stopImmediatePropagation();
		}

		private function onAcceptQuestClick(e:MouseEvent):void {
			acceptQuestsFromInput();
			e.stopImmediatePropagation();
		}

		private function onQuestInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				loadQuestsFromInput();
				e.preventDefault();
			}
		}

		private function onShopInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				loadShopFromInput();
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

			setTimeout(function():void {
					if (currentMode == MODE_QUEST) {
						refresh();
					}
				}, 600);
		}

		private function acceptQuestsFromInput():void {
			if (isAccepting)
				return;
			if (!questIdInput)
				return;
			var ids:String = questIdInput.text;
			if (ids == null)
				return;
			ids = ids.replace(/\s+/g, "");
			if (ids.length == 0)
				return;

			var targetIds:Array = [];
			var count:int = int(countInput.text);
			if (count > 0 && !isNaN(Number(ids))) {
				var startId:int = int(ids);
				for (var i:int = 0; i <= count; i++) {
					targetIds.push(startId + i);
				}
			}
			else {
				var parts:Array = ids.split(",");
				for each (var part:String in parts) {
					var qId:int = int(part);
					if (qId > 0 && targetIds.indexOf(qId) == -1) {
						targetIds.push(qId);
					}
				}
			}

			if (targetIds.length == 0)
				return;

			isAccepting = true;
			loadQuestBtn.enabled = false;
			acceptQuestBtn.enabled = false;
			acceptProgressBar.visible = true;
			updateAcceptProgress(0);

			// Load quests first before accepting
			autoQuest.loadMultiple(targetIds.join(","));
			questHelpTf.text = "Loading quest data...";
			questHelpTf.textColor = 0x38bdf8;
			acceptQuestBtn.label = "...";

			var total:int = targetIds.length;
			var currentIndex:int = 0;

			var processNext:Function = function():void {
				if (!isAccepting)
					return;

				if (currentIndex >= total) {
					acceptQuestBtn.label = "Done";
					updateAcceptProgress(1.0);
					questHelpTf.text = "Accepted " + total + " quest(s) successfully.";
					questHelpTf.textColor = 0x4ade80;

					if (currentMode == MODE_QUEST) {
						refresh();
					}

					acceptTimerId = setTimeout(function():void {
							resetAcceptUI();
						}, 1500);
					return;
				}

				var currentQuestId:int = targetIds[currentIndex];
				var displayIndex:int = currentIndex + 1;
				var pct:int = int((displayIndex / total) * 100);

				acceptQuestBtn.label = displayIndex + "/" + total;
				questHelpTf.text = "Accepting (" + displayIndex + "/" + total + "): Quest [" + currentQuestId + "] " + pct + "%...";
				questHelpTf.textColor = 0x38bdf8;
				updateAcceptProgress(displayIndex / total);

				autoQuest.accept(currentQuestId);
				currentIndex++;

				acceptTimerId = setTimeout(processNext, total > 1 ? 180 : 250);
			};

			acceptTimerId = setTimeout(processNext, 400);
		}

		private function updateAcceptProgress(ratio:Number):void {
			if (!acceptProgressFill)
				return;
			if (ratio < 0)
				ratio = 0;
			if (ratio > 1)
				ratio = 1;
			const barWidth:Number = UI_WIDTH - PADDING * 2;
			const fillW:Number = Math.max(0, barWidth * ratio);
			acceptProgressFill.graphics.clear();
			if (fillW > 0) {
				acceptProgressFill.graphics.beginFill(0x38bdf8, 1.0);
				acceptProgressFill.graphics.drawRoundRect(0, 0, fillW, 4, 3, 3);
				acceptProgressFill.graphics.endFill();
			}
		}

		private function resetAcceptUI():void {
			isAccepting = false;
			if (acceptTimerId != 0) {
				clearTimeout(acceptTimerId);
				acceptTimerId = 0;
			}
			if (acceptQuestBtn) {
				acceptQuestBtn.label = "Accept";
				acceptQuestBtn.enabled = true;
			}
			if (loadQuestBtn) {
				loadQuestBtn.enabled = true;
			}
			if (acceptProgressBar) {
				acceptProgressBar.visible = false;
				updateAcceptProgress(0);
			}
			if (questHelpTf) {
				questHelpTf.text = "Enter Quest ID or ID + count for range";
				questHelpTf.textColor = 0x475569;
			}
		}

		private function loadShopFromInput():void {
			if (!shopIdInput)
				return;
			var idStr:String = shopIdInput.text;
			if (idStr == null)
				return;
			idStr = idStr.replace(/\s+/g, "");
			if (idStr.length == 0)
				return;

			var shopId:int = int(idStr);
			if (shopId <= 0)
				return;

			if (game != null && game.world != null) {
				if (game.world.sendLoadShopRequest != null) {
					game.world.sendLoadShopRequest(shopId);
				}
			}

			// Poll shop info after slight delay
			setTimeout(function():void {
					checkAndCacheCurrentShop();
					if (currentMode == MODE_SHOP) {
						refresh();
					}
				}, 600);
			setTimeout(function():void {
					checkAndCacheCurrentShop();
					if (currentMode == MODE_SHOP) {
						refresh();
					}
				}, 1400);
		}

		private function buildOptionsMenu():void {
			optionsMenu = new Sprite();
			optionsMenu.visible = false;
			addChild(optionsMenu);
		}

		private function showMenuWithButtons(buttons:Array, globalX:Number, globalY:Number):void {
			while (optionsMenu.numChildren > 0) {
				optionsMenu.removeChildAt(0);
			}

			const menuWidth:Number = 106;
			const btnHeight:Number = 22;
			const btnSpacing:Number = 4;
			const padding:Number = 6;
			const menuHeight:Number = padding * 2 + buttons.length * (btnHeight + btnSpacing) - btnSpacing;

			const menuBg:Shape = new Shape();
			drawRoundedRect(menuBg.graphics, 0, 0, menuWidth, menuHeight, 6, 0x0f172a, 0.98, 0x334155, 1);
			optionsMenu.addChild(menuBg);
			optionsMenu.filters = [new DropShadowFilter(8, 90, 0x000000, 0.7, 12, 12)];

			for (var i:int = 0; i < buttons.length; i++) {
				var bData:Object = buttons[i];
				var btn:Sprite = createMenuButton(bData.label, bData.color, bData.hoverColor, padding, padding + i * (btnHeight + btnSpacing), menuWidth - padding * 2, btnHeight);
				btn.addEventListener(MouseEvent.CLICK, bData.fn);
				optionsMenu.addChild(btn);
			}

			var pt:Point = this.globalToLocal(new Point(globalX, globalY));
			optionsMenu.x = Math.max(PADDING, Math.min(pt.x - menuWidth, UI_WIDTH - menuWidth - PADDING));
			optionsMenu.y = Math.max(HEADER_HEIGHT, Math.min(pt.y, UI_HEIGHT - menuHeight - PADDING));
			optionsMenu.visible = true;

			stage.addEventListener(MouseEvent.CLICK, onStageClick);
		}

		private function createMenuButton(labelStr:String, normalCol:uint, hoverCol:uint, xPos:Number, yPos:Number, w:Number, h:Number):Sprite {
			const btn:Sprite = new Sprite();
			btn.x = xPos;
			btn.y = yPos;
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, normalCol, 1.0);
			btn.addChild(bg);

			const tf:TextField = createLabel(labelStr, 0xffffff, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = 3;
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, hoverCol, 1.0);
				});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, normalCol, 1.0);
				});

			return btn;
		}

		private function onStageClick(e:MouseEvent):void {
			if (optionsMenu.visible && !optionsMenu.hitTestPoint(e.stageX, e.stageY)) {
				optionsMenu.visible = false;
				stage.removeEventListener(MouseEvent.CLICK, onStageClick);
			}
		}

		private function onQuestOptBtnClick(e:MouseEvent):void {
			var btn:Sprite = Sprite(e.currentTarget);
			var questID:int = int(btn.name.split("-")[1]);

			var pt:Point = btn.localToGlobal(new Point(0, 0));
			showMenuWithButtons([
						{
							label: "Add to Auto",
							color: 0x15803d,
							hoverColor: 0x16a34a,
							fn: function(ev:MouseEvent):void {
								optionsMenu.visible = false;
								var qName:String = "";
								var qs:Array = autoQuest.getQuestTree();
								if (qs != null) {
									for (var j:int = 0; j < qs.length; j++) {
										if (qs[j].QuestID == questID) {
											qName = String(qs[j].sName);
											break;
										}
									}
								}
								var displayMsg:String = "Add this quest to Auto Quest?\n\n[" + questID + "] " + (qName != "" ? qName : "Quest #" + questID);
								showConfirmModal("ADD QUEST TO AUTO QUEST", displayMsg, "Add Quest", function():void {
										if (AutoQuestUI.instance != null) {
											AutoQuestUI.instance.addQuestId(String(questID));
											for (var k:int = 0; k < scrollContent.numChildren; k++) {
												var item:Sprite = scrollContent.getChildAt(k) as Sprite;
												if (item != null) {
													var b:Sprite = item.getChildByName("addBtn-" + questID) as Sprite;
													if (b != null) {
														b.visible = false;
														break;
													}
												}
											}
										}
									});
							}
						},
						{
							label: "Accept",
							color: 0x2563eb,
							hoverColor: 0x3b82f6,
							fn: function(ev:MouseEvent):void {
								autoQuest.accept(questID);
								optionsMenu.visible = false;
							}
						},
						{
							label: "Complete",
							color: 0x0284c7,
							hoverColor: 0x0ea5e9,
							fn: function(ev:MouseEvent):void {
								autoQuest.tryToComplete(questID);
								optionsMenu.visible = false;
							}
						},
						{
							label: "Load",
							color: 0xd97706,
							hoverColor: 0xf59e0b,
							fn: function(ev:MouseEvent):void {
								autoQuest.load(String(questID));
								optionsMenu.visible = false;
							}
						},
						{
							label: "Copy ID",
							color: 0x334155,
							hoverColor: 0x475569,
							fn: function(ev:MouseEvent):void {
								copyToClipboard(String(questID));
								optionsMenu.visible = false;
							}
						}
					], pt.x, pt.y);

			e.stopImmediatePropagation();
		}

		private function onShopRowOptBtnClick(e:MouseEvent, shop:Object):void {
			var btn:Sprite = Sprite(e.currentTarget);
			var pt:Point = btn.localToGlobal(new Point(0, 0));

			showMenuWithButtons([
						{
							label: "Open Shop",
							color: 0x15803d,
							hoverColor: 0x16a34a,
							fn: function(ev:MouseEvent):void {
								if (game != null && game.world != null && game.world.sendLoadShopRequest != null) {
									game.world.sendLoadShopRequest(int(shop.ShopID));
								}
								optionsMenu.visible = false;
							}
						},
						{
							label: "View Items",
							color: 0x2563eb,
							hoverColor: 0x3b82f6,
							fn: function(ev:MouseEvent):void {
								selectedShop = shop;
								refresh();
								optionsMenu.visible = false;
							}
						},
						{
							label: "Copy Shop ID",
							color: 0x334155,
							hoverColor: 0x475569,
							fn: function(ev:MouseEvent):void {
								copyToClipboard(String(shop.ShopID));
								optionsMenu.visible = false;
							}
						}
					], pt.x, pt.y);

			e.stopImmediatePropagation();
		}

		private function onShopItemOptBtnClick(e:MouseEvent, item:Object):void {
			var btn:Sprite = Sprite(e.currentTarget);
			var pt:Point = btn.localToGlobal(new Point(0, 0));

			var isCoins:Boolean = (item.bCoins == 1 || item.bCoins == true);
			var costStr:String = String(item.iCost) + (isCoins ? " AC" : " Gold");

			showMenuWithButtons([
						{
							label: "Buy 1",
							color: 0x15803d,
							hoverColor: 0x16a34a,
							fn: function(ev:MouseEvent):void {
								optionsMenu.visible = false;
								var buyMsg:String = "Are you sure you want to buy:\n\"" + item.sName + "\"\nPrice: " + costStr + "?";
								showConfirmModal("CONFIRM PURCHASE", buyMsg, "Buy", function():void {
										buyShopItem(item);
									});
							}
						},
						{
							label: "Copy Name",
							color: 0x2563eb,
							hoverColor: 0x3b82f6,
							fn: function(ev:MouseEvent):void {
								copyToClipboard(String(item.sName));
								optionsMenu.visible = false;
							}
						},
						{
							label: "Copy Item ID",
							color: 0x334155,
							hoverColor: 0x475569,
							fn: function(ev:MouseEvent):void {
								copyToClipboard(String(item.ItemID));
								optionsMenu.visible = false;
							}
						},
						{
							label: "Open Shop",
							color: 0xd97706,
							hoverColor: 0xf59e0b,
							fn: function(ev:MouseEvent):void {
								if (selectedShop != null && game != null && game.world != null && game.world.sendLoadShopRequest != null) {
									game.world.sendLoadShopRequest(int(selectedShop.ShopID));
								}
								optionsMenu.visible = false;
							}
						}
					], pt.x, pt.y);

			e.stopImmediatePropagation();
		}

		private function buyShopItem(item:Object):void {
			if (game == null || game.world == null)
				return;
			if (selectedShop != null) {
				if (game.world.shopinfo == null || game.world.shopinfo.ShopID != selectedShop.ShopID) {
					game.world.shopinfo = selectedShop;
				}
			}
			if (game.world.sendBuyItemRequest != null) {
				game.world.sendBuyItemRequest(item);
			}
		}

		// Confirmation Modal Implementation
		private function buildConfirmModal():void {
			confirmModal = new Sprite();
			confirmModal.visible = false;
			addChild(confirmModal);

			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.72);
			dimmer.graphics.drawRoundRect(0, 0, UI_WIDTH, UI_HEIGHT, 8);
			dimmer.graphics.endFill();
			dimmer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					e.stopImmediatePropagation();
				});
			confirmModal.addChild(dimmer);

			const cardW:Number = 280;
			const cardH:Number = 144;
			const cardX:Number = int((UI_WIDTH - cardW) / 2);
			const cardY:Number = int((UI_HEIGHT - cardH) / 2);

			const cardBg:Shape = new Shape();
			drawRoundedRect(cardBg.graphics, cardX, cardY, cardW, cardH, 8, 0x0f172a, 0.98, 0x334155, 1);
			cardBg.filters = [new DropShadowFilter(10, 90, 0x000000, 0.7, 16, 16)];
			confirmModal.addChild(cardBg);

			confirmTitle = createLabel("CONFIRMATION", 0xf8fafc, 11, true, TextFormatAlign.CENTER);
			confirmTitle.x = cardX + 12;
			confirmTitle.y = cardY + 14;
			confirmTitle.width = cardW - 24;
			confirmModal.addChild(confirmTitle);

			confirmMessage = createLabel("", 0xcbd5e1, 10, false, TextFormatAlign.CENTER);
			confirmMessage.x = cardX + 14;
			confirmMessage.y = cardY + 38;
			confirmMessage.width = cardW - 28;
			confirmMessage.height = 54;
			confirmMessage.multiline = true;
			confirmMessage.wordWrap = true;
			confirmModal.addChild(confirmMessage);

			confirmCancelBtn = new MyButton("Cancel", 110, 24, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					hideConfirmModal();
					e.stopImmediatePropagation();
				});
			confirmCancelBtn.x = cardX + 22;
			confirmCancelBtn.y = cardY + cardH - 34;
			confirmModal.addChild(confirmCancelBtn);

			confirmOkBtn = new MyButton("Confirm", 110, 24, MyButton.TYPE_SUCCESS, function(e:MouseEvent):void {
					var action:Function = onConfirmAction;
					hideConfirmModal();
					if (action != null) {
						action();
					}
					e.stopImmediatePropagation();
				});
			confirmOkBtn.x = cardX + cardW - 22 - 110;
			confirmOkBtn.y = cardY + cardH - 34;
			confirmModal.addChild(confirmOkBtn);
		}

		private function showConfirmModal(title:String, message:String, okLabel:String, onOk:Function):void {
			confirmTitle.text = title;
			confirmMessage.text = message;
			confirmOkBtn.label = okLabel;
			onConfirmAction = onOk;
			confirmModal.visible = true;
			setChildIndex(confirmModal, numChildren - 1);
		}

		private function hideConfirmModal():void {
			confirmModal.visible = false;
			onConfirmAction = null;
		}

		private function cleanup():void {
			resetAcceptUI();
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

		private static function drawCircle(g:Graphics, x:Number, y:Number, r:Number, fillColor:uint, fillAlpha:Number, strokeColor:uint = 0, strokeThickness:Number = 0):void {
			g.clear();
			g.beginFill(fillColor, fillAlpha);
			if (strokeThickness > 0) {
				g.lineStyle(strokeThickness, strokeColor, 1.0);
			}
			g.drawCircle(x, y, r);
			g.endFill();
		}

		private function copyToClipboard(text:String):void {
			System.setClipboard(text);
		}
	}
}
