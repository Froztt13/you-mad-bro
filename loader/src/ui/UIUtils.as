package ui {

	import flash.display.Graphics;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class UIUtils {

		// Modern Slate Color Palette
		public static const BG_DARK:uint = 0x0f172a; // Modal panel background
		public static const BG_HEADER:uint = 0x0a0e1a; // Header bar background
		public static const BG_RECESSED:uint = 0x070b14; // Inner list / input background
		public static const BG_HOVER:uint = 0x1e293b; // Interactive item hover

		public static const BORDER_SUBTLE:uint = 0x1e293b; // Subtle divider / inner borders
		public static const BORDER_NORMAL:uint = 0x334155; // Standard input / item borders
		public static const BORDER_HOVER:uint = 0x475569; // Highlighted border on hover
		public static const BORDER_FOCUS:uint = 0x3b82f6; // Focused input border (blue)

		public static const TEXT_WHITE:uint = 0xf8fafc;
		public static const TEXT_MAIN:uint = 0xf1f5f9;
		public static const TEXT_MUTED:uint = 0x94a3b8;
		public static const TEXT_DIM:uint = 0x64748b;

		public static const COLOR_PRIMARY:uint = 0x2563eb; // Royal blue
		public static const COLOR_SUCCESS:uint = 0x15803d; // Emerald green
		public static const COLOR_DANGER:uint = 0xb91c1c; // Red
		public static const COLOR_WARNING:uint = 0xd97706; // Amber

		public static function drawRoundedRect(
				g:Graphics,
				x:Number,
				y:Number,
				w:Number,
				h:Number,
				r:Number,
				fillColor:uint,
				fillAlpha:Number = 1.0,
				strokeColor:uint = 0,
				strokeThickness:Number = 0
			):void {
			g.clear();
			g.beginFill(fillColor, fillAlpha);
			if (strokeThickness > 0) {
				g.lineStyle(strokeThickness, strokeColor, 1.0);
			}
			g.drawRoundRect(x, y, w, h, r);
			g.endFill();
		}

		public static function createLabel(
				text:String,
				color:uint = TEXT_MAIN,
				size:Number = 11,
				bold:Boolean = false,
				align:String = TextFormatAlign.LEFT
			):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			if (align == TextFormatAlign.LEFT) {
				tf.autoSize = TextFieldAutoSize.LEFT;
			}
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, align);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}

		public static function createShadow(distance:Number = 12, angle:Number = 90, alpha:Number = 0.7):DropShadowFilter {
			return new DropShadowFilter(distance, angle, 0x000000, alpha, 18, 18);
		}
	}
}
