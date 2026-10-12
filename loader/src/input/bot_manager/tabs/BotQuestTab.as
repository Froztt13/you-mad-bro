package input.bot_manager.tabs {

	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.QuestAcceptCommand;
	import commands.QuestCompleteCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotQuestTab extends Sprite {

		private var manager:BotManagerUI;

		public function BotQuestTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			// Quest ID
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
		}
	}
}
