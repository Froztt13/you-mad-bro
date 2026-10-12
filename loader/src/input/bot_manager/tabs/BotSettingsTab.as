package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.DelayCommand;
	import commands.NotifCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotSettingsTab extends Sprite {

		private var manager:BotManagerUI;

		private var botRepeatCheckbox:MyCheckbox;
		private var leaveCombatCheckbox:MyCheckbox;
		private var loadBtn:MyButton;
		private var saveBtn:MyButton;

		public function BotSettingsTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Checkboxes Section
			botRepeatCheckbox = new MyCheckbox("Bot Repeat", manager.botEngine.loop, function(val:Boolean):void {
					manager.botEngine.loop = val;
				});
			botRepeatCheckbox.x = 0;
			botRepeatCheckbox.y = 0;
			addChild(botRepeatCheckbox);

			leaveCombatCheckbox = new MyCheckbox("Leave combat on stop/pause", manager.botEngine.leaveCombatOnStop, function(val:Boolean):void {
					manager.botEngine.leaveCombatOnStop = val;
				});
			leaveCombatCheckbox.x = 0;
			leaveCombatCheckbox.y = 22;
			addChild(leaveCombatCheckbox);

			// 2. Wait Delay & Notif Command Section
			const delayLbl:TextField = UIUtils.createLabel("Wait Delay (s):", UIUtils.TEXT_MUTED, 10.5);
			delayLbl.y = 48;
			addChild(delayLbl);

			const delayInput:MyTextField = new MyTextField(60, 24);
			delayInput.y = 66;
			delayInput.text = "2";
			delayInput.restrict = "0-9.";
			addChild(delayInput);

			const addWaitBtn:MyButton = new MyButton("Add Delay", 74, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var secs:Number = parseFloat(delayInput.text);
					if (!isNaN(secs) && secs > 0) {
						manager.addBotCommand(new DelayCommand(secs));
					}
				});
			addWaitBtn.x = 68;
			addWaitBtn.y = 66;
			addChild(addWaitBtn);

			// Notification Command Section
			const notifLbl:TextField = UIUtils.createLabel("Notification Message:", UIUtils.TEXT_MUTED, 10.5);
			notifLbl.y = 96;
			addChild(notifLbl);

			const notifInput:MyTextField = new MyTextField(160, 24);
			notifInput.y = 114;
			notifInput.text = "";
			addChild(notifInput);

			const addNotifBtn:MyButton = new MyButton("Add Notif", 78, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (notifInput.trimmedText.length > 0) {
						manager.addBotCommand(new NotifCommand(notifInput.trimmedText));
						notifInput.text = "";
					}
				});
			addNotifBtn.x = 168;
			addNotifBtn.y = 114;
			addChild(addNotifBtn);

			// Divider between Commands and Script Files
			const div2:Shape = new Shape();
			div2.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div2.graphics.moveTo(0, 148);
			div2.graphics.lineTo(contentW, 148);
			addChild(div2);

			// 3. Script Files Section (Load & Save)
			const scriptLbl:TextField = UIUtils.createLabel("Script Management:", UIUtils.TEXT_MUTED, 10.5);
			scriptLbl.y = 156;
			addChild(scriptLbl);

			loadBtn = new MyButton("Load Script", 100, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					manager.openLoadModal();
				});
			loadBtn.setColors(0x064e3b, 0x065f46, 0x059669, 0x10b981, 0xa7f3d0, 0xffffff);
			loadBtn.x = 0;
			loadBtn.y = 176;
			addChild(loadBtn);

			saveBtn = new MyButton("Save Script", 100, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					manager.openSaveModal();
				});
			saveBtn.setColors(0x1e1b4b, 0x2e1065, 0x4338ca, 0x6366f1, 0xc7d2fe, 0xffffff);
			saveBtn.x = 108;
			saveBtn.y = 176;
			addChild(saveBtn);
		}

		public function updateCheckboxes():void {
			if (botRepeatCheckbox != null && manager.botEngine != null) {
				botRepeatCheckbox.checked = manager.botEngine.loop;
			}
			if (leaveCombatCheckbox != null && manager.botEngine != null) {
				leaveCombatCheckbox.checked = manager.botEngine.leaveCombatOnStop;
			}
		}
	}
}
