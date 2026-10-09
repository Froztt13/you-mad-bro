package ui {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class ConfirmationMessage extends Sprite {

		private static const UI_WIDTH:Number = 320;
		private static const UI_HEIGHT:Number = 160;
		private static const PADDING:Number = 15;

		private var _onConfirm:Function;
		private var _onCancel:Function;

		public function ConfirmationMessage(
				title:String,
				description:String,
				onConfirm:Function,
				onCancel:Function = null,
				confirmLabelText:String = "Confirm",
				cancelLabelText:String = "Cancel",
				confirmBtnType:String = MyButton.TYPE_DANGER
			) {
			super();

			this._onConfirm = onConfirm;
			this._onCancel = onCancel;

			addEventListener(Event.ADDED_TO_STAGE, onAdded);

			// Background
			const bg:Shape = new Shape();
			bg.graphics.beginFill(0x1a1a1a, 0.96);
			bg.graphics.drawRoundRect(0, 0, UI_WIDTH, UI_HEIGHT, 12);
			bg.graphics.endFill();
			bg.graphics.lineStyle(2, 0x444444, 1);
			bg.graphics.drawRoundRect(0, 0, UI_WIDTH, UI_HEIGHT, 12);
			bg.filters = [new DropShadowFilter(8, 45, 0x000000, 0.75, 16, 16, 1, 2)];
			addChild(bg);

			// Title
			const titleLabel:TextField = createLabel(title, 0xffffff, 15, true);
			titleLabel.x = PADDING;
			titleLabel.y = PADDING;
			titleLabel.width = UI_WIDTH - PADDING * 2;
			titleLabel.height = 24;
			addChild(titleLabel);

			// Description
			const descLabel:TextField = createLabel(description, 0xcccccc, 11.5, false);
			descLabel.x = PADDING;
			descLabel.y = titleLabel.y + titleLabel.height + 8;
			descLabel.width = UI_WIDTH - PADDING * 2;
			descLabel.height = 54;
			descLabel.multiline = true;
			descLabel.wordWrap = true;
			addChild(descLabel);

			// Action Buttons (Cancel & Confirm)
			const btnW:Number = 86;
			const btnH:Number = 26;
			const gap:Number = 16;
			const startX:Number = (UI_WIDTH - (btnW * 2 + gap)) / 2;
			const btnY:Number = UI_HEIGHT - PADDING - btnH;

			const cancelBtn:MyButton = new MyButton(cancelLabelText, btnW, btnH, MyButton.TYPE_MUTED, onCancelClick);
			cancelBtn.x = startX;
			cancelBtn.y = btnY;
			addChild(cancelBtn);

			const confirmBtn:MyButton = new MyButton(confirmLabelText, btnW, btnH, confirmBtnType, onConfirmClick);
			confirmBtn.x = startX + btnW + gap;
			confirmBtn.y = btnY;
			addChild(confirmBtn);
		}

		private function onConfirmClick(e:MouseEvent):void {
			close();
			if (_onConfirm != null) {
				_onConfirm();
			}
		}

		private function onCancelClick(e:MouseEvent):void {
			close();
			if (_onCancel != null) {
				_onCancel();
			}
		}

		private function close():void {
			if (parent != null) {
				parent.removeChild(this);
			}
			else {
				visible = false;
			}
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			if (stage != null) {
				this.x = (stage.stageWidth - UI_WIDTH) / 2;
				this.y = (stage.stageHeight - UI_HEIGHT) / 2;
			}
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
