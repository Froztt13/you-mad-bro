package ui {

	import flash.events.FocusEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import Utils;
	import flash.text.TextFormatAlign;

	public class MyTextField extends TextField {

		public static const DEFAULT_BG_COLOR:uint = 0x070b14;
		public static const DEFAULT_TEXT_COLOR:uint = 0xf1f5f9;
		public static const DEFAULT_BORDER_NORMAL:uint = 0x334155;
		public static const DEFAULT_BORDER_FOCUS:uint = 0x3b82f6;

		private var _borderNormal:uint;
		private var _borderFocus:uint;
		private var _fontSize:Number;
		private var _textColor:uint;
		private var _align:String;
		private var _isBold:Boolean;

		public function MyTextField(
				w:Number = 120,
				h:Number = 24,
				fontSize:Number = 12.5,
				align:String = TextFormatAlign.LEFT,
				bold:Boolean = false,
				textColor:uint = DEFAULT_TEXT_COLOR,
				bgColor:uint = DEFAULT_BG_COLOR,
				borderNormal:uint = DEFAULT_BORDER_NORMAL,
				borderFocus:uint = DEFAULT_BORDER_FOCUS
			) {
			super();

			this._fontSize = fontSize;
			this._textColor = textColor;
			this._align = align;
			this._isBold = bold;
			this._borderNormal = borderNormal;
			this._borderFocus = borderFocus;

			this.type = TextFieldType.INPUT;
			this.selectable = true;
			this.border = true;
			this.borderColor = _borderNormal;
			this.background = true;
			this.backgroundColor = bgColor;

			applyFormat();

			this.width = w;
			this.height = h;

			addEventListener(FocusEvent.FOCUS_IN, onFocusIn, false, 0, true);
			addEventListener(FocusEvent.FOCUS_OUT, onFocusOut, false, 0, true);
		}

		private function applyFormat():void {
			const fmt:TextFormat = new TextFormat("_sans", _fontSize, _textColor, _isBold, null, null, null, null, _align);
			this.defaultTextFormat = fmt;
			this.setTextFormat(fmt);
		}

		public function setFontSize(size:Number, bold:Boolean = false):void {
			this._fontSize = size;
			this._isBold = bold;
			applyFormat();
		}

		public function setBorderColors(normal:uint, focus:uint):void {
			this._borderNormal = normal;
			this._borderFocus = focus;
			this.borderColor = normal;
		}

		public function get trimmedText():String {
			return Utils.trim(text);
		}

		public function clear():void {
			this.text = "";
		}

		private function onFocusIn(e:FocusEvent):void {
			this.borderColor = _borderFocus;
		}

		private function onFocusOut(e:FocusEvent):void {
			this.borderColor = _borderNormal;
		}
	}
}
