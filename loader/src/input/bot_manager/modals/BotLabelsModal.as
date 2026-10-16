package input.bot_manager.modals {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	import commands.BotCommand;
	import commands.LabelCommand;
	import engine.BotEngine;
	import ui.CloseButton;
	import ui.ScrollContainer;
	import ui.UIUtils;

	public class BotLabelsModal extends Sprite {

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;

		private var botEngine:BotEngine;
		private var onSelectCallback:Function;

		private var currentLabelsScroll:ScrollContainer;
		private var currentLabelsCountLabel:TextField;
		private var emptyLabelsLabel:TextField;

		public function BotLabelsModal(botEngine:BotEngine, onSelectCallback:Function = null) {
			super();
			this.botEngine = botEngine;
			this.onSelectCallback = onSelectCallback;
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

			dimmer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					close();
				});

			// Card
			const boxW:Number = 380;
			const boxH:Number = 250;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			addChild(boxBg);

			// Title & Subtitle
			const title:TextField = UIUtils.createLabel("SELECT LABEL", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			addChild(title);

			currentLabelsCountLabel = UIUtils.createLabel("", UIUtils.TEXT_DIM, 9.5, false);
			currentLabelsCountLabel.x = boxX + 130;
			currentLabelsCountLabel.y = boxY + 14;
			currentLabelsCountLabel.width = 150;
			addChild(currentLabelsCountLabel);

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

			// Scroll Container
			currentLabelsScroll = new ScrollContainer(boxW - 32, boxH - 52, 10, true);
			currentLabelsScroll.x = boxX + 16;
			currentLabelsScroll.y = boxY + 42;
			addChild(currentLabelsScroll);

			emptyLabelsLabel = UIUtils.createLabel(
					"No labels found in current script.\n\nAdd labels using the 'Add' button first.",
					UIUtils.TEXT_DIM,
					10.5,
					false,
					TextFormatAlign.CENTER
				);
			emptyLabelsLabel.width = boxW - 48;
			emptyLabelsLabel.x = 8;
			emptyLabelsLabel.y = 50;
			emptyLabelsLabel.multiline = true;
			emptyLabelsLabel.wordWrap = true;
		}

		public function open():void {
			this.visible = true;
			currentLabelsScroll.clearContent(true);

			var labels:Array = [];
			var cmds:Array = botEngine.commandList;
			for (var i:int = 0; i < cmds.length; i++) {
				var cmd:BotCommand = cmds[i] as BotCommand;
				if (cmd is LabelCommand) {
					labels.push({
								step: i + 1,
								name: LabelCommand(cmd).labelName
							});
				}
			}

			currentLabelsCountLabel.text = "(" + labels.length + " label" + (labels.length == 1 ? "" : "s") + ")";

			if (labels.length == 0) {
				currentLabelsScroll.addItem(emptyLabelsLabel);
				emptyLabelsLabel.visible = true;
				currentLabelsScroll.updateScroll(0);
				return;
			}

			emptyLabelsLabel.visible = false;

			const rowW:Number = currentLabelsScroll.contentWidth;
			const rowH:Number = 24;

			for (var k:int = 0; k < labels.length; k++) {
				const item:Object = labels[k];
				const row:Sprite = buildLabelRow(item, rowW, rowH);
				row.y = k * (rowH + 4);
				currentLabelsScroll.addItem(row);
			}

			currentLabelsScroll.updateScroll(labels.length * (rowH + 4));
		}

		public function close():void {
			this.visible = false;
		}

		private function buildLabelRow(item:Object, w:Number, h:Number):Sprite {
			const row:Sprite = new Sprite();
			row.buttonMode = true;
			row.useHandCursor = true;

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x0f172a, 0.95, 0x1e293b, 1);
			row.addChild(bg);

			const stepTf:TextField = UIUtils.createLabel("#" + item.step, 0x60a5fa, 9.5, true);
			stepTf.x = 6;
			stepTf.y = 5;
			stepTf.width = 30;
			row.addChild(stepTf);

			const nameTf:TextField = UIUtils.createLabel(String(item.name), UIUtils.TEXT_MAIN, 10, true);
			nameTf.x = 38;
			nameTf.y = 5;
			nameTf.width = w - 100;
			row.addChild(nameTf);

			const selectTf:TextField = UIUtils.createLabel("Select ↵", 0x38bdf8, 9.5, false, TextFormatAlign.RIGHT);
			selectTf.x = w - 60;
			selectTf.y = 5;
			selectTf.width = 54;
			row.addChild(selectTf);

			row.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x38bdf8, 1);
					nameTf.textColor = 0xffffff;
				});
			row.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x0f172a, 0.95, 0x1e293b, 1);
					nameTf.textColor = UIUtils.TEXT_MAIN;
				});
			row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (onSelectCallback != null) {
						onSelectCallback(String(item.name).toUpperCase());
					}
					close();
				});

			return row;
		}
	}
}
