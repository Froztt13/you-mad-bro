package ui {

	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class ScrollContainer extends Sprite {

		private var _viewWidth:Number;
		private var _viewHeight:Number;
		private var _scrollbarWidth:Number;
		private var _paddingX:Number = 4;
		private var _paddingY:Number = 4;

		private var _bg:Shape;
		private var _contentMask:Shape;
		private var _content:Sprite;
		private var _scrollbar:Sprite;
		private var _scrollThumb:Sprite;
		private var _thumbBg:Shape;

		private var _isDragging:Boolean = false;
		private var _dragStartY:Number = 0;
		private var _thumbStartY:Number = 0;
		private var _scrollY:Number = 0;
		private var _maxScrollY:Number = 0;
		private var _thumbHeight:Number = 30;

		public function ScrollContainer(
				w:Number,
				h:Number,
				scrollbarWidth:Number = 10,
				hasRecessedBg:Boolean = false,
				paddingX:Number = 4,
				paddingY:Number = 4
			) {
			super();

			this._viewWidth = w;
			this._viewHeight = h;
			this._scrollbarWidth = scrollbarWidth;
			this._paddingX = paddingX;
			this._paddingY = paddingY;

			if (hasRecessedBg) {
				_bg = new Shape();
				UIUtils.drawRoundedRect(_bg.graphics, 0, 0, w, h, 6, UIUtils.BG_RECESSED, 0.95, UIUtils.BORDER_SUBTLE, 1);
				addChild(_bg);
			}

			// Content container offset by inner padding
			_content = new Sprite();
			_content.x = _paddingX;
			_content.y = _paddingY;
			addChild(_content);

			// Mask covering the scrollable view area
			_contentMask = new Shape();
			_contentMask.x = _paddingX;
			_contentMask.y = _paddingY;
			_content.mask = _contentMask;
			addChild(_contentMask);

			// Scrollbar positioned on the right with symmetrical right padding
			_scrollbar = new Sprite();
			_scrollbar.x = w - _paddingX - _scrollbarWidth;
			_scrollbar.y = _paddingY;
			_scrollbar.visible = false;
			addChild(_scrollbar);

			const scrollAreaH:Number = Math.max(10, h - (_paddingY * 2));
			const cornerRadius:Number = Math.min(5, _scrollbarWidth / 2);
			const trackBg:Shape = new Shape();
			UIUtils.drawRoundedRect(trackBg.graphics, 0, 0, _scrollbarWidth, scrollAreaH, cornerRadius, UIUtils.BG_RECESSED, 0.5);
			_scrollbar.addChild(trackBg);

			_scrollThumb = new Sprite();
			_thumbBg = new Shape();
			_scrollThumb.addChild(_thumbBg);
			_scrollThumb.buttonMode = true;
			_scrollThumb.useHandCursor = true;
			_scrollbar.addChild(_scrollThumb);

			_scrollbar.buttonMode = true;
			_scrollbar.useHandCursor = true;
			_scrollbar.addEventListener(MouseEvent.MOUSE_DOWN, onTrackMouseDown, false, 0, true);

			_scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown, false, 0, true);
			_scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver, false, 0, true);
			_scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut, false, 0, true);

			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);

			drawThumb(false);
			updateMask();
		}

		public function get content():Sprite {
			return _content;
		}

		public function get contentWidth():Number {
			const scrollAreaW:Number = _viewWidth - (_paddingX * 2);
			// Always reserve space for scrollbar + 3px gap to guarantee stable layout and prevent scrollbar overlap
			return Math.max(10, scrollAreaW - _scrollbarWidth - 3);
		}

		public function get isScrollbarVisible():Boolean {
			return _scrollbar != null && _scrollbar.visible;
		}

		public function get scrollY():Number {
			return _scrollY;
		}

		public function set scrollY(val:Number):void {
			_scrollY = Math.max(0, Math.min(val, _maxScrollY));
			applyScroll();
		}

		public function get viewHeight():Number {
			return _viewHeight;
		}

		public function addItem(item:DisplayObject):void {
			_content.addChild(item);
		}

		public function clearContent(resetScroll:Boolean = false):void {
			while (_content.numChildren > 0) {
				_content.removeChildAt(0);
			}
			if (resetScroll) {
				_scrollY = 0;
				_maxScrollY = 0;
				if (_scrollbar != null) {
					_scrollbar.visible = false;
				}
				applyScroll();
			}
		}

		public function ensureVisible(itemY:Number, itemHeight:Number):void {
			const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));
			if (itemY < _scrollY) {
				scrollY = itemY;
			}
			else if (itemY + itemHeight > _scrollY + scrollAreaH) {
				scrollY = (itemY + itemHeight) - scrollAreaH;
			}
		}

		private function updateMask():void {
			const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));
			const maskW:Number = Math.max(10, _viewWidth - (_paddingX * 2));
			_contentMask.graphics.clear();
			_contentMask.graphics.beginFill(0x000000);
			_contentMask.graphics.drawRect(0, 0, maskW, scrollAreaH);
			_contentMask.graphics.endFill();
		}

		public function updateScroll(totalContentHeight:Number = -1):void {
			if (totalContentHeight < 0) {
				totalContentHeight = _content.height;
			}

			const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));

			if (totalContentHeight > scrollAreaH) {
				_maxScrollY = totalContentHeight - scrollAreaH;
				_thumbHeight = Math.max(30, (scrollAreaH / totalContentHeight) * scrollAreaH);

				drawThumb(false);

				_scrollbar.visible = true;
				_scrollY = Math.min(_scrollY, _maxScrollY);
			}
			else {
				_scrollbar.visible = false;
				_scrollY = 0;
				_maxScrollY = 0;
			}

			applyScroll();
		}

		public function scrollToBottom():void {
			if (_maxScrollY > 0) {
				_scrollY = _maxScrollY;
				applyScroll();
			}
		}

		public function scrollToTop():void {
			_scrollY = 0;
			applyScroll();
		}

		private function applyScroll():void {
			_content.y = _paddingY - _scrollY;
			if (_maxScrollY > 0) {
				const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));
				const maxThumbY:Number = scrollAreaH - _thumbHeight;
				_scrollThumb.y = (_scrollY / _maxScrollY) * maxThumbY;
			}
		}

		private function onMouseWheel(e:MouseEvent):void {
			if (_maxScrollY <= 0)
				return;
			const step:Number = 24;
			if (e.delta > 0) {
				_scrollY = Math.max(0, _scrollY - step);
			}
			else if (e.delta < 0) {
				_scrollY = Math.min(_maxScrollY, _scrollY + step);
			}
			applyScroll();
		}

		private function onThumbMouseDown(e:MouseEvent):void {
			_isDragging = true;
			_dragStartY = e.stageY;
			_thumbStartY = _scrollThumb.y;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, 0, true);
			e.stopImmediatePropagation();
		}

		private function onStageMouseMove(e:MouseEvent):void {
			if (!_isDragging)
				return;

			const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));
			const maxThumbY:Number = scrollAreaH - _thumbHeight;
			const deltaY:Number = e.stageY - _dragStartY;
			var newThumbY:Number = _thumbStartY + deltaY;
			newThumbY = Math.max(0, Math.min(newThumbY, maxThumbY));

			_scrollY = (maxThumbY > 0) ? (newThumbY / maxThumbY) * _maxScrollY : 0;
			applyScroll();
		}

		private function onStageMouseUp(e:MouseEvent):void {
			_isDragging = false;
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			}
		}

		private function onThumbRollOver(e:MouseEvent):void {
			drawThumb(true);
		}

		private function onThumbRollOut(e:MouseEvent):void {
			drawThumb(false);
		}

		private function onTrackMouseDown(e:MouseEvent):void {
			if (e.target == _scrollThumb || _scrollThumb.contains(e.target as DisplayObject)) {
				return;
			}
			const scrollAreaH:Number = Math.max(10, _viewHeight - (_paddingY * 2));
			const maxThumbY:Number = scrollAreaH - _thumbHeight;
			if (maxThumbY > 0 && _maxScrollY > 0) {
				var targetThumbY:Number = _scrollbar.mouseY - (_thumbHeight / 2);
				targetThumbY = Math.max(0, Math.min(targetThumbY, maxThumbY));
				_scrollY = (targetThumbY / maxThumbY) * _maxScrollY;
				applyScroll();
			}
		}

		private function drawThumb(isHover:Boolean = false):void {
			const cornerRadius:Number = Math.min(5, _scrollbarWidth / 2);
			const borderCol:uint = isHover ? UIUtils.BORDER_HOVER : UIUtils.BORDER_NORMAL;
			const alphaVal:Number = isHover ? 1.0 : 0.9;

			// Invisible expanded touch hit target (+6px padding on left/right for mobile touchscreens)
			_scrollThumb.graphics.clear();
			_scrollThumb.graphics.beginFill(0x000000, 0);
			_scrollThumb.graphics.drawRect(-6, 0, _scrollbarWidth + 12, _thumbHeight);
			_scrollThumb.graphics.endFill();

			// Visible rounded pill thumb
			UIUtils.drawRoundedRect(_thumbBg.graphics, 0, 0, _scrollbarWidth, _thumbHeight, cornerRadius, borderCol, alphaVal);
		}
	}
}
