package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.BuyItemCommand;
	import commands.EquipItemCommand;
	import commands.TransferToBankCommand;
	import commands.TransferToInventoryCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyDropdown;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotItemTab extends Sprite {

		private var manager:BotManagerUI;

		private var itemNameInput:MyTextField;
		private var actionDropdown:MyDropdown;

		private var buyItemNameInput:MyTextField;
		private var buyShopIdInput:MyTextField;
		private var buyQtyInput:MyTextField;

		private var whitelistStatusLabel:TextField;
		private var notifyDropsCheckbox:MyCheckbox;

		public function BotItemTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Item Actions Section (Equip, Transfer Bank, Transfer Inv)
			const itemLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
			itemLbl.x = 0;
			itemLbl.y = 4;
			addChild(itemLbl);

			itemNameInput = new MyTextField(contentW, 24);
			itemNameInput.x = 0;
			itemNameInput.y = 22;
			addChild(itemNameInput);

			const actionItems:Array = [
					{label: "Equip", value: "equip"},
					{label: "Transfer to Bank", value: "bank"},
					{label: "Transfer to Invent", value: "inv"}
				];

			actionDropdown = new MyDropdown(190, 24, actionItems);
			actionDropdown.x = 0;
			actionDropdown.y = 52;
			addChild(actionDropdown);

			const addCmdBtn:MyButton = new MyButton("Add Command", contentW - 198, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var name:String = itemNameInput.trimmedText;
					if (name.length == 0) {
						return;
					}
					var act:String = String(actionDropdown.selectedValue);
					if (act == "equip") {
						manager.addBotCommand(new EquipItemCommand(name));
					}
					else if (act == "bank") {
						manager.addBotCommand(new TransferToBankCommand(name));
					}
					else if (act == "inv") {
						manager.addBotCommand(new TransferToInventoryCommand(name));
					}
				});
			addCmdBtn.x = 198;
			addCmdBtn.y = 52;
			addChild(addCmdBtn);

			// Divider between Item Actions and Buy (aligned at y=84)
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 84);
			div1.graphics.lineTo(contentW, 84);
			addChild(div1);

			// 2. Buy Shop Item Section (Dedicated fields for Item Name, Shop ID, Qty, and Buy button)
			const buySectionLbl:TextField = UIUtils.createLabel("Buy Shop Item:", UIUtils.TEXT_MUTED, 10.5);
			buySectionLbl.x = 0;
			buySectionLbl.y = 92;
			addChild(buySectionLbl);

			const buyItemNameLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
			buyItemNameLbl.x = 0;
			buyItemNameLbl.y = 110;
			addChild(buyItemNameLbl);

			buyItemNameInput = new MyTextField(contentW, 24);
			buyItemNameInput.x = 0;
			buyItemNameInput.y = 128;
			addChild(buyItemNameInput);

			const buyShopIdLbl:TextField = UIUtils.createLabel("Shop ID:", UIUtils.TEXT_MUTED, 10.5);
			buyShopIdLbl.x = 0;
			buyShopIdLbl.y = 158;
			addChild(buyShopIdLbl);

			buyShopIdInput = new MyTextField(100, 24);
			buyShopIdInput.restrict = "0-9";
			buyShopIdInput.x = 0;
			buyShopIdInput.y = 176;
			addChild(buyShopIdInput);

			const buyQtyLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			buyQtyLbl.x = 110;
			buyQtyLbl.y = 158;
			addChild(buyQtyLbl);

			buyQtyInput = new MyTextField(78, 24);
			buyQtyInput.restrict = "0-9";
			buyQtyInput.text = "1";
			buyQtyInput.x = 110;
			buyQtyInput.y = 176;
			addChild(buyQtyInput);

			const buyBtn:MyButton = new MyButton("Buy", contentW - 198, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var bName:String = buyItemNameInput.trimmedText;
					if (bName.length == 0) {
						return;
					}
					var sId:int = parseInt(buyShopIdInput.trimmedText);
					if (isNaN(sId)) {
						sId = 0;
					}
					var qVal:int = parseInt(buyQtyInput.trimmedText);
					if (isNaN(qVal) || qVal <= 0) {
						qVal = 1;
					}
					manager.addBotCommand(new BuyItemCommand(bName, sId, qVal));
				});
			buyBtn.x = 198;
			buyBtn.y = 176;
			addChild(buyBtn);

			// Divider above Drops Whitelist at the bottom (y=216)
			const divWl:Shape = new Shape();
			divWl.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			divWl.graphics.moveTo(0, 216);
			divWl.graphics.lineTo(contentW, 216);
			addChild(divWl);

			// 3. Drops Whitelist Section at the bottom corner (y=226)
			const wlSectionLbl:TextField = UIUtils.createLabel("Drops Whitelist:", UIUtils.TEXT_MUTED, 10.5);
			wlSectionLbl.y = 226;
			addChild(wlSectionLbl);

			whitelistStatusLabel = UIUtils.createLabel("No items whitelisted.", UIUtils.TEXT_DIM, 10.5);
			whitelistStatusLabel.x = 94;
			whitelistStatusLabel.y = 226;
			whitelistStatusLabel.width = contentW - 94;
			addChild(whitelistStatusLabel);

			const manageWlBtn:MyButton = new MyButton("Manage Whitelist", 124, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					manager.openWhitelistModal();
				});
			manageWlBtn.x = 0;
			manageWlBtn.y = 250;
			addChild(manageWlBtn);

			notifyDropsCheckbox = new MyCheckbox("Drop Notif", manager.botEngine.notifyItemDrops, function(val:Boolean):void {
					manager.botEngine.notifyItemDrops = val;
				}, 10.5);
			notifyDropsCheckbox.x = 132;
			notifyDropsCheckbox.y = 253;
			addChild(notifyDropsCheckbox);

			updateWhitelistStatus();
		}

		public function updateWhitelistStatus():void {
			if (whitelistStatusLabel == null || manager.botEngine == null) {
				return;
			}
			const count:int = manager.botEngine.whitelist.length;
			if (count == 0) {
				whitelistStatusLabel.text = "No items whitelisted yet (Auto-accept inactive).";
			}
			else {
				whitelistStatusLabel.text = count + " item" + (count == 1 ? "" : "s") + " configured to auto-accept drops.";
			}
		}

		public function updateCheckboxes():void {
			if (notifyDropsCheckbox != null && manager.botEngine != null) {
				notifyDropsCheckbox.checked = manager.botEngine.notifyItemDrops;
			}
		}
	}
}
