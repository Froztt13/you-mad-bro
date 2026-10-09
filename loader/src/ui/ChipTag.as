package ui {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	public class ChipTag extends Sprite {

		private var _w:Number;
		private var _h:Number;
		private var _bgShape:Shape;
		private var _labelTf:TextField;
		private var _closeBtn:Sprite;
		private var _onClose:Function;

		public function ChipTag(
				label:String,
				w:Number = 78,
				h:Number = 24,
				hasCloseBtn:Boolean = false,
				onClose:Function = null,
				textColor:uint = 0xf1f5f9,
				bgColor:uint = 0x1e293b,
				borderColor:uint = 0x334155
			) {
			super();

			this._w = w;
			this._h = h;
			this._onClose = onClose;

			_bgShape = new Shape();
			UIUtils.drawRoundedRect(_bgShape.graphics, 0, 0, w, h, 4, bgColor, 1.0, borderColor, 1);
			addChild(_bgShape);

			var textW:Number = hasCloseBtn ? (w - 26) : (w - 8);
			_labelTf = UIUtils.createLabel(label, textColor, 10, true, hasCloseBtn ? TextFormatAlign.LEFT : TextFormatAlign.CENTER);
			_labelTf.width = textW;
			_labelTf.height = h;
			_labelTf.x = hasCloseBtn ? 6 : 4;
			_labelTf.y = int((h - 16) / 2);
			addChild(_labelTf);

			if (hasCloseBtn) {
				_closeBtn = new Sprite();
				_closeBtn.buttonMode = true;
				_closeBtn.useHandCursor = true;

				const closeBg:Shape = new Shape();
				UIUtils.drawRoundedRect(closeBg.graphics, 0, 0, 16, 16, 3, 0x334155, 1.0);
				_closeBtn.addChild(closeBg);

				const closeLabel:TextField = UIUtils.createLabel("×", 0x94a3b8, 10.5, true, TextFormatAlign.CENTER);
				closeLabel.width = 16;
				closeLabel.height = 16;
				closeLabel.y = 0;
				_closeBtn.addChild(closeLabel);

				_closeBtn.x = w - 20;
				_closeBtn.y = int((h - 16) / 2);

				_closeBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(closeBg.graphics, 0, 0, 16, 16, 3, 0xb91c1c, 1.0);
						closeLabel.textColor = 0xffffff;
					});

				_closeBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(closeBg.graphics, 0, 0, 16, 16, 3, 0x334155, 1.0);
						closeLabel.textColor = 0x94a3b8;
					});

				_closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
				addChild(_closeBtn);
			}
		}

		public function get label():String {
			return _labelTf != null ? _labelTf.text : "";
		}

		public function set label(val:String):void {
			if (_labelTf != null) {
				_labelTf.text = val;
			}
		}

		private function onCloseClick(e:MouseEvent):void {
			if (_onClose != null) {
				_onClose(this);
			}
		}
	}
}
