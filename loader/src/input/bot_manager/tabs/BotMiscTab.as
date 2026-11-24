package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	import commands.BlankCommand;
	import commands.BotCommand;
	import commands.GotoLabelCommand;
	import commands.LabelCommand;
	import commands.RestartBotCommand;
	import commands.SendPacketCommand;
	import commands.StopBotCommand;
	import commands.conditions.BaseConditionalCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotMiscTab extends Sprite {

		private var manager:BotManagerUI;

		private var miscLabelInput:MyTextField;
		private var selectedCondType:String = BotCommand.TYPE_IS_ITEM_IN_INV;
		private var miscCondSelector:Sprite;
		private var miscCondLabel:TextField;
		private var miscCondVar1Label:TextField;
		private var miscCondVar1Input:MyTextField;
		private var miscCondVar2Label:TextField;
		private var miscCondVar2Input:MyTextField;
		private var packetInput:MyTextField;
		private var packetForClientCheck:MyCheckbox;

		public function BotMiscTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 6;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Label Section (1 input, 1 Add btn, 1 Goto btn)
			const lblTitle:TextField = UIUtils.createLabel("Label:", UIUtils.TEXT_MUTED, 10.5);
			lblTitle.y = 0;
			addChild(lblTitle);

			const currentLabelsBtn:Sprite = new Sprite();
			currentLabelsBtn.buttonMode = true;
			currentLabelsBtn.useHandCursor = true;
			currentLabelsBtn.x = 42;
			currentLabelsBtn.y = 0;

			const currentLabelsLink:TextField = UIUtils.createLabel("[Browse Labels]", 0x38bdf8, 9.5, false);
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
			miscLabelInput.y = 17;
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
			addLabelBtn.y = 17;
			addChild(addLabelBtn);

			const gotoLabelBtn:MyButton = new MyButton("Goto", 66, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var name:String = miscLabelInput.trimmedText.toUpperCase();
					if (name.length > 0) {
						manager.addBotCommand(new GotoLabelCommand(name));
					}
				});
			gotoLabelBtn.x = 260;
			gotoLabelBtn.y = 17;
			addChild(gotoLabelBtn);

			// Divider between Label and Conditionals
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 51);
			div1.graphics.lineTo(contentW, 51);
			addChild(div1);

			// 2. Conditional Command Section (Skip 1 command if false)
			const condTitle:TextField = UIUtils.createLabel("Condition (Skip 1 command if false):", UIUtils.TEXT_MUTED, 10.5);
			condTitle.y = 61;
			addChild(condTitle);

			const browseCondBtn:Sprite = new Sprite();
			browseCondBtn.buttonMode = true;
			browseCondBtn.useHandCursor = true;
			browseCondBtn.x = 188;
			browseCondBtn.y = 61;

			const browseCondLink:TextField = UIUtils.createLabel("[Browse Conditions]", 0x38bdf8, 9.5, false);
			browseCondLink.selectable = false;
			browseCondLink.mouseEnabled = false;
			browseCondBtn.addChild(browseCondLink);

			browseCondBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					browseCondLink.textColor = 0x93c5fd;
				});
			browseCondBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					browseCondLink.textColor = 0x38bdf8;
				});
			browseCondBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					manager.openConditionsModal();
				});
			addChild(browseCondBtn);

			// Clickable Condition Selector Box
			miscCondSelector = new Sprite();
			miscCondSelector.buttonMode = true;
			miscCondSelector.useHandCursor = true;
			miscCondSelector.x = 0;
			miscCondSelector.y = 78;

			const selectorBg:Shape = new Shape();
			UIUtils.drawRoundedRect(selectorBg.graphics, 0, 0, 244, 24, 4, UIUtils.BG_RECESSED, 1.0, UIUtils.BORDER_NORMAL, 1);
			miscCondSelector.addChild(selectorBg);

			miscCondLabel = UIUtils.createLabel("", UIUtils.TEXT_MAIN, 11, false, TextFormatAlign.LEFT);
			miscCondLabel.x = 8;
			miscCondLabel.y = int((24 - 16) / 2);
			miscCondLabel.width = 216;
			miscCondLabel.mouseEnabled = false;
			miscCondSelector.addChild(miscCondLabel);

			const selectorArrow:TextField = UIUtils.createLabel("▾", UIUtils.TEXT_MUTED, 10, false, TextFormatAlign.CENTER);
			selectorArrow.x = 224;
			selectorArrow.y = int((24 - 14) / 2);
			selectorArrow.width = 16;
			selectorArrow.mouseEnabled = false;
			miscCondSelector.addChild(selectorArrow);

			miscCondSelector.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(selectorBg.graphics, 0, 0, 244, 24, 4, UIUtils.BG_HOVER, 1.0, UIUtils.BORDER_HOVER, 1);
					selectorArrow.textColor = 0x93c5fd;
				});
			miscCondSelector.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(selectorBg.graphics, 0, 0, 244, 24, 4, UIUtils.BG_RECESSED, 1.0, UIUtils.BORDER_NORMAL, 1);
					selectorArrow.textColor = UIUtils.TEXT_MUTED;
				});
			miscCondSelector.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					manager.openConditionsModal();
				});
			addChild(miscCondSelector);

			const addCondBtn:MyButton = new MyButton("Add", 76, 24, MyButton.TYPE_PRIMARY, onAddConditionClick);
			addCondBtn.x = 252;
			addCondBtn.y = 78;
			addChild(addCondBtn);

			miscCondVar1Label = UIUtils.createLabel("Name:", UIUtils.TEXT_MUTED, 10.5);
			miscCondVar1Label.x = 0;
			miscCondVar1Label.y = 107;
			addChild(miscCondVar1Label);

			miscCondVar2Label = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			miscCondVar2Label.x = 252;
			miscCondVar2Label.y = 107;
			addChild(miscCondVar2Label);

			miscCondVar1Input = new MyTextField(244, 24);
			miscCondVar1Input.x = 0;
			miscCondVar1Input.y = 123;
			miscCondVar1Input.text = "";
			addChild(miscCondVar1Input);

			miscCondVar2Input = new MyTextField(76, 24);
			miscCondVar2Input.x = 252;
			miscCondVar2Input.y = 123;
			miscCondVar2Input.text = "1";
			miscCondVar2Input.restrict = "0-9";
			addChild(miscCondVar2Input);

			// Divider between Conditionals and Send Packet
			const div2:Shape = new Shape();
			div2.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div2.graphics.moveTo(0, 157);
			div2.graphics.lineTo(contentW, 157);
			addChild(div2);

			// 3. Send Packet Section
			const pktTitle:TextField = UIUtils.createLabel("Packet:", UIUtils.TEXT_MUTED, 10.5);
			pktTitle.y = 167;
			addChild(pktTitle);

			packetForClientCheck = new MyCheckbox("For Client", false, null, 10);
			packetForClientCheck.x = 252;
			packetForClientCheck.y = 165;
			addChild(packetForClientCheck);

			packetInput = new MyTextField(244, 24);
			packetInput.x = 0;
			packetInput.y = 184;
			packetInput.text = "";
			addChild(packetInput);

			const sendPktBtn:MyButton = new MyButton("Send", 76, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var rawPkt:String = packetInput.trimmedText;
					if (rawPkt.length > 0) {
						var isClient:Boolean = (packetForClientCheck != null) ? packetForClientCheck.checked : false;
						manager.addBotCommand(new SendPacketCommand(rawPkt, isClient));
					}
				});
			sendPktBtn.x = 252;
			sendPktBtn.y = 184;
			addChild(sendPktBtn);

			// Divider between Send Packet and Bot Controls
			const div3:Shape = new Shape();
			div3.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div3.graphics.moveTo(0, 218);
			div3.graphics.lineTo(contentW, 218);
			addChild(div3);

			// 4. Bot Controls Section (Bottom)
			const ctrlTitle:TextField = UIUtils.createLabel("Bot Controls:", UIUtils.TEXT_MUTED, 10.5);
			ctrlTitle.y = 228;
			addChild(ctrlTitle);

			const restartBtn:MyButton = new MyButton("Restart Bot", 100, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					manager.addBotCommand(new RestartBotCommand());
				});
			restartBtn.x = 0;
			restartBtn.y = 245;
			addChild(restartBtn);

			const stopCmdBtn:MyButton = new MyButton("Stop Bot", 100, 24, MyButton.TYPE_DANGER, function(e:MouseEvent):void {
					manager.addBotCommand(new StopBotCommand());
				});
			stopCmdBtn.x = 108;
			stopCmdBtn.y = 245;
			addChild(stopCmdBtn);

			const blankCmdBtn:MyButton = new MyButton("Blank Cmd", 100, 24, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					manager.addBotCommand(new BlankCommand());
				});
			blankCmdBtn.x = 216;
			blankCmdBtn.y = 245;
			addChild(blankCmdBtn);

			setSelectedCondition(BotCommand.TYPE_IS_ITEM_IN_INV);
		}

		public function setLabelText(text:String):void {
			if (miscLabelInput != null) {
				miscLabelInput.text = text != null ? text.toUpperCase() : "";
			}
		}

		public function setSelectedCondition(condType:String):void {
			selectedCondType = condType;
			var def:Object = BaseConditionalCommand.getDefinition(condType);
			if (def != null && miscCondLabel != null) {
				miscCondLabel.text = def.label;
			}
			updateConditionInputs(condType);
		}

		public function get selectedConditionType():String {
			return selectedCondType;
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
			if (selectedCondType == null)
				return;
			var def:Object = BaseConditionalCommand.getDefinition(selectedCondType);
			if (def == null)
				return;

			if (def.var1Label != null && String(def.var1Label).length > 0 && miscCondVar1Input.trimmedText.length == 0) {
				return;
			}

			var cmd:BaseConditionalCommand = BaseConditionalCommand.createCommand(
					selectedCondType,
					miscCondVar1Input.trimmedText,
					miscCondVar2Input.trimmedText
				);
			if (cmd != null) {
				manager.addBotCommand(cmd);
			}
		}
	}
}
