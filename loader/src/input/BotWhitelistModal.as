package input {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;

	import ui.ChipTag;
	import ui.CloseButton;
	import ui.ConfirmationMessage;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.ScrollContainer;
	import ui.UIUtils;
	import engine.BotEngine;
	import Utils;

	public class BotWhitelistModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var botEngine:BotEngine;
		private var onChangedCallback:Function;

		private var itemInput:MyTextField;
		private var listScroll:ScrollContainer;
		private var emptyLabel:TextField;
		private var countLabel:TextField;

		public function BotWhitelistModal(botEngine:BotEngine, onChangedCallback:Function = null) {
			super();
			this.botEngine = botEngine;
			this.onChangedCallback = onChangedCallback;
			this.visible = false;

			buildUI();
		}

		private function buildUI():void {
			// Dimmer background
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			addChild(dimmer);

			// Dialog Card
			const boxW:Number = 500;
			const boxH:Number = 310;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Header
			const title:TextField = UIUtils.createLabel("ITEM DROPS WHITELIST", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

			const subTitle:TextField = UIUtils.createLabel("Auto-accept matching item drops while bot is running", UIUtils.TEXT_DIM, 9.5, false);
			subTitle.x = boxX + 16;
			subTitle.y = boxY + 28;
			subTitle.width = 380;
			addChild(subTitle);

			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = boxX + boxW - 32;
			closeBtn.y = boxY + 10;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});
			addChild(closeBtn);

			// Divider under header
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div.graphics.moveTo(boxX + 16, boxY + 48);
			div.graphics.lineTo(boxX + boxW - 16, boxY + 48);
			addChild(div);

			// Input field & Add button
			const inputLbl:TextField = UIUtils.createLabel("Item Name (or comma-separated):", UIUtils.TEXT_MUTED, 10);
			inputLbl.x = boxX + 16;
			inputLbl.y = boxY + 54;
			addChild(inputLbl);

			itemInput = new MyTextField(boxW - 32 - 82, 24);
			itemInput.x = boxX + 16;
			itemInput.y = boxY + 70;
			itemInput.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown, false, 0, true);
			addChild(itemInput);

			const addBtn:MyButton = new MyButton("Add Item", 76, 24, MyButton.TYPE_PRIMARY, onAddClick);
			addBtn.x = boxX + boxW - 16 - 76;
			addBtn.y = boxY + 70;
			addChild(addBtn);

			// Scrollable list container
			const listW:Number = boxW - 32;
			const listH:Number = 145;
			listScroll = new ScrollContainer(listW, listH, 10, true);
			listScroll.x = boxX + 16;
			listScroll.y = boxY + 102;
			addChild(listScroll);

			emptyLabel = UIUtils.createLabel(
					"No items whitelisted yet.\nAdd item names above to auto-accept drops.",
					UIUtils.TEXT_DIM,
					10.5,
					false,
					TextFormatAlign.CENTER
				);
			emptyLabel.width = listW - 16;
			emptyLabel.x = 8;
			emptyLabel.y = 50;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;

			// Footer divider
			const divFooter:Shape = new Shape();
			divFooter.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			divFooter.graphics.moveTo(boxX + 16, boxY + 258);
			divFooter.graphics.lineTo(boxX + boxW - 16, boxY + 258);
			addChild(divFooter);

			// Footer count & buttons
			countLabel = UIUtils.createLabel("(0 items)", UIUtils.TEXT_MUTED, 10);
			countLabel.x = boxX + 16;
			countLabel.y = boxY + 270;
			addChild(countLabel);

			const clearBtn:MyButton = new MyButton("Clear All", 74, 24, MyButton.TYPE_DANGER, onClearAllClick);
			clearBtn.x = boxX + boxW - 16 - 74 - 8 - 64;
			clearBtn.y = boxY + 266;
			addChild(clearBtn);

			const doneBtn:MyButton = new MyButton("Done", 64, 24, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					close();
				});
			doneBtn.x = boxX + boxW - 16 - 64;
			doneBtn.y = boxY + 266;
			addChild(doneBtn);
		}

		public function open():void {
			this.visible = true;
			itemInput.text = "";
			refreshChips();
		}

		public function close():void {
			this.visible = false;
		}

		private function onInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				addItemFromInput();
			}
		}

		private function onAddClick(e:MouseEvent):void {
			addItemFromInput();
		}

		private function addItemFromInput():void {
			var raw:String = itemInput.trimmedText;
			if (raw.length == 0) {
				return;
			}

			var parts:Array = raw.split(",");
			var addedCount:int = 0;
			for each (var part:String in parts) {
				var clean:String = Utils.trim(part);
				if (clean.length > 0) {
					if (botEngine.addWhitelistItem(clean)) {
						addedCount++;
					}
				}
			}

			itemInput.text = "";
			refreshChips();

			if (onChangedCallback != null) {
				onChangedCallback();
			}
		}

		private function onClearAllClick(e:MouseEvent):void {
			if (botEngine.whitelist.length == 0) {
				return;
			}

			const confirmDialog:ConfirmationMessage = new ConfirmationMessage(
					"Clear Whitelist?",
					"Are you sure you want to remove all items from the drop whitelist?",
					function():void {
						const items:Array = botEngine.whitelist.concat();
						for each (var item:String in items) {
							botEngine.removeWhitelistItem(item);
						}

						refreshChips();

						if (onChangedCallback != null) {
							onChangedCallback();
						}
					},
					null,
					"Clear All",
					"Cancel",
					MyButton.TYPE_DANGER
				);

			if (stage != null) {
				stage.addChild(confirmDialog);
			}
			else if (parent != null) {
				parent.addChild(confirmDialog);
			}
		}

		public function refreshChips():void {
			listScroll.clearContent();

			const items:Array = botEngine.whitelist;
			countLabel.text = "(" + items.length + " item" + (items.length == 1 ? "" : "s") + " whitelisted)";

			if (items.length == 0) {
				listScroll.addItem(emptyLabel);
				emptyLabel.visible = true;
				listScroll.updateScroll(0);
				return;
			}

			emptyLabel.visible = false;

			var currentX:Number = 0;
			var currentY:Number = 0;
			const maxW:Number = listScroll.contentWidth;
			const chipH:Number = 22;
			const gapX:Number = 6;
			const gapY:Number = 6;
			var totalRows:int = 1;

			for (var i:int = 0; i < items.length; i++) {
				const itemName:String = String(items[i]);
				const chipW:Number = Math.max(70, Math.min(180, itemName.length * 6.8 + 28));

				if (currentX + chipW > maxW && currentX > 0) {
					currentX = 0;
					currentY += chipH + gapY;
					totalRows++;
				}

				const chip:ChipTag = new ChipTag(itemName, chipW, chipH, true, onRemoveChip);
				chip.x = currentX;
				chip.y = currentY;
				chip.name = itemName;

				currentX += chipW + gapX;
				listScroll.addItem(chip);
			}

			listScroll.updateScroll(totalRows * (chipH + gapY));
		}

		private function onRemoveChip(tag:ChipTag):void {
			botEngine.removeWhitelistItem(tag.name);
			refreshChips();

			if (onChangedCallback != null) {
				onChangedCallback();
			}
		}
	}
}
