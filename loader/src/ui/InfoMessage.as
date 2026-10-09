package ui {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.filters.DropShadowFilter;

	public class InfoMessage extends Sprite {

		private static const UI_WIDTH:Number = 300;
		private static const UI_HEIGHT:Number = 150;
		private static const PADDING:Number = 15;

		public function InfoMessage(title:String, description:String) {
			addEventListener(Event.ADDED_TO_STAGE, onAdded);

			// Background
			const bg:Shape = new Shape();
			bg.graphics.beginFill(0x1a1a1a, 0.95);
			bg.graphics.drawRoundRect(0, 0, UI_WIDTH, UI_HEIGHT, 12);
			bg.graphics.endFill();
			bg.graphics.lineStyle(2, 0x444444, 1);
			bg.graphics.drawRoundRect(0, 0, UI_WIDTH, UI_HEIGHT, 12);
			bg.filters = [new DropShadowFilter(8, 45, 0x000000, 0.7, 16, 16, 1, 2)];
			addChild(bg);

			// Title
			const titleLabel:TextField = createLabel(title, 0xffffff, 16, true);
			titleLabel.x = PADDING;
			titleLabel.y = PADDING;
			titleLabel.width = UI_WIDTH - PADDING * 2;
			titleLabel.height = 25;
			addChild(titleLabel);

			// Description
			const descLabel:TextField = createLabel(description, 0xcccccc, 12, false);
			descLabel.x = PADDING;
			descLabel.y = titleLabel.y + titleLabel.height + 10;
			descLabel.width = UI_WIDTH - PADDING * 2;
			descLabel.height = 50;
			descLabel.multiline = true;
			descLabel.wordWrap = true;
			addChild(descLabel);

			// OK Button
			const okBtn:Sprite = new Sprite();
			okBtn.graphics.beginFill(0x333333, 1);
			okBtn.graphics.drawRoundRect(0, 0, 80, 26, 6);
			okBtn.graphics.endFill();

			const okLabel:TextField = createLabel("OK", 0xffffff, 12, true);
			okLabel.width = 80;
			okLabel.height = 26;
			okLabel.y = 3;
			okBtn.addChild(okLabel);

			okBtn.x = (UI_WIDTH - 80) / 2;
			okBtn.y = UI_HEIGHT - PADDING - 26;
			okBtn.buttonMode = true;
			okBtn.useHandCursor = true;
			okBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					visible = false;
					// parent.removeChild(this);
				});
			addChild(okBtn);
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			// Center on stage
			this.x = (stage.stageWidth - UI_WIDTH) / 2;
			this.y = (stage.stageHeight - UI_HEIGHT) / 2;
		}

		private function createLabel(text:String, color:uint, size:int, bold:Boolean):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, TextFormatAlign.CENTER);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}
	}
}
