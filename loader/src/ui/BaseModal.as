package ui {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class BaseModal extends Sprite {

		public static const HEADER_HEIGHT:Number = 36;
		public static const PADDING:Number = 12;

		protected var _modalWidth:Number;
		protected var _modalHeight:Number;
		protected var _modalBg:Shape;
		protected var _headerBar:Sprite;
		protected var _titleTf:TextField;
		protected var _subTf:TextField;
		protected var _closeBtn:CloseButton;

		public function BaseModal(w:Number, h:Number, title:String, subtitle:String = "") {
			super();

			this._modalWidth = w;
			this._modalHeight = h;

			// Background Panel
			_modalBg = new Shape();
			UIUtils.drawRoundedRect(_modalBg.graphics, 0, 0, w, h, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			_modalBg.filters = [UIUtils.createShadow()];
			addChild(_modalBg);

			// Draggable Header Bar
			_headerBar = new Sprite();
			_headerBar.graphics.beginFill(UIUtils.BG_HEADER, 0.98);
			_headerBar.graphics.drawRoundRectComplex(0, 0, w, HEADER_HEIGHT, 8, 8, 0, 0);
			_headerBar.graphics.endFill();
			_headerBar.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			_headerBar.graphics.moveTo(0, HEADER_HEIGHT);
			_headerBar.graphics.lineTo(w, HEADER_HEIGHT);
			addChild(_headerBar);

			_headerBar.addEventListener(MouseEvent.MOUSE_DOWN, onHeaderMouseDown, false, 0, true);

			// Title
			_titleTf = UIUtils.createLabel(title, UIUtils.TEXT_WHITE, 12, true);
			_titleTf.x = PADDING;
			_titleTf.y = 9;
			_titleTf.width = 140;
			_headerBar.addChild(_titleTf);

			// Subtitle
			if (subtitle != null && subtitle.length > 0) {
				_subTf = UIUtils.createLabel(subtitle, UIUtils.TEXT_DIM, 9.5, false);
				_subTf.x = PADDING + _titleTf.textWidth + 12;
				_subTf.y = 11;
				_subTf.width = 120;
				_headerBar.addChild(_subTf);
			}

			// Close Button
			_closeBtn = new CloseButton();
			_closeBtn.x = w - PADDING - 22;
			_closeBtn.y = 7;
			_closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			_headerBar.addChild(_closeBtn);

			addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStageInternal, false, 0, true);
		}

		private function onAddedToStageInternal(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageInternal);
			if (x == 0 && y == 0) {
				centerOnStage();
			}
		}

		public function centerOnStage():void {
			if (stage != null) {
				x = int((stage.stageWidth - _modalWidth) / 2);
				y = int((stage.stageHeight - _modalHeight) / 2);
			}
		}

		public function addDivider(yPos:Number):Shape {
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(PADDING, yPos);
			div.graphics.lineTo(_modalWidth - PADDING, yPos);
			addChild(div);
			return div;
		}

		public function addHeaderControl(control:Sprite):void {
			_headerBar.addChild(control);
		}

		public function get header():Sprite {
			return _headerBar;
		}

		public function get closeButton():CloseButton {
			return _closeBtn;
		}

		public function get modalWidth():Number {
			return _modalWidth;
		}

		public function get modalHeight():Number {
			return _modalHeight;
		}

		protected function onCloseClick(e:MouseEvent):void {
			this.visible = false;
			dispatchEvent(new Event(Event.CLOSE));
		}

		private function onHeaderMouseDown(e:MouseEvent):void {
			startDrag();
			if (stage != null) {
				stage.addEventListener(MouseEvent.MOUSE_UP, onDragStop, false, 0, true);
			}
		}

		private function onPanelMouseDown(e:MouseEvent):void {
			if (e.target == this || e.target == _modalBg) {
				startDrag();
				if (stage != null) {
					stage.addEventListener(MouseEvent.MOUSE_UP, onDragStop, false, 0, true);
				}
			}
		}

		private function onDragStop(e:MouseEvent):void {
			stopDrag();
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, onDragStop);
			}
		}
	}
}
