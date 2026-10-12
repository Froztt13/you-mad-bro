package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.BotCommand;
	import commands.GotoLabelCommand;
	import commands.LabelCommand;
	import commands.RestartBotCommand;
	import commands.StopBotCommand;
	import commands.conditions.BaseConditionalCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyDropdown;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotMiscTab extends Sprite {

		private var manager:BotManagerUI;

		private var miscLabelInput:MyTextField;
		private var miscCondDropdown:MyDropdown;
		private var miscCondVar1Label:TextField;
		private var miscCondVar1Input:MyTextField;
		private var miscCondVar2Label:TextField;
		private var miscCondVar2Input:MyTextField;

		public function BotMiscTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Label Section (1 input, 1 Add btn, 1 Goto btn)
			const lblTitle:TextField = UIUtils.createLabel("Label:", UIUtils.TEXT_MUTED, 10.5);
			lblTitle.y = 4;
			addChild(lblTitle);

			const currentLabelsBtn:Sprite = new Sprite();
			currentLabelsBtn.buttonMode = true;
			currentLabelsBtn.useHandCursor = true;
			currentLabelsBtn.x = 42;
			currentLabelsBtn.y = 4;

			const currentLabelsLink:TextField = UIUtils.createLabel("[Current Labels]", 0x38bdf8, 9.5, false);
			currentLabelsLink.selectable = false;
			currentLabelsLink.mouseEnabled = false;
			currentLabelsBtn.addChild(currentLabelsLink);

			currentLabelsBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					currentLabelsLink.textColor = 0x93c5fd;
				});
			currentLabelsBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					currentLabelsLink.textColor = 0x38bdf8;
				});
			currentLabelsBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					manager.openCurrentLabelsModal();
				});
			addChild(currentLabelsBtn);

			miscLabelInput = new MyTextField(184, 24);
			miscLabelInput.x = 0;
			miscLabelInput.y = 22;
			miscLabelInput.text = "";
			miscLabelInput.addEventListener(Event.CHANGE, function(e:Event):void {
					var sel:int = miscLabelInput.caretIndex;
					miscLabelInput.text = miscLabelInput.text.toUpperCase();
					miscLabelInput.setSelection(sel, sel);
				});
			addChild(miscLabelInput);

			const addLabelBtn:MyButton = new MyButton("Add", 66, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var name:String = miscLabelInput.trimmedText.toUpperCase();
					if (name.length > 0) {
						manager.addBotCommand(new LabelCommand(name));
					}
				});
			addLabelBtn.x = 190;
			addLabelBtn.y = 22;
			addChild(addLabelBtn);

			const gotoLabelBtn:MyButton = new MyButton("Goto", 66, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var name:String = miscLabelInput.trimmedText.toUpperCase();
					if (name.length > 0) {
						manager.addBotCommand(new GotoLabelCommand(name));
					}
				});
			gotoLabelBtn.x = 260;
			gotoLabelBtn.y = 22;
			addChild(gotoLabelBtn);

			// Divider between Label and Bot Controls
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 58);
			div1.graphics.lineTo(contentW, 58);
			addChild(div1);

			// 2. Bot Controls Section (Restart Bot, Stop Bot)
			const ctrlTitle:TextField = UIUtils.createLabel("Bot Controls:", UIUtils.TEXT_MUTED, 10.5);
			ctrlTitle.y = 66;
			addChild(ctrlTitle);

			const restartBtn:MyButton = new MyButton("Restart Bot", 100, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					manager.addBotCommand(new RestartBotCommand());
				});
			restartBtn.x = 0;
			restartBtn.y = 86;
			addChild(restartBtn);

			const stopCmdBtn:MyButton = new MyButton("Stop Bot", 100, 24, MyButton.TYPE_DANGER, function(e:MouseEvent):void {
					manager.addBotCommand(new StopBotCommand());
				});
			stopCmdBtn.x = 108;
			stopCmdBtn.y = 86;
			addChild(stopCmdBtn);

			// Divider between Bot Controls and Conditionals
			const div2:Shape = new Shape();
			div2.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div2.graphics.moveTo(0, 122);
			div2.graphics.lineTo(contentW, 122);
			addChild(div2);

			// 3. Conditional Command Section (Skip 1 command if false)
			const condTitle:TextField = UIUtils.createLabel("Condition (Skip 1 command if false):", UIUtils.TEXT_MUTED, 10.5);
			condTitle.y = 130;
			addChild(condTitle);

			const condItems:Array = BaseConditionalCommand.getAvailableConditions();

			miscCondDropdown = new MyDropdown(244, 24, condItems, onMiscConditionChange);
			miscCondDropdown.x = 0;
			miscCondDropdown.y = 150;
			addChild(miscCondDropdown);

			const addCondBtn:MyButton = new MyButton("Add", 76, 24, MyButton.TYPE_PRIMARY, onAddConditionClick);
			addCondBtn.x = 252;
			addCondBtn.y = 150;
			addChild(addCondBtn);

			miscCondVar1Label = UIUtils.createLabel("Name:", UIUtils.TEXT_MUTED, 10.5);
			miscCondVar1Label.x = 0;
			miscCondVar1Label.y = 180;
			addChild(miscCondVar1Label);

			miscCondVar2Label = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			miscCondVar2Label.x = 252;
			miscCondVar2Label.y = 180;
			addChild(miscCondVar2Label);

			miscCondVar1Input = new MyTextField(244, 24);
			miscCondVar1Input.x = 0;
			miscCondVar1Input.y = 196;
			miscCondVar1Input.text = "";
			addChild(miscCondVar1Input);

			miscCondVar2Input = new MyTextField(76, 24);
			miscCondVar2Input.x = 252;
			miscCondVar2Input.y = 196;
			miscCondVar2Input.text = "1";
			miscCondVar2Input.restrict = "0-9";
			addChild(miscCondVar2Input);

			updateConditionInputs(BotCommand.TYPE_IS_ITEM_IN_INV);
		}

		public function setLabelText(text:String):void {
			if (miscLabelInput != null) {
				miscLabelInput.text = text != null ? text.toUpperCase() : "";
			}
		}

		private function onMiscConditionChange(item:Object):void {
			if (item != null && item.value != null) {
				updateConditionInputs(String(item.value));
			}
		}

		private function updateConditionInputs(condType:String):void {
			var def:Object = BaseConditionalCommand.getDefinition(condType);
			if (def == null)
				return;

			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			if (def.var1Label != null && String(def.var1Label).length > 0) {
				miscCondVar1Label.visible = true;
				miscCondVar1Label.text = def.var1Label;
				miscCondVar1Input.visible = true;
				miscCondVar1Input.restrict = def.var1Restrict;
				miscCondVar1Input.width = (def.var2Label != null && String(def.var2Label).length > 0) ? 244 : contentW;
				miscCondVar1Input.text = (def.var1Default != null) ? def.var1Default : "";
			}
			else {
				miscCondVar1Label.visible = false;
				miscCondVar1Input.visible = false;
			}

			if (def.var2Label != null && String(def.var2Label).length > 0) {
				miscCondVar2Label.visible = true;
				miscCondVar2Label.text = def.var2Label;
				miscCondVar2Input.visible = true;
				miscCondVar2Input.restrict = def.var2Restrict;
				miscCondVar2Input.text = (def.var2Default != null) ? def.var2Default : "";
			}
			else {
				miscCondVar2Label.visible = false;
				miscCondVar2Input.visible = false;
			}
		}

		private function onAddConditionClick(e:MouseEvent):void {
			if (miscCondDropdown == null)
				return;
			var condType:String = String(miscCondDropdown.selectedValue);
			var def:Object = BaseConditionalCommand.getDefinition(condType);
			if (def == null)
				return;

			if (def.var1Label != null && String(def.var1Label).length > 0 && miscCondVar1Input.trimmedText.length == 0) {
				return;
			}

			var cmd:BaseConditionalCommand = BaseConditionalCommand.createCommand(
					condType,
					miscCondVar1Input.trimmedText,
					miscCondVar2Input.trimmedText
				);
			if (cmd != null) {
				manager.addBotCommand(cmd);
			}
		}
	}
}
