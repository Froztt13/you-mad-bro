package ui {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;

	public class CloseButton extends Sprite {

		public function CloseButton() {
			const closeBg:Shape = new Shape();
			closeBg.graphics.beginFill(0x333333, 0.9);
			closeBg.graphics.drawRoundRect(0, 0, 22, 22, 5);
			addChild(closeBg);

			const closeLabel:TextField = new TextField();
			closeLabel.selectable = false;
			closeLabel.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", 12, 0xffffff, true, null, null, null, null, TextFormatAlign.CENTER);
			closeLabel.defaultTextFormat = fmt;
			closeLabel.text = "✕";
			closeLabel.textColor = 0xffffff;
			closeLabel.width = 22;
			closeLabel.height = 22;
			closeLabel.y = 2;
			addChild(closeLabel);

			this.buttonMode = true;
			this.useHandCursor = true;
		}
	}
}
