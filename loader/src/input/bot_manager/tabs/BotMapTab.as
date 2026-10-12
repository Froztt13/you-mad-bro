package input.bot_manager.tabs {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	import commands.JoinCommand;
	import commands.JumpCommand;
	import input.bot_manager.BotManagerUI;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.UIUtils;

	public class BotMapTab extends Sprite {

		private var manager:BotManagerUI;

		public function BotMapTab(manager:BotManagerUI) {
			super();
			this.manager = manager;
			this.x = 10;
			this.y = 10;

			buildUI();
		}

		private function buildUI():void {
			const contentW:Number = BotManagerUI.COL_RIGHT_W - 20;

			// 1. Join Map Section
			const mapLbl:TextField = UIUtils.createLabel("Join Map:", UIUtils.TEXT_MUTED, 10.5);
			mapLbl.y = 4;
			addChild(mapLbl);

			const mapInput:MyTextField = new MyTextField(130, 24);
			mapInput.y = 22;
			addChild(mapInput);

			const cellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
			cellLbl.x = 138;
			cellLbl.y = 4;
			addChild(cellLbl);

			const cellInput:MyTextField = new MyTextField(80, 24);
			cellInput.x = 138;
			cellInput.y = 22;
			cellInput.text = "Enter";
			addChild(cellInput);

			const padLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
			padLbl.x = 226;
			padLbl.y = 4;
			addChild(padLbl);

			const padInput:MyTextField = new MyTextField(80, 24);
			padInput.x = 226;
			padInput.y = 22;
			padInput.text = "Spawn";
			addChild(padInput);

			const addJoinBtn:MyButton = new MyButton("Add Join Map", 110, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (mapInput.trimmedText.length > 0) {
						manager.addBotCommand(new JoinCommand(mapInput.trimmedText, cellInput.trimmedText, padInput.trimmedText));
					}
				});
			addJoinBtn.y = 52;
			addChild(addJoinBtn);

			const getCurrentBtn:MyButton = new MyButton("Get Current", 100, 24, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					try {
						var gameObj:Object = manager.game;
						if (gameObj != null && gameObj.world != null) {
							if (gameObj.world.strAreaName != null && String(gameObj.world.strAreaName).length > 0) {
								mapInput.text = String(gameObj.world.strAreaName);
							}
							var curCell:String = (gameObj.world.strFrame != null && String(gameObj.world.strFrame).length > 0) ? String(gameObj.world.strFrame) : "Enter";
							var curPad:String = (gameObj.world.strPad != null && String(gameObj.world.strPad).length > 0) ? String(gameObj.world.strPad) : "Spawn";

							cellInput.text = curCell;
							padInput.text = curPad;

							jCellInput.text = curCell;
							jPadInput.text = curPad;
						}
					}
					catch (err:Error) {
					}
				});
			getCurrentBtn.x = 118;
			getCurrentBtn.y = 52;
			addChild(getCurrentBtn);

			// Divider between Join and Jump
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 84);
			div1.graphics.lineTo(contentW, 84);
			addChild(div1);

			// 2. Jump Cell Section
			const jumpTitle:TextField = UIUtils.createLabel("Jump Cell (Current Map):", UIUtils.TEXT_MUTED, 10.5);
			jumpTitle.y = 92;
			addChild(jumpTitle);

			const jCellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
			jCellLbl.y = 110;
			addChild(jCellLbl);

			const jCellInput:MyTextField = new MyTextField(100, 24);
			jCellInput.x = 0;
			jCellInput.y = 128;
			jCellInput.text = "Enter";
			addChild(jCellInput);

			const jPadLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
			jPadLbl.x = 110;
			jPadLbl.y = 110;
			addChild(jPadLbl);

			const jPadInput:MyTextField = new MyTextField(100, 24);
			jPadInput.x = 110;
			jPadInput.y = 128;
			jPadInput.text = "*";
			addChild(jPadInput);

			const addJumpBtn:MyButton = new MyButton("Add Jump Cell", 110, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (jCellInput.trimmedText.length > 0) {
						manager.addBotCommand(new JumpCommand(jCellInput.trimmedText, jPadInput.trimmedText));
					}
				});
			addJumpBtn.x = 218;
			addJumpBtn.y = 128;
			addChild(addJumpBtn);
		}
	}
}
