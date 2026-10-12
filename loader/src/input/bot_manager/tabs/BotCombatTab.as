package input.bot_manager.tabs {

	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.BotCommand;
	import commands.HuntCommand;
	import commands.KillCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotCombatTab extends Sprite {

		private var manager:BotManagerUI;

		private var monsterTargetInput:MyTextField;
		private var killModeOnceBtn:MyButton;
		private var killModeCountBtn:MyButton;
		private var killModeItemBtn:MyButton;
		private var currentKillMode:String = KillCommand.MODE_NONE;
		private var killCountContainer:Sprite;
		private var killCountInput:MyTextField;
		private var killItemContainer:Sprite;
		private var killItemNameInput:MyTextField;
		private var killItemQtyInput:MyTextField;
		private var huntModeCheckbox:MyCheckbox;
		private var addCombatBtn:MyButton;

		public function BotCombatTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// Monster Target Input
			const monsterLbl:TextField = UIUtils.createLabel("Monster Target (* for any):", UIUtils.TEXT_MUTED, 10.5);
			monsterLbl.y = 4;
			addChild(monsterLbl);

			monsterTargetInput = new MyTextField(contentW, 24);
			monsterTargetInput.y = 22;
			monsterTargetInput.text = "*";
			addChild(monsterTargetInput);

			// Kill Until Condition Selector
			const condLbl:TextField = UIUtils.createLabel("Kill Until (Condition):", UIUtils.TEXT_MUTED, 10.5);
			condLbl.y = 54;
			addChild(condLbl);

			const btnW:Number = 96;
			const btnH:Number = 22;

			killModeOnceBtn = new MyButton("Kill Once", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					setKillMode(KillCommand.MODE_NONE);
				});
			killModeOnceBtn.y = 88;
			addChild(killModeOnceBtn);

			killModeCountBtn = new MyButton("Kill Count", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					setKillMode(KillCommand.MODE_COUNT);
				});
			killModeCountBtn.x = btnW + 6;
			killModeCountBtn.y = 88;
			addChild(killModeCountBtn);

			killModeItemBtn = new MyButton("Kill for Items", 112, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					setKillMode(KillCommand.MODE_ITEM);
				});
			killModeItemBtn.x = (btnW + 6) * 2;
			killModeItemBtn.y = 88;
			addChild(killModeItemBtn);

			// Kill Count Section
			killCountContainer = new Sprite();
			killCountContainer.y = 118;
			addChild(killCountContainer);

			const countLbl:TextField = UIUtils.createLabel("Target Kill Count:", UIUtils.TEXT_MUTED, 10.5);
			killCountContainer.addChild(countLbl);

			killCountInput = new MyTextField(100, 24);
			killCountInput.y = 18;
			killCountInput.text = "1";
			killCountInput.restrict = "0-9";
			killCountContainer.addChild(killCountInput);

			// Kill Items Section
			killItemContainer = new Sprite();
			killItemContainer.y = 118;
			addChild(killItemContainer);

			const itemLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
			killItemContainer.addChild(itemLbl);

			killItemNameInput = new MyTextField(210, 24);
			killItemNameInput.y = 18;
			killItemContainer.addChild(killItemNameInput);

			const qtyLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			qtyLbl.x = 218;
			killItemContainer.addChild(qtyLbl);

			killItemQtyInput = new MyTextField(94, 24);
			killItemQtyInput.x = 218;
			killItemQtyInput.y = 18;
			killItemQtyInput.text = "1";
			killItemQtyInput.restrict = "0-9";
			killItemContainer.addChild(killItemQtyInput);

			// Hunt Mode Checkbox
			huntModeCheckbox = new MyCheckbox("Hunt Across Cells (Auto-search monster)", false, null, 10.5);
			huntModeCheckbox.x = 0;
			huntModeCheckbox.y = 180;
			addChild(huntModeCheckbox);

			// Add Combat Command Button
			addCombatBtn = new MyButton("Add Combat Command", contentW, 26, MyButton.TYPE_PRIMARY, onAddCombatCommandClick);
			addCombatBtn.y = 212;
			addChild(addCombatBtn);

			setKillMode(KillCommand.MODE_NONE);
		}

		public function setKillMode(mode:String):void {
			currentKillMode = mode;
			killModeOnceBtn.setType(mode == KillCommand.MODE_NONE ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			killModeOnceBtn.active = (mode == KillCommand.MODE_NONE);

			killModeCountBtn.setType(mode == KillCommand.MODE_COUNT ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			killModeCountBtn.active = (mode == KillCommand.MODE_COUNT);

			killModeItemBtn.setType(mode == KillCommand.MODE_ITEM ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			killModeItemBtn.active = (mode == KillCommand.MODE_ITEM);

			killCountContainer.visible = (mode == KillCommand.MODE_COUNT);
			killItemContainer.visible = (mode == KillCommand.MODE_ITEM);
		}

		private function onAddCombatCommandClick(e:MouseEvent):void {
			var isHunt:Boolean = (huntModeCheckbox != null && huntModeCheckbox.checked);
			createAndAddCombatCommand(isHunt);
		}

		private function createAndAddCombatCommand(isHunt:Boolean):void {
			var mon:String = monsterTargetInput.trimmedText;
			if (mon.length == 0)
				mon = "*";

			var cmd:BotCommand;
			if (currentKillMode == KillCommand.MODE_ITEM) {
				var itemName:String = killItemNameInput.trimmedText;
				var itemQty:int = parseInt(killItemQtyInput.text);
				if (itemName.length == 0)
					return;
				cmd = isHunt
					? new HuntCommand(mon, KillCommand.MODE_ITEM, 1, itemName, itemQty)
					: new KillCommand(mon, KillCommand.MODE_ITEM, 1, itemName, itemQty);
			}
			else if (currentKillMode == KillCommand.MODE_COUNT) {
				var kCount:int = parseInt(killCountInput.text);
				cmd = isHunt
					? new HuntCommand(mon, KillCommand.MODE_COUNT, kCount)
					: new KillCommand(mon, KillCommand.MODE_COUNT, kCount);
			}
			else {
				cmd = isHunt
					? new HuntCommand(mon, KillCommand.MODE_NONE)
					: new KillCommand(mon, KillCommand.MODE_NONE);
			}

			manager.addBotCommand(cmd);
		}
	}
}
