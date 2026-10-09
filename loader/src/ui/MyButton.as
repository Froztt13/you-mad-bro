package ui {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	public class MyButton extends Sprite {

		public static const TYPE_PRIMARY:String = "primary"; // Blue
		public static const TYPE_SUCCESS:String = "success"; // Emerald
		public static const TYPE_DANGER:String = "danger"; // Red
		public static const TYPE_SECONDARY:String = "secondary"; // Slate Dark
		public static const TYPE_MUTED:String = "muted"; // Subtle Slate

		private var _w:Number;
		private var _h:Number;
		private var _r:Number;
		private var _fontSize:Number;

		private var _bgNormal:uint;
		private var _bgHover:uint;
		private var _borderNormal:uint;
		private var _borderHover:uint;
		private var _textNormal:uint;
		private var _textHover:uint;

		private var _bgShape:Shape;
		private var _labelTf:TextField;
		private var _enabled:Boolean = true;
		private var _active:Boolean = false;
		private var _isHovered:Boolean = false;
		private var _onClick:Function;

		public function MyButton(
				label:String,
				w:Number = 80,
				h:Number = 24,
				type:String = TYPE_SECONDARY,
				onClick:Function = null,
				fontSize:Number = 11,
				radius:Number = 4
			) {
			super();

			this._w = w;
			this._h = h;
			this._r = radius;
			this._fontSize = fontSize;
			this._onClick = onClick;

			this.buttonMode = true;
			this.useHandCursor = true;
			this.mouseChildren = false;

			_bgShape = new Shape();
			addChild(_bgShape);

			_labelTf = UIUtils.createLabel(label, 0xffffff, fontSize, true, TextFormatAlign.CENTER);
			_labelTf.width = w;
			_labelTf.height = h;
			_labelTf.y = int((h - (fontSize + 5)) / 2);
			addChild(_labelTf);

			setType(type);

			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(MouseEvent.CLICK, onInternalClick);
		}

		private function onInternalClick(e:MouseEvent):void {
			if (_enabled && _onClick != null) {
				_onClick(e);
			}
		}

		public function setType(type:String):void {
			switch (type) {
				case TYPE_PRIMARY:
					setColors(0x2563eb, 0x3b82f6, 0x1d4ed8, 0x60a5fa, 0xffffff, 0xffffff);
					break;
				case TYPE_SUCCESS:
					setColors(0x15803d, 0x16a34a, 0x166534, 0x22c55e, 0xffffff, 0xffffff);
					break;
				case TYPE_DANGER:
					setColors(0xb91c1c, 0xdc2626, 0x991b1b, 0xef4444, 0xffffff, 0xffffff);
					break;
				case TYPE_MUTED:
					setColors(0x1e293b, 0x334155, 0x334155, 0x475569, 0x94a3b8, 0xffffff);
					break;
				case TYPE_SECONDARY:
				default:
					setColors(0x1e293b, 0x334155, 0x334155, 0x475569, 0xcbd5e1, 0xffffff);
					break;
			}
		}

		public function setColors(
				bgNormal:uint,
				bgHover:uint,
				borderNormal:uint,
				borderHover:uint,
				textNormal:uint,
				textHover:uint
			):void {
			this._bgNormal = bgNormal;
			this._bgHover = bgHover;
			this._borderNormal = borderNormal;
			this._borderHover = borderHover;
			this._textNormal = textNormal;
			this._textHover = textHover;
			redraw();
		}

		public function get label():String {
			return _labelTf != null ? _labelTf.text : "";
		}

		public function set label(val:String):void {
			if (_labelTf != null) {
				_labelTf.text = val;
			}
		}

		public function set active(val:Boolean):void {
			this._active = val;
			redraw();
		}

		public function get active():Boolean {
			return _active;
		}

		public function set enabled(val:Boolean):void {
			this._enabled = val;
			this.mouseEnabled = val;
			this.alpha = val ? 1.0 : 0.4;
		}

		public function get enabled():Boolean {
			return _enabled;
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
			var bg:uint = (_isHovered || _active) ? _bgHover : _bgNormal;
			var stroke:uint = (_isHovered || _active) ? _borderHover : _borderNormal;
			var txtColor:uint = (_isHovered || _active) ? _textHover : _textNormal;

			UIUtils.drawRoundedRect(_bgShape.graphics, 0, 0, _w, _h, _r, bg, 1.0, stroke, 1);
			if (_labelTf != null) {
				_labelTf.textColor = txtColor;
			}
		}
	}
}
