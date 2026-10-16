package input.bot_manager.modals {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	import commands.BotCommand;
	import commands.conditions.BaseConditionalCommand;
	import ui.CloseButton;
	import ui.MyButton;
	import ui.ScrollContainer;
	import ui.UIUtils;

	public class BotConditionsModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var onSelectCallback:Function;
		private var currentCategory:String = BaseConditionalCommand.CATEGORY_ALL;
		private var selectedType:String = null;

		private var countLabel:TextField;
		private var conditionsScroll:ScrollContainer;

		private var tabAllBtn:MyButton;
		private var tabItemBtn:MyButton;
		private var tabPlayerBtn:MyButton;
		private var tabMapBtn:MyButton;
		private var tabQuestBtn:MyButton;

		public function BotConditionsModal(onSelectCallback:Function = null) {
			super();
			this.onSelectCallback = onSelectCallback;
			this.visible = false;

			buildUI();
		}

		private function buildUI():void {
			// Dark overlay dimmer
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			addChild(dimmer);

			dimmer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});

			// Modal Card
			const boxW:Number = 480;
			const boxH:Number = 300;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Header Title
			const title:TextField = UIUtils.createLabel("SELECT CONDITION", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

			countLabel = UIUtils.createLabel("", UIUtils.TEXT_DIM, 9.5, false);
			countLabel.x = boxX + 160;
			countLabel.y = boxY + 14;
			countLabel.width = 160;
			addChild(countLabel);

			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = boxX + boxW - 32;
			closeBtn.y = boxY + 10;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});
			addChild(closeBtn);

			// Header Divider
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(boxX + 16, boxY + 36);
			div.graphics.lineTo(boxX + boxW - 16, boxY + 36);
			addChild(div);

			// Category Tabs
			const tabY:Number = boxY + 44;
			const tabH:Number = 24;
			const tabGap:Number = 4;
			var curTabX:Number = boxX + 16;

			tabAllBtn = new MyButton("All", 42, tabH, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					switchCategory(BaseConditionalCommand.CATEGORY_ALL);
				}, 10.5);
			tabAllBtn.x = curTabX;
			tabAllBtn.y = tabY;
			addChild(tabAllBtn);
			curTabX += 42 + tabGap;

			tabItemBtn = new MyButton("Item", 54, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchCategory(BaseConditionalCommand.CATEGORY_ITEM);
				}, 10.5);
			tabItemBtn.x = curTabX;
			tabItemBtn.y = tabY;
			addChild(tabItemBtn);
			curTabX += 54 + tabGap;

			tabPlayerBtn = new MyButton("Player", 62, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchCategory(BaseConditionalCommand.CATEGORY_PLAYER);
				}, 10.5);
			tabPlayerBtn.x = curTabX;
			tabPlayerBtn.y = tabY;
			addChild(tabPlayerBtn);
			curTabX += 62 + tabGap;

			tabMapBtn = new MyButton("Map", 50, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchCategory(BaseConditionalCommand.CATEGORY_MAP);
				}, 10.5);
			tabMapBtn.x = curTabX;
			tabMapBtn.y = tabY;
			addChild(tabMapBtn);
			curTabX += 50 + tabGap;

			tabQuestBtn = new MyButton("Quest", 58, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchCategory(BaseConditionalCommand.CATEGORY_QUEST);
				}, 10.5);
			tabQuestBtn.x = curTabX;
			tabQuestBtn.y = tabY;
			addChild(tabQuestBtn);

			// Scrollable Conditions List
			conditionsScroll = new ScrollContainer(boxW - 32, boxH - 80, 10, true);
			conditionsScroll.x = boxX + 16;
			conditionsScroll.y = boxY + 74;
			addChild(conditionsScroll);
		}

		public function switchCategory(category:String):void {
			currentCategory = category;

			tabAllBtn.setType(category == BaseConditionalCommand.CATEGORY_ALL ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabItemBtn.setType(category == BaseConditionalCommand.CATEGORY_ITEM ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabPlayerBtn.setType(category == BaseConditionalCommand.CATEGORY_PLAYER ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabMapBtn.setType(category == BaseConditionalCommand.CATEGORY_MAP ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabQuestBtn.setType(category == BaseConditionalCommand.CATEGORY_QUEST ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);

			tabAllBtn.active = (category == BaseConditionalCommand.CATEGORY_ALL);
			tabItemBtn.active = (category == BaseConditionalCommand.CATEGORY_ITEM);
			tabPlayerBtn.active = (category == BaseConditionalCommand.CATEGORY_PLAYER);
			tabMapBtn.active = (category == BaseConditionalCommand.CATEGORY_MAP);
			tabQuestBtn.active = (category == BaseConditionalCommand.CATEGORY_QUEST);

			refreshList();
		}

		public function open(currentSelectedType:String = null):void {
			this.selectedType = currentSelectedType;

			// If current selection belongs to a category, switch to it, otherwise default to All
			if (currentSelectedType != null) {
				var def:Object = BaseConditionalCommand.getDefinition(currentSelectedType);
				if (def != null && def.category != null) {
					currentCategory = String(def.category);
				}
				else {
					currentCategory = BaseConditionalCommand.CATEGORY_ALL;
				}
			}
			else {
				currentCategory = BaseConditionalCommand.CATEGORY_ALL;
			}

			switchCategory(currentCategory);
			this.visible = true;
		}

		public function close():void {
			this.visible = false;
		}

		private function refreshList():void {
			conditionsScroll.clearContent(true);

			var items:Array = BaseConditionalCommand.getConditionsByCategory(currentCategory);
			countLabel.text = "(" + items.length + " condition" + (items.length == 1 ? "" : "s") + ")";

			const rowW:Number = conditionsScroll.contentWidth;
			const rowH:Number = 36;
			const rowGap:Number = 4;

			for (var i:int = 0; i < items.length; i++) {
				var item:Object = items[i];
				var row:Sprite = buildConditionRow(item, rowW, rowH);
				row.y = i * (rowH + rowGap);
				conditionsScroll.addItem(row);
			}

			conditionsScroll.updateScroll(items.length * (rowH + rowGap));
		}

		private function buildConditionRow(item:Object, w:Number, h:Number):Sprite {
			const row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			const isSelected:Boolean = (selectedType != null && selectedType == item.value);

			const bg:Shape = new Shape();
			var defaultBg:uint = isSelected ? 0x1e293b : 0x0f172a;
			var defaultBorder:uint = isSelected ? 0x38bdf8 : 0x1e293b;
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, defaultBg, 0.95, defaultBorder, 1);
			row.addChild(bg);

			// Category Badge
			var catColor:uint = 0x38bdf8;
			var catBg:uint = 0x0c4a6e;
			switch (item.category) {
				case BaseConditionalCommand.CATEGORY_ITEM:
					catColor = 0x38bdf8;
					catBg = 0x075985;
					break;
				case BaseConditionalCommand.CATEGORY_PLAYER:
					catColor = 0xfacc15;
					catBg = 0x713f12;
					break;
				case BaseConditionalCommand.CATEGORY_MAP:
					catColor = 0xa78bfa;
					catBg = 0x4c1d95;
					break;
				case BaseConditionalCommand.CATEGORY_QUEST:
					catColor = 0x34d399;
					catBg = 0x064e3b;
					break;
			}

			const badgeShp:Shape = new Shape();
			UIUtils.drawRoundedRect(badgeShp.graphics, 6, 8, 48, 20, 3, catBg, 0.6, catColor, 1);
			row.addChild(badgeShp);

			const badgeTf:TextField = UIUtils.createLabel(String(item.category).toUpperCase(), catColor, 8.5, true, TextFormatAlign.CENTER);
			badgeTf.x = 6;
			badgeTf.y = 11;
			badgeTf.width = 48;
			badgeTf.mouseEnabled = false;
			row.addChild(badgeTf);

			// Label & Description
			const titleTf:TextField = UIUtils.createLabel(String(item.label), UIUtils.TEXT_WHITE, 10.5, true);
			titleTf.x = 62;
			titleTf.y = 4;
			titleTf.width = w - 145;
			titleTf.mouseEnabled = false;
			row.addChild(titleTf);

			const descTf:TextField = UIUtils.createLabel(String(item.description), UIUtils.TEXT_MUTED, 9, false);
			descTf.x = 62;
			descTf.y = 18;
			descTf.width = w - 145;
			descTf.mouseEnabled = false;
			row.addChild(descTf);

			// Action text
			const actionTf:TextField = UIUtils.createLabel(
					isSelected ? "Selected ✓" : "Select ↵",
					isSelected ? 0x34d399 : 0x38bdf8,
					9.5,
					false,
					TextFormatAlign.RIGHT
				);
			actionTf.x = w - 76;
			actionTf.y = 11;
			actionTf.width = 70;
			actionTf.mouseEnabled = false;
			row.addChild(actionTf);

			// Hover Effects
			row.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x38bdf8, 1);
					titleTf.textColor = 0x93c5fd;
				});

			row.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, defaultBg, 0.95, defaultBorder, 1);
					titleTf.textColor = UIUtils.TEXT_WHITE;
				});

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (onSelectCallback != null) {
						onSelectCallback(String(item.value));
					}
					close();
				});

			return row;
		}
	}
}
