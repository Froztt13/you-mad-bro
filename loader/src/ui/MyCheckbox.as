package ui {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MyCheckbox extends Sprite {

		private var _checked:Boolean = false;
		private var _enabled:Boolean = true;
		private var _label:String;
		private var _onChange:Function;

		private var _boxShape:Shape;
		private var _checkMark:Shape;
		private var _labelTf:TextField;
		private var _isHovered:Boolean = false;

		public static const BOX_SIZE:Number = 16;

		public function MyCheckbox(label:String, defaultChecked:Boolean = false, onChange:Function = null, fontSize:Number = 11) {
			super();

			this._label = label;
			this._checked = defaultChecked;
			this._onChange = onChange;

			this.buttonMode = true;
			this.useHandCursor = true;

			// Checkbox box
			_boxShape = new Shape();
			_boxShape.y = 1;
			addChild(_boxShape);

			// Checkmark vector
			_checkMark = new Shape();
			_checkMark.y = 1;
			addChild(_checkMark);

			// Label text
			_labelTf = UIUtils.createLabel(label, UIUtils.TEXT_MAIN, fontSize, false);
			_labelTf.x = BOX_SIZE + 8;
			_labelTf.y = 0;
			_labelTf.autoSize = "left";
			addChild(_labelTf);

			redraw();

			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
		}

		public function get checked():Boolean {
			return _checked;
		}

		public function set checked(val:Boolean):void {
			if (_checked != val) {
				_checked = val;
				redraw();
			}
		}

		public function get label():String {
			return _label;
		}

		public function set label(val:String):void {
			_label = val;
			_labelTf.text = val;
		}

		public function get enabled():Boolean {
			return _enabled;
		}

		public function set enabled(val:Boolean):void {
			_enabled = val;
			this.mouseEnabled = val;
			this.alpha = val ? 1.0 : 0.4;
		}

		private function onClick(e:MouseEvent):void {
			if (!_enabled)
				return;
			_checked = !_checked;
			redraw();
			if (_onChange != null) {
				_onChange(_checked);
			}
		}

		private function onMouseOver(e:MouseEvent):void {
			_isHovered = true;
			redraw();
		}

		private function onMouseOut(e:MouseEvent):void {
			_isHovered = false;
			redraw();
		}

		private function redraw():void {
			const borderCol:uint = _checked ? 0x3b82f6 : (_isHovered ? UIUtils.BORDER_HOVER : UIUtils.BORDER_NORMAL);
			const bgCol:uint = _checked ? 0x2563eb : (_isHovered ? UIUtils.BG_HOVER : UIUtils.BG_RECESSED);

			UIUtils.drawRoundedRect(_boxShape.graphics, 0, 0, BOX_SIZE, BOX_SIZE, 3, bgCol, 1.0, borderCol, 1);

			_checkMark.graphics.clear();
			if (_checked) {
				_checkMark.graphics.lineStyle(2, 0xffffff, 1.0, true);
				// Draw clean checkmark
				_checkMark.graphics.moveTo(3.5, 8.5);
				_checkMark.graphics.lineTo(6.5, 12);
				_checkMark.graphics.lineTo(12.5, 4.5);
			}

			_labelTf.textColor = _isHovered ? UIUtils.TEXT_WHITE : UIUtils.TEXT_MAIN;
		}
	}
}
