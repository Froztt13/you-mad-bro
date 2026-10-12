package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.GetMapItemCommand;
	import commands.QuestAcceptCommand;
	import commands.QuestCompleteCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotQuestTab extends Sprite {

		private var manager:BotManagerUI;
		private var mapItemIdInput:MyTextField;
		private var mapItemQtyInput:MyTextField;

		public function BotQuestTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Quest Section
			const qLbl:TextField = UIUtils.createLabel("Quest ID:", UIUtils.TEXT_MUTED, 10.5);
			qLbl.x = 0;
			qLbl.y = 4;
			addChild(qLbl);

			const qInput:MyTextField = new MyTextField(110, 24);
			qInput.name = "questIdInput";
			qInput.x = 0;
			qInput.y = 22;
			qInput.restrict = "0-9";
			addChild(qInput);

			// Item ID (Reward Selection, default -1)
			const itemLbl:TextField = UIUtils.createLabel("Item ID:", UIUtils.TEXT_MUTED, 10.5);
			itemLbl.x = 120;
			itemLbl.y = 4;
			addChild(itemLbl);

			const itemInput:MyTextField = new MyTextField(110, 24);
			itemInput.name = "questItemIdInput";
			itemInput.x = 120;
			itemInput.y = 22;
			itemInput.text = "-1";
			itemInput.restrict = "0-9\\-";
			addChild(itemInput);

			// Buttons (height 24, y 52, matching Map and Item tabs)
			const addAcceptBtn:MyButton = new MyButton("Add Accept Quest", 130, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var qid:int = parseInt(qInput.text);
					if (qid > 0) {
						manager.addBotCommand(new QuestAcceptCommand(qid));
					}
				});
			addAcceptBtn.x = 0;
			addAcceptBtn.y = 52;
			addChild(addAcceptBtn);

			const addTurnInBtn:MyButton = new MyButton("Add Turn-In Quest", 130, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var qid:int = parseInt(qInput.text);
					var iid:int = parseInt(itemInput.text);
					if (isNaN(iid)) {
						iid = -1;
					}
					if (qid > 0) {
						manager.addBotCommand(new QuestCompleteCommand(qid, iid));
					}
				});
			addTurnInBtn.x = 138;
			addTurnInBtn.y = 52;
			addChild(addTurnInBtn);

			// Divider between Quest and Map Item (aligned with other tabs at y=84)
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 84);
			div1.graphics.lineTo(contentW, 84);
			addChild(div1);

			// 2. Get Map Item Section
			const mapItemSectionLbl:TextField = UIUtils.createLabel("Get Map Item (Quest Map Item):", UIUtils.TEXT_MUTED, 10.5);
			mapItemSectionLbl.x = 0;
			mapItemSectionLbl.y = 92;
			addChild(mapItemSectionLbl);

			const mapItemIdLbl:TextField = UIUtils.createLabel("Item ID:", UIUtils.TEXT_MUTED, 10.5);
			mapItemIdLbl.x = 0;
			mapItemIdLbl.y = 110;
			addChild(mapItemIdLbl);

			mapItemIdInput = new MyTextField(110, 24);
			mapItemIdInput.restrict = "0-9";
			mapItemIdInput.x = 0;
			mapItemIdInput.y = 128;
			addChild(mapItemIdInput);

			const mapItemQtyLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			mapItemQtyLbl.x = 118;
			mapItemQtyLbl.y = 110;
			addChild(mapItemQtyLbl);

			mapItemQtyInput = new MyTextField(60, 24);
			mapItemQtyInput.restrict = "0-9";
			mapItemQtyInput.text = "1";
			mapItemQtyInput.x = 118;
			mapItemQtyInput.y = 128;
			addChild(mapItemQtyInput);

			const addMapItemBtn:MyButton = new MyButton("Get Map Item", contentW - 186, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
				var id:int = parseInt(mapItemIdInput.trimmedText);
				var qVal:int = parseInt(mapItemQtyInput.trimmedText);
				var qty:int = (!isNaN(qVal) && qVal > 0) ? qVal : 1;
				if (!isNaN(id) && id > 0) {
					manager.addBotCommand(new GetMapItemCommand(id, qty));
				}
			});
			addMapItemBtn.x = 186;
			addMapItemBtn.y = 128;
			addChild(addMapItemBtn);
		}
	}
}
