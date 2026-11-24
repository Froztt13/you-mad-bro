package ui {

	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.filters.DropShadowFilter;

	public class InfoMessage extends Sprite {

		private static const UI_WIDTH:Number = 360;
		private static const MIN_HEIGHT:Number = 150;
		private static const PADDING:Number = 18;

		private var boxHeight:Number = MIN_HEIGHT;

		public function InfoMessage(title:String, description:String, listItems:Array = null, listTitle:String = null) {
			addEventListener(Event.ADDED_TO_STAGE, onAdded);

			const contentW:Number = UI_WIDTH - PADDING * 2;

			// Title
			const titleLabel:TextField = createLabel(title, UIUtils.TEXT_WHITE, 15, true, TextFormatAlign.CENTER);
			titleLabel.x = PADDING;
			titleLabel.y = PADDING;
			titleLabel.width = contentW;
			titleLabel.height = 24;

			// Description
			const descLabel:TextField = createLabel(description != null ? description : "", UIUtils.TEXT_MAIN, 12, false, TextFormatAlign.CENTER);
			descLabel.x = PADDING;
			descLabel.y = titleLabel.y + titleLabel.height + 8;
			descLabel.width = contentW;
			descLabel.multiline = true;
			descLabel.wordWrap = true;
			const descHeight:Number = Math.max(22, Math.min(180, descLabel.textHeight + 8));
			descLabel.height = descHeight;

			var currentY:Number = descLabel.y + descHeight + 12;

			// Optional Recessed List Box (for warnings / errors / item lists)
			var listHeaderLabel:TextField = null;
			var listBoxBg:Shape = null;
			var listScroll:ScrollContainer = null;

			if (listItems != null && listItems.length > 0) {
				if (listTitle != null && listTitle.length > 0) {
					listHeaderLabel = createLabel(listTitle, 0xfbbf24, 11, true, TextFormatAlign.LEFT);
					listHeaderLabel.x = PADDING;
					listHeaderLabel.y = currentY;
					listHeaderLabel.width = contentW;
					listHeaderLabel.height = 18;
					currentY += 22;
				}

				const rowH:Number = 20;
				const listPad:Number = 6;
				const totalRowsH:Number = listItems.length * rowH + listPad * 2;
				const listBoxH:Number = Math.max(36, Math.min(110, totalRowsH));

				listBoxBg = new Shape();
				UIUtils.drawRoundedRect(listBoxBg.graphics, PADDING, currentY, contentW, listBoxH, 6, UIUtils.BG_RECESSED, 1.0, 0x92400e, 1);

				listScroll = new ScrollContainer(contentW - 4, listBoxH - 4, 4, true);
				listScroll.x = PADDING + 2;
				listScroll.y = currentY + 2;

				var rowY:Number = listPad - 2;
				for (var i:int = 0; i < listItems.length; i++) {
					var rowTxt:TextField = createLabel("• " + String(listItems[i]), UIUtils.TEXT_MAIN, 11, false, TextFormatAlign.LEFT);
					rowTxt.x = 8;
					rowTxt.y = rowY;
					rowTxt.width = listScroll.contentWidth - 16;
					rowTxt.height = rowH;
					listScroll.addItem(rowTxt);
					rowY += rowH;
				}
				listScroll.updateScroll(rowY + 4);

				currentY += listBoxH + 14;
			}
			else {
				currentY += 6;
			}

			boxHeight = Math.max(MIN_HEIGHT, currentY + 28 + PADDING);

			// Background
			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, UI_WIDTH, boxHeight, 10, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1.5);
			bg.filters = [new DropShadowFilter(8, 45, 0x000000, 0.7, 16, 16, 1, 2)];
			addChild(bg);
			addChild(titleLabel);
			addChild(descLabel);

			if (listHeaderLabel != null) {
				addChild(listHeaderLabel);
			}
			if (listBoxBg != null) {
				addChild(listBoxBg);
			}
			if (listScroll != null) {
				addChild(listScroll);
			}

			// OK Button
			const self:Sprite = this;
			const okBtn:MyButton = new MyButton("OK", 90, 28, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					visible = false;
					if (self.parent != null) {
						self.parent.removeChild(self);
					}
				});
			okBtn.x = (UI_WIDTH - 90) / 2;
			okBtn.y = boxHeight - PADDING - 28;
			addChild(okBtn);
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.x = (stage.stageWidth - UI_WIDTH) / 2;
			this.y = (stage.stageHeight - boxHeight) / 2;
		}

		private function createLabel(text:String, color:uint, size:int, bold:Boolean, align:String = "center"):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, align);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}
	}
}
