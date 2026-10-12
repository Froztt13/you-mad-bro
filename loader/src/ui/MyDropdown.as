package ui {

	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	public class MyDropdown extends Sprite {

		private var _w:Number;
		private var _h:Number;
		private var _r:Number;
		private var _items:Array = [];
		private var _selectedIndex:int = -1;
		private var _onChange:Function;
		private var _isOpen:Boolean = false;

		private var _headerBtn:Sprite;
		private var _headerBg:Shape;
		private var _headerLabel:TextField;
		private var _arrowLabel:TextField;

		private var _popup:Sprite;
		private var _popupBg:Shape;
		private var _itemsContainer:Sprite;

		public function MyDropdown(
				w:Number = 160,
				h:Number = 24,
				items:Array = null,
				onChange:Function = null,
				radius:Number = 4
			) {
			super();

			this._w = w;
			this._h = h;
			this._r = radius;
			this._onChange = onChange;

			buildHeader();
			buildPopup();

			if (items != null && items.length > 0) {
				setItems(items);
			}

			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}

		private function buildHeader():void {
			_headerBtn = new Sprite();
			_headerBtn.buttonMode = true;
			_headerBtn.useHandCursor = true;
			_headerBtn.mouseChildren = false;

			_headerBg = new Shape();
			_headerBtn.addChild(_headerBg);

			_headerLabel = UIUtils.createLabel("", UIUtils.TEXT_MAIN, 11, false, TextFormatAlign.LEFT);
			_headerLabel.x = 8;
			_headerLabel.width = _w - 24;
			_headerLabel.height = _h;
			_headerLabel.y = int((_h - 16) / 2);
			_headerBtn.addChild(_headerLabel);

			_arrowLabel = UIUtils.createLabel("▼", UIUtils.TEXT_MUTED, 8, false, TextFormatAlign.CENTER);
			_arrowLabel.x = _w - 18;
			_arrowLabel.width = 16;
			_arrowLabel.height = _h;
			_arrowLabel.y = int((_h - 14) / 2);
			_headerBtn.addChild(_arrowLabel);

			drawHeader(false);

			_headerBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					if (!_isOpen) drawHeader(true);
				});
			_headerBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
				if (!_isOpen) drawHeader(false);
			});
			_headerBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				toggle();
			});

			addChild(_headerBtn);
		}

		private function drawHeader(hover:Boolean):void {
			var bg:uint = hover || _isOpen ? UIUtils.BG_HOVER : UIUtils.BG_RECESSED;
			var border:uint = _isOpen ? UIUtils.BORDER_FOCUS : (hover ? UIUtils.BORDER_HOVER : UIUtils.BORDER_NORMAL);
			UIUtils.drawRoundedRect(_headerBg.graphics, 0, 0, _w, _h, _r, bg, 1.0, border, 1);
		}

		private function buildPopup():void {
			_popup = new Sprite();
			_popup.y = _h + 2;
			_popup.visible = false;
			_popup.filters = [new DropShadowFilter(6, 90, 0x000000, 0.6, 10, 10, 1, 1)];

			_popupBg = new Shape();
			_popup.addChild(_popupBg);

			_itemsContainer = new Sprite();
			_popup.addChild(_itemsContainer);

			addChild(_popup);
		}

		public function setItems(items:Array):void {
			_items = [];
			if (items != null) {
				for (var i:int = 0; i < items.length; i++) {
					var item:Object = items[i];
					if (item is String) {
						_items.push({label: String(item), value: item});
					}
					else if (item != null && item.label != null) {
						_items.push({label: String(item.label), value: (item.value !== undefined ? item.value : item.label)});
					}
				}
			}

			rebuildPopupItems();

			if (_items.length > 0) {
				setSelectedIndex(0, false);
			}
			else {
				_selectedIndex = -1;
				_headerLabel.text = "";
			}
		}

		private function rebuildPopupItems():void {
			while (_itemsContainer.numChildren > 0) {
				_itemsContainer.removeChildAt(0);
			}

			const rowH:Number = 24;
			const totalH:Number = _items.length * rowH;

			UIUtils.drawRoundedRect(_popupBg.graphics, 0, 0, _w, totalH, _r, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);

			for (var i:int = 0; i < _items.length; i++) {
				var itemData:Object = _items[i];

				var row:Sprite = new Sprite();
				row.buttonMode = true;
				row.useHandCursor = true;
				row.mouseChildren = false;
				row.y = i * rowH;

				var rowBg:Shape = new Shape();
				UIUtils.drawRoundedRect(rowBg.graphics, 1, 0, _w - 2, rowH, 2, UIUtils.BG_DARK, 0.0);
				row.addChild(rowBg);

				var rowTf:TextField = UIUtils.createLabel(itemData.label, UIUtils.TEXT_MAIN, 11, false, TextFormatAlign.LEFT);
				rowTf.x = 8;
				rowTf.width = _w - 16;
				rowTf.height = rowH;
				rowTf.y = int((rowH - 16) / 2);
				rowTf.mouseEnabled = false;
				row.addChild(rowTf);

				row.addEventListener(MouseEvent.MOUSE_OVER, onRowMouseOver);
				row.addEventListener(MouseEvent.MOUSE_OUT, onRowMouseOut);
				row.addEventListener(MouseEvent.CLICK, makeRowClickHandler(i));

				_itemsContainer.addChild(row);
			}
		}

		private function onRowMouseOver(e:MouseEvent):void {
			var targetRow:Sprite = e.currentTarget as Sprite;
			if (targetRow != null && targetRow.numChildren > 0) {
				var bgShp:Shape = targetRow.getChildAt(0) as Shape;
				UIUtils.drawRoundedRect(bgShp.graphics, 1, 0, _w - 2, 24, 2, UIUtils.BG_HOVER, 1.0);
			}
		}

		private function onRowMouseOut(e:MouseEvent):void {
			var targetRow:Sprite = e.currentTarget as Sprite;
			if (targetRow != null && targetRow.numChildren > 0) {
				var bgShp:Shape = targetRow.getChildAt(0) as Shape;
				UIUtils.drawRoundedRect(bgShp.graphics, 1, 0, _w - 2, 24, 2, UIUtils.BG_DARK, 0.0);
			}
		}

		private function makeRowClickHandler(idx:int):Function {
			return function(e:MouseEvent):void {
				setSelectedIndex(idx, true);
				close();
			};
		}

		public function setSelectedIndex(index:int, triggerCallback:Boolean = true):void {
			if (index < 0 || index >= _items.length)
				return;

			_selectedIndex = index;
			_headerLabel.text = _items[index].label;

			if (triggerCallback && _onChange != null) {
				_onChange(_items[index]);
			}
		}

		public function setSelectedValue(val:*, triggerCallback:Boolean = true):void {
			for (var i:int = 0; i < _items.length; i++) {
				if (_items[i].value == val) {
					setSelectedIndex(i, triggerCallback);
					return;
				}
			}
		}

		public function get selectedIndex():int {
			return _selectedIndex;
		}

		public function get selectedItem():Object {
			if (_selectedIndex >= 0 && _selectedIndex < _items.length) {
				return _items[_selectedIndex];
			}
			return null;
		}

		public function get selectedValue():* {
			var itm:Object = selectedItem;
			return itm != null ? itm.value : null;
		}

		public function get selectedLabel():String {
			var itm:Object = selectedItem;
			return itm != null ? itm.label : "";
		}

		public function toggle():void {
			if (_isOpen) {
				close();
			}
			else {
				open();
			}
		}

		public function open():void {
			if (_isOpen || _items.length == 0)
				return;

			_isOpen = true;
			_popup.visible = true;
			drawHeader(false);

			if (parent != null) {
				parent.setChildIndex(this, parent.numChildren - 1);
			}

			if (stage != null) {
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
			}
		}

		public function close():void {
			if (!_isOpen)
				return;

			_isOpen = false;
			_popup.visible = false;
			drawHeader(false);

			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
			}
		}

		private function onStageMouseDown(e:MouseEvent):void {
			var targetObj:DisplayObject = e.target as DisplayObject;
			if (targetObj == null || !this.contains(targetObj)) {
				close();
			}
		}

		private function onRemovedFromStage(e:Event):void {
			close();
		}
	}
}
