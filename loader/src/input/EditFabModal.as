package input {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;

	import ui.BaseModal;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.ScrollContainer;
	import ui.UIUtils;

	public class EditFabModal extends BaseModal {

		public static const MODAL_W:Number = 520;
		public static const MODAL_H:Number = 450;

		public static const ACTION_KEY:String = "key";
		public static const ACTION_BOT_MGR:String = "bot";
		public static const ACTION_BOT_TOGGLE:String = "toggle_bot";
		public static const ACTION_COMBAT:String = "leave_combat";
		public static const ACTION_LOADER:String = "loader";
		public static const ACTION_CELL:String = "cell";
		public static const ACTION_LAG:String = "lag";
		public static const ACTION_BANK:String = "bank";
		public static const ACTION_LOGGER:String = "logger";

		private var game:Object;
		private var fabOverlay:FabOverlay;

		private var listScroll:ScrollContainer;
		private var workingList:Array = [];
		private var rowViews:Array = [];

		// Action Picker Overlay
		private var pickerOverlay:Sprite;
		private var pickerActiveIndex:int = -1;

		public function EditFabModal(game:Object, fabOverlay:FabOverlay) {
			super(MODAL_W, MODAL_H, "Edit Floating Action Buttons", "Mobile Hotkeys & Feature Toggles");
			this.game = game;
			this.fabOverlay = fabOverlay;

			buildBody();
			buildActionPicker();
		}

		public static function getActionDisplayName(act:String):String {
			if (act == ACTION_BOT_MGR) return "Bot Manager";
			if (act == ACTION_BOT_TOGGLE || act == "start_bot") return "Toggle Bot";
			if (act == ACTION_COMBAT || act == "combat") return "Leave Combat";
			if (act == ACTION_LOADER || act == "grabber") return "Loader / Grabber";
			if (act == ACTION_CELL) return "Cell Jump";
			if (act == ACTION_LAG) return "Lag Killer";
			if (act == ACTION_BANK) return "Bank";
			if (act == ACTION_LOGGER || act == "packet") return "Packet Logger";
			return "Hotkey";
		}

		public static function getDefaultLabelForAction(act:String):String {
			if (act == ACTION_BOT_MGR) return "Bot";
			if (act == ACTION_BOT_TOGGLE || act == "start_bot") return "On/Off";
			if (act == ACTION_COMBAT || act == "combat") return "Leave";
			if (act == ACTION_LOADER || act == "grabber") return "Load";
			if (act == ACTION_CELL) return "Jump";
			if (act == ACTION_LAG) return "Lag";
			if (act == ACTION_BANK) return "Bank";
			if (act == ACTION_LOGGER || act == "packet") return "Log";
			return "Space";
		}

		private function buildBody():void {
			// Subtitle / Help instructions
			const helpTf:TextField = UIUtils.createLabel("Set button to trigger a keyboard hotkey or toggle a feature (Bot, Combat, Loader, etc.)", UIUtils.TEXT_MUTED, 9.5, false);
			helpTf.x = BaseModal.PADDING;
			helpTf.y = BaseModal.HEADER_HEIGHT + 6;
			helpTf.width = MODAL_W - BaseModal.PADDING * 2;
			addChild(helpTf);

			// Column Headers
			const colY:Number = BaseModal.HEADER_HEIGHT + 24;
			const col1:TextField = UIUtils.createLabel("LABEL", UIUtils.TEXT_DIM, 8.5, true);
			col1.x = BaseModal.PADDING + 8;
			col1.y = colY;
			col1.width = 85;
			addChild(col1);

			const col2:TextField = UIUtils.createLabel("ACTION / FEATURE", UIUtils.TEXT_DIM, 8.5, true);
			col2.x = BaseModal.PADDING + 96;
			col2.y = colY;
			col2.width = 158;
			addChild(col2);

			const col3:TextField = UIUtils.createLabel("KEY", UIUtils.TEXT_DIM, 8.5, true, TextFormatAlign.CENTER);
			col3.x = BaseModal.PADDING + 258;
			col3.y = colY;
			col3.width = 60;
			addChild(col3);

			const col4:TextField = UIUtils.createLabel("ACTIONS", UIUtils.TEXT_DIM, 8.5, true);
			col4.x = BaseModal.PADDING + 326;
			col4.y = colY;
			col4.width = 120;
			addChild(col4);

			// Scrollable container for button rows
			const scrollW:Number = MODAL_W - BaseModal.PADDING * 2; // 496
			const scrollH:Number = 285;
			listScroll = new ScrollContainer(scrollW, scrollH, 8, true, 4, 4);
			listScroll.x = BaseModal.PADDING;
			listScroll.y = BaseModal.HEADER_HEIGHT + 40;
			addChild(listScroll);

			// Bottom Toolbar
			const bottomY:Number = MODAL_H - BaseModal.PADDING - 28;

			const addBtn:MyButton = new MyButton("+ Add Button", 110, 28, MyButton.TYPE_PRIMARY, onAddClick);
			addBtn.x = BaseModal.PADDING;
			addBtn.y = bottomY;
			addChild(addBtn);

			const resetBtn:MyButton = new MyButton("Reset Defaults", 110, 28, MyButton.TYPE_MUTED, onResetClick);
			resetBtn.x = addBtn.x + 110 + 8;
			resetBtn.y = bottomY;
			addChild(resetBtn);

			const saveBtn:MyButton = new MyButton("Save & Close", 120, 28, MyButton.TYPE_SUCCESS, onSaveClick);
			saveBtn.x = MODAL_W - BaseModal.PADDING - 120;
			saveBtn.y = bottomY;
			addChild(saveBtn);
		}

		private function buildActionPicker():void {
			pickerOverlay = new Sprite();
			pickerOverlay.visible = false;
			addChild(pickerOverlay);

			// Dark backdrop
			const backdrop:Shape = new Shape();
			backdrop.graphics.beginFill(0x000000, 0.65);
			backdrop.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 12, 12);
			backdrop.graphics.endFill();
			pickerOverlay.addChild(backdrop);

			// Backdrop click closes picker
			pickerOverlay.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				if (e.target == pickerOverlay || e.target == backdrop) {
					closeActionPicker();
				}
			});

			// Centered Card Panel
			const cardW:Number = 360;
			const cardH:Number = 390;
			const cardX:Number = (MODAL_W - cardW) / 2;
			const cardY:Number = (MODAL_H - cardH) / 2;

			const card:Sprite = new Sprite();
			card.x = cardX;
			card.y = cardY;
			pickerOverlay.addChild(card);

			const cardBg:Shape = new Shape();
			UIUtils.drawRoundedRect(cardBg.graphics, 0, 0, cardW, cardH, 8, 0x0f172a, 0.98, 0x38bdf8, 1.2);
			card.addChild(cardBg);

			// Title
			const titleTf:TextField = UIUtils.createLabel("Select Button Action", 0xf8fafc, 12.5, true);
			titleTf.x = 16;
			titleTf.y = 10;
			titleTf.width = 250;
			card.addChild(titleTf);

			// Close "✕" button
			const closeBtn:Sprite = createDeleteButton(closeActionPicker);
			closeBtn.x = cardW - 36;
			closeBtn.y = 8;
			card.addChild(closeBtn);

			// Options List
			const options:Array = [
				{ id: ACTION_KEY, label: "Hotkey", desc: "Trigger key press (Skills 1-5, Space, Rest, etc.)" },
				{ id: ACTION_BOT_TOGGLE, label: "Toggle Bot", desc: "Start / Stop bot engine execution" },
				{ id: ACTION_COMBAT, label: "Leave Combat", desc: "Cancel attack, clear target, and exit combat" },
				{ id: ACTION_BOT_MGR, label: "Bot Manager", desc: "Open / Toggle Bot Manager UI" },
				{ id: ACTION_LOADER, label: "Loader / Grabber", desc: "Open / Toggle Quest & Item Grabber UI" },
				{ id: ACTION_CELL, label: "Cell Jump", desc: "Open / Toggle Fast Travel Cell Jump UI" },
				{ id: ACTION_LAG, label: "Lag Killer", desc: "Toggle Lag Killer (hide world map & effects)" },
				{ id: ACTION_BANK, label: "Bank", desc: "Open / Toggle Bank" },
				{ id: ACTION_LOGGER, label: "Packet Logger", desc: "Open / Toggle Packet Logger UI" }
			];

			const listStartY:Number = 38;
			const rowH:Number = 34;

			for (var i:int = 0; i < options.length; i++) {
				var opt:Object = options[i];
				var optRow:Sprite = createPickerOptionRow(opt, cardW - 24, rowH);
				optRow.x = 12;
				optRow.y = listStartY + i * (rowH + 4);
				card.addChild(optRow);
			}
		}

		private function createPickerOptionRow(opt:Object, w:Number, h:Number):Sprite {
			const row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 6, 0x1e293b, 0.8, 0x334155, 1);
			row.addChild(bg);

			const mainTf:TextField = UIUtils.createLabel(opt.label, 0xf8fafc, 11, true);
			mainTf.x = 10;
			mainTf.y = 2;
			mainTf.width = w - 20;
			row.addChild(mainTf);

			const descTf:TextField = UIUtils.createLabel(opt.desc, 0x94a3b8, 8.5, false);
			descTf.x = 10;
			descTf.y = 17;
			descTf.width = w - 20;
			row.addChild(descTf);

			row.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 6, 0x334155, 1.0, 0x38bdf8, 1);
				mainTf.textColor = 0x38bdf8;
			});

			row.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 6, 0x1e293b, 0.8, 0x334155, 1);
				mainTf.textColor = 0xf8fafc;
			});

			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				selectPickerOption(opt.id);
			});

			return row;
		}

		private function openActionPicker(index:int):void {
			syncWorkingListFromInputs();
			pickerActiveIndex = index;
			setChildIndex(pickerOverlay, numChildren - 1);
			pickerOverlay.visible = true;
		}

		private function closeActionPicker():void {
			pickerOverlay.visible = false;
			pickerActiveIndex = -1;
		}

		private function selectPickerOption(chosenAction:String):void {
			if (pickerActiveIndex >= 0 && pickerActiveIndex < workingList.length) {
				var item:Object = workingList[pickerActiveIndex];
				var oldAction:String = String(item.action || ACTION_KEY);
				item.action = chosenAction;

				// If label is empty or matches default of previous action, update to default of new action
				var curLabel:String = String(item.label || "");
				if (curLabel == "" || curLabel == getDefaultLabelForAction(oldAction)) {
					item.label = getDefaultLabelForAction(chosenAction);
				}

				if (chosenAction == ACTION_KEY && (item.key == null || item.key == "")) {
					item.key = "1";
					item.keyCode = 49;
				}
			}
			closeActionPicker();
			renderRows();
		}

		public function refresh():void {
			workingList = [];
			var srcList:Array = (fabOverlay != null) ? fabOverlay.getButtonsData() : [];
			for each (var item:Object in srcList) {
				workingList.push({
					id: item.id,
					label: item.label,
					action: item.action || ACTION_KEY,
					key: item.key || "1",
					keyCode: item.keyCode || FabOverlay.getKeyCodeForString(item.key),
					x: item.x,
					y: item.y
				});
			}
			renderRows();
		}

		private function renderRows():void {
			listScroll.clearContent();
			rowViews = [];

			const rowH:Number = 32;
			for (var i:int = 0; i < workingList.length; i++) {
				const item:Object = workingList[i];
				const rowItem:Object = createRowSprite(item, i);
				const rowSprite:Sprite = rowItem.row as Sprite;
				rowSprite.y = i * (rowH + 4);
				listScroll.content.addChild(rowSprite);
				rowViews.push(rowItem);
			}

			listScroll.updateScroll();
		}

		private function createRowSprite(item:Object, index:int):Object {
			const row:Sprite = new Sprite();
			const rowW:Number = MODAL_W - BaseModal.PADDING * 2 - 18; // ~478
			const rowH:Number = 32;

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, rowW, rowH, 4, UIUtils.BG_DARK, 0.6, UIUtils.BORDER_SUBTLE, 1);
			row.addChild(bg);

			// 1. Label Input
			const labelInput:MyTextField = new MyTextField(82, 24, 11);
			labelInput.x = 6;
			labelInput.y = 4;
			labelInput.text = item.label;
			labelInput.maxChars = 8;
			row.addChild(labelInput);

			// 2. Action Selector Button
			const actName:String = getActionDisplayName(item.action);
			const actBtn:Sprite = createActionSelectButton(actName + " [v]", 158, 24, function():void {
				openActionPicker(index);
			});
			actBtn.x = 94;
			actBtn.y = 4;
			row.addChild(actBtn);

			// 3. Key Input (only visible if action == "key")
			const isKeyAction:Boolean = (item.action == ACTION_KEY || item.action == null || item.action == "");
			const keyInput:MyTextField = new MyTextField(60, 24, 11, TextFormatAlign.CENTER);
			keyInput.x = 258;
			keyInput.y = 4;
			keyInput.text = isKeyAction ? String(item.key || "1") : "-";
			keyInput.maxChars = 6;
			keyInput.visible = isKeyAction;
			row.addChild(keyInput);

			// Placeholder dash if not key action
			if (!isKeyAction) {
				const dashTf:TextField = UIUtils.createLabel("-", 0x475569, 11, true, TextFormatAlign.CENTER);
				dashTf.x = 258;
				dashTf.y = 7;
				dashTf.width = 60;
				row.addChild(dashTf);
			}

			// 4. Test Button
			const testBtn:MyButton = new MyButton("Test", 56, 24, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
				var kStr:String = isKeyAction ? keyInput.text : "";
				var kCode:int = isKeyAction ? FabOverlay.getKeyCodeForString(kStr) : 0;
				if (fabOverlay != null) {
					fabOverlay.triggerButton({
						label: labelInput.text,
						action: item.action || ACTION_KEY,
						key: kStr,
						keyCode: kCode
					});
				}
			});
			testBtn.x = 324;
			testBtn.y = 4;
			row.addChild(testBtn);

			// 5. Delete Button
			const delBtn:Sprite = createDeleteButton(function():void {
				syncWorkingListFromInputs();
				workingList.splice(index, 1);
				renderRows();
			});
			delBtn.x = 386;
			delBtn.y = 4;
			row.addChild(delBtn);

			return {
				row: row,
				labelInput: labelInput,
				keyInput: keyInput
			};
		}

		private function createActionSelectButton(text:String, w:Number, h:Number, onClick:Function):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x38bdf8, 0.7);
			btn.addChild(bg);

			const tf:TextField = UIUtils.createLabel(text, 0xf8fafc, 10, true, TextFormatAlign.CENTER);
			tf.x = 4;
			tf.y = int((h - 15) / 2);
			tf.width = w - 8;
			tf.mouseEnabled = false;
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x38bdf8, 1.2);
				tf.textColor = 0x38bdf8;
			});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x38bdf8, 0.7);
				tf.textColor = 0xf8fafc;
			});

			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				onClick();
			});

			return btn;
		}

		private function createDeleteButton(onClick:Function):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, 26, 24, 4, 0x1e293b, 1.0, 0x334155, 1);
			btn.addChild(bg);

			const tf:TextField = UIUtils.createLabel("x", 0xef4444, 11, true, TextFormatAlign.CENTER);
			tf.width = 26;
			tf.height = 24;
			tf.y = 3;
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, 26, 24, 4, 0x7f1d1d, 1.0, 0xef4444, 1);
				tf.textColor = 0xffffff;
			});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
				UIUtils.drawRoundedRect(bg.graphics, 0, 0, 26, 24, 4, 0x1e293b, 1.0, 0x334155, 1);
				tf.textColor = 0xef4444;
			});

			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				onClick();
			});

			return btn;
		}

		private function syncWorkingListFromInputs():void {
			for (var i:int = 0; i < rowViews.length; i++) {
				var rowObj:Object = rowViews[i];
				if (rowObj != null && i < workingList.length) {
					var lblInput:MyTextField = rowObj.labelInput as MyTextField;
					var kInput:MyTextField = rowObj.keyInput as MyTextField;
					if (lblInput != null) {
						workingList[i].label = (lblInput.text.length > 0) ? lblInput.text : "Key";
					}
					var act:String = String(workingList[i].action || ACTION_KEY);
					if (act == ACTION_KEY && kInput != null) {
						workingList[i].key = (kInput.text.length > 0) ? kInput.text : "1";
						workingList[i].keyCode = FabOverlay.getKeyCodeForString(workingList[i].key);
					}
				}
			}
		}

		private function onAddClick(e:MouseEvent):void {
			syncWorkingListFromInputs();
			var nextNum:int = workingList.length + 1;
			workingList.push({
				id: "fab_" + Math.random().toString().substr(2, 6),
				label: "Key " + nextNum,
				action: ACTION_KEY,
				key: String(nextNum <= 9 ? nextNum : "1"),
				keyCode: FabOverlay.getKeyCodeForString(String(nextNum <= 9 ? nextNum : "1")),
				x: 700,
				y: 350
			});
			renderRows();
			listScroll.scrollToBottom();
		}

		private function onResetClick(e:MouseEvent):void {
			workingList = FabOverlay.getDefaultButtons();
			renderRows();
		}

		private function onSaveClick(e:MouseEvent):void {
			syncWorkingListFromInputs();
			if (fabOverlay != null) {
				fabOverlay.setButtonsData(workingList);
				fabOverlay.visible = true;
			}
			visible = false;
		}
	}
}
