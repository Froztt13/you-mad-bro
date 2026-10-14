package input.bot_manager.modals {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.*;
	import commands.conditions.BaseConditionalCommand;
	import engine.BotEngine;
	import ui.CloseButton;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyDropdown;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotEditCommandModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var botEngine:BotEngine;
		private var onSaveCallback:Function;

		private var editModalSub:TextField;
		private var editModalFormContainer:Sprite;

		private var editingIndex:int = -1;
		private var editingCmd:BotCommand = null;

		// Form controls
		private var editKillMode:String = KillCommand.MODE_NONE;
		private var editMonInput:MyTextField;
		private var editKillOnceBtn:MyButton;
		private var editKillCountBtn:MyButton;
		private var editKillItemBtn:MyButton;
		private var editKillCountBox:Sprite;
		private var editKillCountInput:MyTextField;
		private var editKillItemBox:Sprite;
		private var editKillItemNameInput:MyTextField;
		private var editKillItemQtyInput:MyTextField;
		private var editHuntCheckbox:MyCheckbox;
		private var editMostMonstersCheckbox:MyCheckbox;

		private var editMapInput:MyTextField;
		private var editCellInput:MyTextField;
		private var editPadInput:MyTextField;

		private var editWalkXInput:MyTextField;
		private var editWalkYInput:MyTextField;

		private var editQuestIdInput:MyTextField;
		private var editQuestItemIdInput:MyTextField;
		private var editMapItemIdInput:MyTextField;
		private var editMapItemQtyInput:MyTextField;

		private var editDelayInput:MyTextField;

		private var editItemTransferInput:MyTextField;
		private var editBuyShopIdInput:MyTextField;
		private var editBuyQtyInput:MyTextField;

		private var editNotifTitleInput:MyTextField;
		private var editNotifMsgInput:MyTextField;

		private var editLabelInput:MyTextField;

		private var editCondDropdown:MyDropdown;
		private var editCondVar1Label:TextField;
		private var editCondVar1Input:MyTextField;
		private var editCondVar2Label:TextField;
		private var editCondVar2Input:MyTextField;

		public function BotEditCommandModal(botEngine:BotEngine, onSaveCallback:Function = null) {
			super();
			this.botEngine = botEngine;
			this.onSaveCallback = onSaveCallback;
			this.visible = false;

			buildUI();
		}

		private function buildUI():void {
			// Dimmer
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			addChild(dimmer);

			// Card
			const boxW:Number = 400;
			const boxH:Number = 260;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Title & Subtitle
			const title:TextField = UIUtils.createLabel("EDIT COMMAND", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

			editModalSub = UIUtils.createLabel("", UIUtils.TEXT_DIM, 9.5, false);
			editModalSub.x = boxX + 115;
			editModalSub.y = boxY + 14;
			editModalSub.width = 200;
			addChild(editModalSub);

			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = boxX + boxW - 32;
			closeBtn.y = boxY + 10;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});
			addChild(closeBtn);

			// Divider under header
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(boxX + 16, boxY + 36);
			div.graphics.lineTo(boxX + boxW - 16, boxY + 36);
			addChild(div);

			// Form Container
			editModalFormContainer = new Sprite();
			editModalFormContainer.x = boxX + 16;
			editModalFormContainer.y = boxY + 44;
			addChild(editModalFormContainer);

			// Footer Buttons
			const saveEditBtn:MyButton = new MyButton("Save Changes", 100, 26, MyButton.TYPE_PRIMARY, onSaveEditClick);
			saveEditBtn.x = boxX + boxW - 16 - 100;
			saveEditBtn.y = boxY + boxH - 38;
			addChild(saveEditBtn);

			const cancelEditBtn:MyButton = new MyButton("Cancel", 64, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					close();
				});
			cancelEditBtn.x = saveEditBtn.x - 70;
			cancelEditBtn.y = boxY + boxH - 38;
			addChild(cancelEditBtn);
		}

		public function open(index:int, cmd:BotCommand):void {
			if (cmd == null)
				return;
			editingIndex = index;
			editingCmd = cmd;
			this.visible = true;

			// Clear previous form controls
			while (editModalFormContainer.numChildren > 0) {
				editModalFormContainer.removeChildAt(0);
			}

			editModalSub.text = "#" + (index + 1) + " " + cmd.type.toUpperCase();

			const formW:Number = 368;

			if (cmd is KillCommand) {
				var kcmd:KillCommand = cmd as KillCommand;
				editKillMode = kcmd.killMode;

				var monLbl:TextField = UIUtils.createLabel("Monster Target (* for any):", UIUtils.TEXT_MUTED, 10.5);
				monLbl.y = 0;
				editModalFormContainer.addChild(monLbl);

				editMonInput = new MyTextField(formW, 24);
				editMonInput.y = 18;
				editMonInput.text = kcmd.monster;
				editModalFormContainer.addChild(editMonInput);

				var condLbl:TextField = UIUtils.createLabel("Kill Until:", UIUtils.TEXT_MUTED, 10.5);
				condLbl.y = 50;
				editModalFormContainer.addChild(condLbl);

				var btnW:Number = 110;
				var btnH:Number = 22;

				editKillOnceBtn = new MyButton("Kill Once", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_NONE);
					});
				editKillOnceBtn.y = 68;
				editModalFormContainer.addChild(editKillOnceBtn);

				editKillCountBtn = new MyButton("Kill Count", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_COUNT);
					});
				editKillCountBtn.x = btnW + 6;
				editKillCountBtn.y = 68;
				editModalFormContainer.addChild(editKillCountBtn);

				editKillItemBtn = new MyButton("Kill for Items", 124, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_ITEM);
					});
				editKillItemBtn.x = (btnW + 6) * 2;
				editKillItemBtn.y = 68;
				editModalFormContainer.addChild(editKillItemBtn);

				// Kill Count Box
				editKillCountBox = new Sprite();
				editKillCountBox.y = 96;
				var cLbl:TextField = UIUtils.createLabel("Target Kill Count:", UIUtils.TEXT_MUTED, 10.5);
				editKillCountBox.addChild(cLbl);
				editKillCountInput = new MyTextField(100, 24);
				editKillCountInput.y = 18;
				editKillCountInput.text = String(kcmd.killCount);
				editKillCountInput.restrict = "0-9";
				editKillCountBox.addChild(editKillCountInput);
				editModalFormContainer.addChild(editKillCountBox);

				// Kill Item Box
				editKillItemBox = new Sprite();
				editKillItemBox.y = 96;
				var inLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
				editKillItemBox.addChild(inLbl);
				editKillItemNameInput = new MyTextField(260, 24);
				editKillItemNameInput.y = 18;
				editKillItemNameInput.text = kcmd.itemName;
				editKillItemBox.addChild(editKillItemNameInput);

				var iqLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
				iqLbl.x = 268;
				editKillItemBox.addChild(iqLbl);
				editKillItemQtyInput = new MyTextField(100, 24);
				editKillItemQtyInput.x = 268;
				editKillItemQtyInput.y = 18;
				editKillItemQtyInput.text = String(kcmd.itemQty);
				editKillItemQtyInput.restrict = "0-9";
				editKillItemBox.addChild(editKillItemQtyInput);
				editModalFormContainer.addChild(editKillItemBox);

				// Hunt Checkbox
				var isHuntCmd:Boolean = (cmd is HuntCommand);
				var isMostOnly:Boolean = isHuntCmd ? (cmd as HuntCommand).mostMonstersOnly : true;
				editHuntCheckbox = new MyCheckbox("Hunt Across Cells", isHuntCmd, function(checked:Boolean):void {
						if (editMostMonstersCheckbox != null) {
							editMostMonstersCheckbox.visible = checked;
						}
					}, 10.5);
				editHuntCheckbox.x = 0;
				editHuntCheckbox.y = 146;
				editModalFormContainer.addChild(editHuntCheckbox);

				editMostMonstersCheckbox = new MyCheckbox("Most Monsters Cell Only", isMostOnly, null, 10.5);
				editMostMonstersCheckbox.x = 140;
				editMostMonstersCheckbox.y = 146;
				editMostMonstersCheckbox.visible = isHuntCmd;
				editModalFormContainer.addChild(editMostMonstersCheckbox);

				setEditKillMode(editKillMode);
			}
			else if (cmd is JoinCommand || cmd is JumpCommand) {
				var isJoin:Boolean = (cmd is JoinCommand);
				var jcmd:JoinCommand = isJoin ? (cmd as JoinCommand) : null;
				var jumpCmd:JumpCommand = !isJoin ? (cmd as JumpCommand) : null;

				if (isJoin) {
					var mLbl:TextField = UIUtils.createLabel("Map Name:", UIUtils.TEXT_MUTED, 10.5);
					mLbl.y = 0;
					editModalFormContainer.addChild(mLbl);

					editMapInput = new MyTextField(formW, 24);
					editMapInput.y = 18;
					editMapInput.text = jcmd.map;
					editModalFormContainer.addChild(editMapInput);
				}

				var cellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
				cellLbl.y = isJoin ? 52 : 0;
				editModalFormContainer.addChild(cellLbl);

				editCellInput = new MyTextField(178, 24);
				editCellInput.y = isJoin ? 70 : 18;
				editCellInput.text = isJoin ? jcmd.cell : jumpCmd.cell;
				editModalFormContainer.addChild(editCellInput);

				var padLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
				padLbl.x = 186;
				padLbl.y = isJoin ? 52 : 0;
				editModalFormContainer.addChild(padLbl);

				editPadInput = new MyTextField(182, 24);
				editPadInput.x = 186;
				editPadInput.y = isJoin ? 70 : 18;
				editPadInput.text = isJoin ? jcmd.pad : jumpCmd.pad;
				editModalFormContainer.addChild(editPadInput);
			}
			else if (cmd is QuestAcceptCommand || cmd is QuestCompleteCommand) {
				var isAccept:Boolean = (cmd is QuestAcceptCommand);
				var qacmd:QuestAcceptCommand = isAccept ? (cmd as QuestAcceptCommand) : null;
				var qccmd:QuestCompleteCommand = !isAccept ? (cmd as QuestCompleteCommand) : null;

				var qLbl:TextField = UIUtils.createLabel("Quest ID:", UIUtils.TEXT_MUTED, 10.5);
				qLbl.y = 0;
				editModalFormContainer.addChild(qLbl);

				editQuestIdInput = new MyTextField(178, 24);
				editQuestIdInput.y = 18;
				editQuestIdInput.text = String(isAccept ? qacmd.questId : qccmd.questId);
				editQuestIdInput.restrict = "0-9";
				editModalFormContainer.addChild(editQuestIdInput);

				if (!isAccept) {
					var itemLbl:TextField = UIUtils.createLabel("Item ID (Reward -1=default):", UIUtils.TEXT_MUTED, 10.5);
					itemLbl.x = 186;
					itemLbl.y = 0;
					editModalFormContainer.addChild(itemLbl);

					editQuestItemIdInput = new MyTextField(182, 24);
					editQuestItemIdInput.x = 186;
					editQuestItemIdInput.y = 18;
					editQuestItemIdInput.text = String(qccmd.itemId);
					editQuestItemIdInput.restrict = "0-9\\-";
					editModalFormContainer.addChild(editQuestItemIdInput);
				}
			}
			else if (cmd is DelayCommand) {
				var dcmd:DelayCommand = cmd as DelayCommand;
				var dLbl:TextField = UIUtils.createLabel("Delay (Seconds):", UIUtils.TEXT_MUTED, 10.5);
				dLbl.y = 0;
				editModalFormContainer.addChild(dLbl);

				editDelayInput = new MyTextField(120, 24);
				editDelayInput.y = 18;
				editDelayInput.text = String(dcmd.delaySeconds);
				editDelayInput.restrict = "0-9.";
				editModalFormContainer.addChild(editDelayInput);
			}
			else if (cmd is TransferToBankCommand || cmd is TransferToInventoryCommand || cmd is EquipItemCommand) {
				var itmName:String = "";
				if (cmd is EquipItemCommand) {
					itmName = (cmd as EquipItemCommand).itemName;
				}
				else if (cmd is TransferToBankCommand) {
					itmName = (cmd as TransferToBankCommand).itemName;
				}
				else if (cmd is TransferToInventoryCommand) {
					itmName = (cmd as TransferToInventoryCommand).itemName;
				}

				var tLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
				tLbl.y = 0;
				editModalFormContainer.addChild(tLbl);

				editItemTransferInput = new MyTextField(formW, 24);
				editItemTransferInput.y = 18;
				editItemTransferInput.text = itmName;
				editModalFormContainer.addChild(editItemTransferInput);
			}
			else if (cmd is WalkCommand) {
				var wcmd:WalkCommand = cmd as WalkCommand;

				var wxLbl:TextField = UIUtils.createLabel("X:", UIUtils.TEXT_MUTED, 10.5);
				wxLbl.y = 0;
				editModalFormContainer.addChild(wxLbl);

				editWalkXInput = new MyTextField(100, 24);
				editWalkXInput.restrict = "0-9";
				editWalkXInput.y = 18;
				editWalkXInput.text = String(wcmd.x);
				editModalFormContainer.addChild(editWalkXInput);

				var wyLbl:TextField = UIUtils.createLabel("Y:", UIUtils.TEXT_MUTED, 10.5);
				wyLbl.x = 110;
				wyLbl.y = 0;
				editModalFormContainer.addChild(wyLbl);

				editWalkYInput = new MyTextField(100, 24);
				editWalkYInput.restrict = "0-9";
				editWalkYInput.x = 110;
				editWalkYInput.y = 18;
				editWalkYInput.text = String(wcmd.y);
				editModalFormContainer.addChild(editWalkYInput);
			}
			else if (cmd is GetMapItemCommand) {
				var gmicmd:GetMapItemCommand = cmd as GetMapItemCommand;
				var gmiHalfW:Number = int((formW - 10) / 2);

				var gmiLbl:TextField = UIUtils.createLabel("Item ID:", UIUtils.TEXT_MUTED, 10.5);
				gmiLbl.y = 0;
				editModalFormContainer.addChild(gmiLbl);

				editMapItemIdInput = new MyTextField(gmiHalfW, 24);
				editMapItemIdInput.restrict = "0-9";
				editMapItemIdInput.y = 18;
				editMapItemIdInput.text = String(gmicmd.itemId);
				editModalFormContainer.addChild(editMapItemIdInput);

				var gmiQtyLbl:TextField = UIUtils.createLabel("Qty (Repeat):", UIUtils.TEXT_MUTED, 10.5);
				gmiQtyLbl.x = gmiHalfW + 10;
				gmiQtyLbl.y = 0;
				editModalFormContainer.addChild(gmiQtyLbl);

				editMapItemQtyInput = new MyTextField(gmiHalfW, 24);
				editMapItemQtyInput.restrict = "0-9";
				editMapItemQtyInput.x = gmiHalfW + 10;
				editMapItemQtyInput.y = 18;
				editMapItemQtyInput.text = String(gmicmd.qty > 0 ? gmicmd.qty : 1);
				editModalFormContainer.addChild(editMapItemQtyInput);
			}
			else if (cmd is BuyItemCommand) {
				var bicmd:BuyItemCommand = cmd as BuyItemCommand;

				var biNameLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
				biNameLbl.y = 0;
				editModalFormContainer.addChild(biNameLbl);

				editItemTransferInput = new MyTextField(formW, 24);
				editItemTransferInput.y = 18;
				editItemTransferInput.text = bicmd.itemName;
				editModalFormContainer.addChild(editItemTransferInput);

				var biShopLbl:TextField = UIUtils.createLabel("Shop ID (0 = open shop):", UIUtils.TEXT_MUTED, 10.5);
				biShopLbl.y = 52;
				editModalFormContainer.addChild(biShopLbl);

				editBuyShopIdInput = new MyTextField(178, 24);
				editBuyShopIdInput.restrict = "0-9";
				editBuyShopIdInput.y = 70;
				editBuyShopIdInput.text = String(bicmd.shopId);
				editModalFormContainer.addChild(editBuyShopIdInput);

				var biQtyLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
				biQtyLbl.x = 186;
				biQtyLbl.y = 52;
				editModalFormContainer.addChild(biQtyLbl);

				editBuyQtyInput = new MyTextField(182, 24);
				editBuyQtyInput.restrict = "0-9";
				editBuyQtyInput.x = 186;
				editBuyQtyInput.y = 70;
				editBuyQtyInput.text = String(bicmd.qty);
				editModalFormContainer.addChild(editBuyQtyInput);
			}
			else if (cmd is NotifCommand) {
				var ncmd:NotifCommand = cmd as NotifCommand;
				var ntLbl:TextField = UIUtils.createLabel("Alert Title:", UIUtils.TEXT_MUTED, 10.5);
				ntLbl.y = 0;
				editModalFormContainer.addChild(ntLbl);

				editNotifTitleInput = new MyTextField(formW, 24);
				editNotifTitleInput.y = 18;
				editNotifTitleInput.text = ncmd.title;
				editModalFormContainer.addChild(editNotifTitleInput);

				var nmLbl:TextField = UIUtils.createLabel("Alert Message:", UIUtils.TEXT_MUTED, 10.5);
				nmLbl.y = 52;
				editModalFormContainer.addChild(nmLbl);

				editNotifMsgInput = new MyTextField(formW, 24);
				editNotifMsgInput.y = 70;
				editNotifMsgInput.text = ncmd.message;
				editModalFormContainer.addChild(editNotifMsgInput);
			}
			else if (cmd is LabelCommand || cmd is GotoLabelCommand) {
				var isLabel:Boolean = (cmd is LabelCommand);
				var lcmd:LabelCommand = isLabel ? (cmd as LabelCommand) : null;
				var glcmd:GotoLabelCommand = !isLabel ? (cmd as GotoLabelCommand) : null;

				var labelLbl:TextField = UIUtils.createLabel("Label Name:", UIUtils.TEXT_MUTED, 10.5);
				labelLbl.y = 0;
				editModalFormContainer.addChild(labelLbl);

				editLabelInput = new MyTextField(formW, 24);
				editLabelInput.y = 18;
				editLabelInput.text = isLabel ? lcmd.labelName : glcmd.labelName;
				editLabelInput.addEventListener(Event.CHANGE, function(e:Event):void {
						var sel:int = editLabelInput.caretIndex;
						editLabelInput.text = editLabelInput.text.toUpperCase();
						editLabelInput.setSelection(sel, sel);
					});
				editModalFormContainer.addChild(editLabelInput);
			}
			else if (cmd is RestartBotCommand || cmd is StopBotCommand) {
				var infoLbl:TextField = UIUtils.createLabel("No editable parameters for this command.", UIUtils.TEXT_MUTED, 10.5);
				infoLbl.y = 20;
				editModalFormContainer.addChild(infoLbl);
			}
			else if (cmd is BaseConditionalCommand) {
				var bccmd:BaseConditionalCommand = cmd as BaseConditionalCommand;

				var cTypeLbl:TextField = UIUtils.createLabel("Condition Type: " + bccmd.commandLabel, UIUtils.TEXT_MAIN, 10.5, true);
				cTypeLbl.y = 0;
				editModalFormContainer.addChild(cTypeLbl);

				var cDef:Object = BaseConditionalCommand.getDefinition(bccmd.type);
				var hasV1:Boolean = (cDef != null && cDef.var1Label != null && String(cDef.var1Label).length > 0);
				var hasV2:Boolean = (cDef != null && cDef.var2Label != null && String(cDef.var2Label).length > 0);

				if (hasV1) {
					editCondVar1Label = UIUtils.createLabel(cDef.var1Label, UIUtils.TEXT_MUTED, 10);
					editCondVar1Label.y = 28;
					editModalFormContainer.addChild(editCondVar1Label);

					var w1:Number = hasV2 ? 260 : formW;
					editCondVar1Input = new MyTextField(w1, 24);
					editCondVar1Input.y = 46;
					editCondVar1Input.text = bccmd.var1;
					editCondVar1Input.restrict = cDef.var1Restrict;
					editModalFormContainer.addChild(editCondVar1Input);
				}

				if (hasV2) {
					editCondVar2Label = UIUtils.createLabel(cDef.var2Label, UIUtils.TEXT_MUTED, 10);
					editCondVar2Label.x = 268;
					editCondVar2Label.y = 28;
					editModalFormContainer.addChild(editCondVar2Label);

					editCondVar2Input = new MyTextField(100, 24);
					editCondVar2Input.x = 268;
					editCondVar2Input.y = 46;
					editCondVar2Input.text = bccmd.var2;
					editCondVar2Input.restrict = cDef.var2Restrict;
					editModalFormContainer.addChild(editCondVar2Input);
				}

				if (!hasV1 && !hasV2) {
					var noParamsLbl:TextField = UIUtils.createLabel("No parameters required for this condition.", UIUtils.TEXT_MUTED, 10.5);
					noParamsLbl.y = 28;
					editModalFormContainer.addChild(noParamsLbl);
				}
			}
		}

		public function close():void {
			this.visible = false;
		}

		private function setEditKillMode(mode:String):void {
			editKillMode = mode;
			if (editKillOnceBtn != null) {
				editKillOnceBtn.setType(mode == KillCommand.MODE_NONE ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillOnceBtn.active = (mode == KillCommand.MODE_NONE);
			}
			if (editKillCountBtn != null) {
				editKillCountBtn.setType(mode == KillCommand.MODE_COUNT ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillCountBtn.active = (mode == KillCommand.MODE_COUNT);
			}
			if (editKillItemBtn != null) {
				editKillItemBtn.setType(mode == KillCommand.MODE_ITEM ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillItemBtn.active = (mode == KillCommand.MODE_ITEM);
			}

			if (editKillCountBox != null) {
				editKillCountBox.visible = (mode == KillCommand.MODE_COUNT);
			}
			if (editKillItemBox != null) {
				editKillItemBox.visible = (mode == KillCommand.MODE_ITEM);
			}
		}

		private function onSaveEditClick(e:MouseEvent):void {
			if (editingCmd == null || editingIndex < 0 || editingIndex >= botEngine.commandList.length) {
				close();
				return;
			}

			if (editingCmd is KillCommand) {
				var mon:String = editMonInput.trimmedText;
				var finalMon:String = (mon.length > 0) ? mon : "*";
				var finalCount:int = (editKillMode == KillCommand.MODE_COUNT) ? Math.max(1, parseInt(editKillCountInput.text)) : 1;
				var finalItem:String = (editKillMode == KillCommand.MODE_ITEM) ? editKillItemNameInput.trimmedText : "";
				var finalQty:int = (editKillMode == KillCommand.MODE_ITEM) ? Math.max(1, parseInt(editKillItemQtyInput.text)) : 1;
				var isHuntEdit:Boolean = (editHuntCheckbox != null && editHuntCheckbox.checked);
				var isMostOnlyEdit:Boolean = (isHuntEdit && editMostMonstersCheckbox != null && editMostMonstersCheckbox.checked);

				var newCmd:BotCommand;
				if (isHuntEdit) {
					newCmd = new HuntCommand(finalMon, editKillMode, finalCount, finalItem, finalQty, isMostOnlyEdit);
				}
				else {
					newCmd = new KillCommand(finalMon, editKillMode, finalCount, finalItem, finalQty);
				}
				botEngine.commandList[editingIndex] = newCmd;
			}
			else if (editingCmd is JoinCommand) {
				var jcmd:JoinCommand = editingCmd as JoinCommand;
				jcmd.map = editMapInput.trimmedText;
				jcmd.cell = editCellInput.trimmedText.length > 0 ? editCellInput.trimmedText : "Enter";
				jcmd.pad = editPadInput.trimmedText.length > 0 ? editPadInput.trimmedText : "Spawn";
			}
			else if (editingCmd is JumpCommand) {
				var jumpCmd:JumpCommand = editingCmd as JumpCommand;
				jumpCmd.cell = editCellInput.trimmedText.length > 0 ? editCellInput.trimmedText : "Enter";
				jumpCmd.pad = editPadInput.trimmedText.length > 0 ? editPadInput.trimmedText : "Spawn";
			}
			else if (editingCmd is QuestAcceptCommand) {
				var qacmd:QuestAcceptCommand = editingCmd as QuestAcceptCommand;
				var qid:int = parseInt(editQuestIdInput.text);
				if (qid > 0) {
					qacmd.questId = qid;
				}
			}
			else if (editingCmd is QuestCompleteCommand) {
				var qccmd:QuestCompleteCommand = editingCmd as QuestCompleteCommand;
				var qid2:int = parseInt(editQuestIdInput.text);
				if (qid2 > 0) {
					qccmd.questId = qid2;
				}
				qccmd.itemId = parseInt(editQuestItemIdInput.text);
			}
			else if (editingCmd is DelayCommand) {
				var dcmd:DelayCommand = editingCmd as DelayCommand;
				var s:Number = parseFloat(editDelayInput.text);
				if (!isNaN(s) && s > 0) {
					dcmd.delaySeconds = s;
				}
			}
			else if (editingCmd is TransferToBankCommand) {
				var tbcmd:TransferToBankCommand = editingCmd as TransferToBankCommand;
				var iname1:String = editItemTransferInput.trimmedText;
				if (iname1.length > 0) {
					tbcmd.itemName = iname1;
				}
			}
			else if (editingCmd is TransferToInventoryCommand) {
				var ticmd:TransferToInventoryCommand = editingCmd as TransferToInventoryCommand;
				var iname2:String = editItemTransferInput.trimmedText;
				if (iname2.length > 0) {
					ticmd.itemName = iname2;
				}
			}
			else if (editingCmd is EquipItemCommand) {
				var eqcmd:EquipItemCommand = editingCmd as EquipItemCommand;
				var iname3:String = editItemTransferInput.trimmedText;
				if (iname3.length > 0) {
					eqcmd.itemName = iname3;
				}
			}
			else if (editingCmd is WalkCommand) {
				var wcmdEdit:WalkCommand = editingCmd as WalkCommand;
				var wxVal:int = parseInt(editWalkXInput.trimmedText);
				var wyVal:int = parseInt(editWalkYInput.trimmedText);
				if (!isNaN(wxVal)) {
					wcmdEdit.x = wxVal;
				}
				if (!isNaN(wyVal)) {
					wcmdEdit.y = wyVal;
				}
			}
			else if (editingCmd is GetMapItemCommand) {
				var gmicmdEdit:GetMapItemCommand = editingCmd as GetMapItemCommand;
				var gmiId:int = parseInt(editMapItemIdInput.trimmedText);
				if (!isNaN(gmiId) && gmiId > 0) {
					gmicmdEdit.itemId = gmiId;
				}
				var gmiQty:int = parseInt(editMapItemQtyInput.trimmedText);
				if (!isNaN(gmiQty) && gmiQty > 0) {
					gmicmdEdit.qty = gmiQty;
				}
				else {
					gmicmdEdit.qty = 1;
				}
			}
			else if (editingCmd is BuyItemCommand) {
				var bicmdEdit:BuyItemCommand = editingCmd as BuyItemCommand;
				var bName:String = editItemTransferInput.trimmedText;
				if (bName.length > 0) {
					bicmdEdit.itemName = bName;
				}
				var bSid:int = parseInt(editBuyShopIdInput.trimmedText);
				if (!isNaN(bSid)) {
					bicmdEdit.shopId = bSid;
				}
				var bQty:int = parseInt(editBuyQtyInput.trimmedText);
				if (!isNaN(bQty) && bQty > 0) {
					bicmdEdit.qty = bQty;
				}
			}
			else if (editingCmd is NotifCommand) {
				var ncmdEdit:NotifCommand = editingCmd as NotifCommand;
				var tText:String = editNotifTitleInput.trimmedText;
				var mText:String = editNotifMsgInput.trimmedText;
				if (tText.length > 0) {
					ncmdEdit.title = tText;
				}
				ncmdEdit.message = mText;
			}
			else if (editingCmd is LabelCommand) {
				var lcmdEdit:LabelCommand = editingCmd as LabelCommand;
				var lName:String = editLabelInput.trimmedText.toUpperCase();
				if (lName.length > 0) {
					lcmdEdit.labelName = lName;
				}
			}
			else if (editingCmd is GotoLabelCommand) {
				var glcmdEdit:GotoLabelCommand = editingCmd as GotoLabelCommand;
				var glName:String = editLabelInput.trimmedText.toUpperCase();
				if (glName.length > 0) {
					glcmdEdit.labelName = glName;
				}
			}
			else if (editingCmd is RestartBotCommand || editingCmd is StopBotCommand) {
				// No editable parameters to update
			}
			else if (editingCmd is BaseConditionalCommand) {
				var bccmdEdit:BaseConditionalCommand = editingCmd as BaseConditionalCommand;
				if (editCondVar1Input != null && editCondVar1Input.trimmedText.length > 0) {
					bccmdEdit.var1 = editCondVar1Input.trimmedText;
				}
				if (editCondVar2Input != null && editCondVar2Input.trimmedText.length > 0) {
					bccmdEdit.var2 = editCondVar2Input.trimmedText;
				}
			}

			close();
			if (onSaveCallback != null) {
				onSaveCallback();
			}
		}
	}
}
