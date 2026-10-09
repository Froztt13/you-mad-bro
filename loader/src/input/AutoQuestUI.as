package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import flash.ui.Keyboard;

	import engine.AutoQuest;
	import ui.CloseButton;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.ChipTag;
	import Utils;

	public class AutoQuestUI extends Sprite {

		private static const UI_WIDTH:Number = 200;
		private static const UI_HEIGHT:Number = 380;
		private static const PADDING:Number = 12;

		public static var instance:AutoQuestUI;

		private var autoQuest:AutoQuest;
		private var modalBg:Shape;
		private var questIdInput:MyTextField;
		private var addBtn:MyButton;
		private var startBtn:MyButton;
		private var statusLabel:TextField;
		private var emptyLabel:TextField;
		private var chipContainer:Sprite;
		private var running:Boolean = false;
		private var pendingQuestIds:Array = null;

		public function AutoQuestUI(autoQuest:AutoQuest) {
			instance = this;
			this.autoQuest = autoQuest;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			buildUI();
			this.addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown);
		}

		private function onPanelMouseDown(e:MouseEvent):void {
			if (e.target == this || e.target == modalBg) {
				this.startDrag();
				stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
			}
		}

		private function onPanelMouseUp(e:MouseEvent):void {
			this.stopDrag();
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
			}
		}

		private function buildUI():void {
			// Background panel
			modalBg = new Shape();
			drawRoundedRect(modalBg.graphics, 0, 0, UI_WIDTH, UI_HEIGHT, 8, 0x0f172a, 0.98, 0x334155, 1);
			modalBg.filters = [new DropShadowFilter(12, 90, 0x000000, 0.7, 18, 18)];
			addChild(modalBg);

			// Header Bar (Draggable)
			const headerBar:Sprite = new Sprite();
			headerBar.graphics.beginFill(0x0a0e1a, 0.98);
			headerBar.graphics.drawRoundRectComplex(0, 0, UI_WIDTH, 36, 8, 8, 0, 0);
			headerBar.graphics.endFill();
			headerBar.graphics.lineStyle(1, 0x1e293b, 1);
			headerBar.graphics.moveTo(0, 36);
			headerBar.graphics.lineTo(UI_WIDTH, 36);
			addChild(headerBar);

			headerBar.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					startDrag();
					stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
				});

			const titleTf:TextField = createLabel("Auto Quest", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 85;
			headerBar.addChild(titleTf);

			const subTf:TextField = createLabel("Queue", 0x64748b, 10, false);
			subTf.x = 92;
			subTf.y = 11;
			subTf.width = 60;
			headerBar.addChild(subTf);

			// Close Button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22;
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			addChild(closeBtn);

			// Section 1: Add Quest
			const addHeader:TextField = createLabel("ADD QUEST ID", 0x64748b, 9.5, true);
			addHeader.x = PADDING;
			addHeader.y = 46;
			addHeader.width = 120;
			addChild(addHeader);

			// Input Field
			questIdInput = new MyTextField(128, 24, 12.5);
			questIdInput.x = PADDING;
			questIdInput.y = 64;
			questIdInput.maxChars = 128;
			questIdInput.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown, false, 0, true);
			addChild(questIdInput);

			// Add Button
			addBtn = new MyButton("Add", 42, 24, MyButton.TYPE_PRIMARY, onAddClick);
			addBtn.x = 146;
			addBtn.y = 64;
			addChild(addBtn);

			// Section 2: Queue Box
			const queueHeader:TextField = createLabel("QUEUED QUESTS", 0x64748b, 9.5, true);
			queueHeader.x = PADDING;
			queueHeader.y = 98;
			queueHeader.width = 120;
			addChild(queueHeader);

			const queueBox:Shape = new Shape();
			drawRoundedRect(queueBox.graphics, PADDING, 116, UI_WIDTH - PADDING * 2, 204, 6, 0x070b14, 0.95, 0x1e293b, 1);
			addChild(queueBox);

			chipContainer = new Sprite();
			chipContainer.x = PADDING + 6;
			chipContainer.y = 122;
			addChild(chipContainer);

			emptyLabel = createLabel("No quests queued.\nEnter a quest ID above.", 0x64748b, 10, false, TextFormatAlign.CENTER);
			emptyLabel.x = PADDING;
			emptyLabel.y = 200;
			emptyLabel.width = UI_WIDTH - PADDING * 2;
			emptyLabel.height = 36;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;
			addChild(emptyLabel);

			// Divider Line
			const divider:Shape = new Shape();
			divider.graphics.lineStyle(1, 0x1e293b, 1);
			divider.graphics.moveTo(PADDING, 330);
			divider.graphics.lineTo(UI_WIDTH - PADDING, 330);
			addChild(divider);

			// Footer: Status Label
			statusLabel = createLabel("Idle", 0x64748b, 10, true);
			statusLabel.x = PADDING;
			statusLabel.y = 345;
			statusLabel.width = 84;
			statusLabel.height = 20;
			addChild(statusLabel);

			// Footer: Start / Stop Button
			startBtn = new MyButton("Start", 88, 26, MyButton.TYPE_SUCCESS, onStartStopClick);
			startBtn.x = 100;
			startBtn.y = 341;
			addChild(startBtn);

			// Center if added to stage without explicit coordinate assignment
			if (stage != null && x == 0 && y == 0) {
				x = (stage.stageWidth - UI_WIDTH) / 2;
				y = (stage.stageHeight - UI_HEIGHT) / 2;
			}

			if (pendingQuestIds != null) {
				setQuestIds(pendingQuestIds);
				pendingQuestIds = null;
			}
		}

		private function buildChip(id:String):Sprite {
			const chip:ChipTag = new ChipTag(id, 78, 24, true, onRemoveChip);
			chip.name = id;
			return chip;
		}

		private function onRemoveChip(tag:ChipTag):void {
			chipContainer.removeChild(tag);

			if (QuestTreeUI.instance != null) {
				QuestTreeUI.instance.onQuestRemoved(tag.name);
			}

			rearrangeChips();
		}

		private function onAddClick(e:MouseEvent):void {
			addQuestId(questIdInput.text);
			questIdInput.text = "";
		}

		private function rearrangeChips():void {
			const cols:int = 2;
			const chipWidth:Number = 78;
			const chipHeight:Number = 24;
			const gapX:Number = 8;
			const gapY:Number = 6;

			for (var i:int = 0; i < chipContainer.numChildren; i++) {
				var chip:Sprite = Sprite(chipContainer.getChildAt(i));
				const row:int = Math.floor(i / cols);
				const col:int = i % cols;

				chip.x = col * (chipWidth + gapX);
				chip.y = row * (chipHeight + gapY);
			}

			if (emptyLabel != null) {
				emptyLabel.visible = (chipContainer.numChildren == 0);
			}
		}

		private function onCloseClick(e:MouseEvent):void {
			visible = false;
		}

		private function onInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				addQuestId(questIdInput.text);
				questIdInput.text = "";
				e.preventDefault();
			}
		}

		private function onStartStopClick(e:MouseEvent):void {
			startOrStop();
		}

		private function startOrStop():void {
			var ids:Array = [];
			for (var i:int = 0; i < chipContainer.numChildren; i++) {
				ids.push(chipContainer.getChildAt(i).name);
			}

			if (ids.length == 0) {
				return;
			}

			if (running) {
				stop();
			}
			else {
				start(ids.join(","));
			}
		}

		private function start(ids:String):void {
			running = true;
			statusLabel.text = "Running...";
			statusLabel.textColor = 0x4ade80;
			startBtn.setType(MyButton.TYPE_DANGER);
			startBtn.label = "Stop";
			autoQuest.startAutoQuest(ids);
		}

		public function startAutoQuest():void {
			var ids:Array = [];
			for (var i:int = 0; i < chipContainer.numChildren; i++) {
				ids.push(chipContainer.getChildAt(i).name);
			}

			if (ids.length == 0) {
				return;
			}

			if (!running) {
				start(ids.join(","));
			}
		}

		public function stop():void {
			running = false;
			statusLabel.text = "Idle";
			statusLabel.textColor = 0x64748b;
			startBtn.setType(MyButton.TYPE_SUCCESS);
			startBtn.label = "Start";
			autoQuest.stopAutoQuest();
		}

		public function stopAutoQuest():void {
			if (running) {
				stop();
			}
		}

		public function isAutoQuestRunning():Boolean {
			return running;
		}

		public function getQuestIds():Array {
			var ids:Array = [];
			if (chipContainer != null) {
				for (var i:int = 0; i < chipContainer.numChildren; i++) {
					ids.push(chipContainer.getChildAt(i).name);
				}
			}
			else if (pendingQuestIds != null) {
				return pendingQuestIds.slice();
			}
			return ids;
		}

		public function clearQuests():void {
			if (chipContainer != null) {
				while (chipContainer.numChildren > 0) {
					chipContainer.removeChildAt(0);
				}
				rearrangeChips();
			}
			pendingQuestIds = null;
		}

		public function setQuestIds(ids:Array):void {
			if (chipContainer == null) {
				pendingQuestIds = (ids != null) ? ids.slice() : [];
				return;
			}
			clearQuests();
			if (ids != null) {
				for each (var id:* in ids) {
					if (id != null) {
						addQuestId(String(id));
					}
				}
			}
		}

		public function addQuestId(id:String):void {
			if (id == null || id.length == 0)
				return;

			var parts:Array = id.split(",");
			for (var i:int = 0; i < parts.length; i++) {
				var cleanId:String = Utils.trim(parts[i]);
				if (cleanId.length > 0 && !hasQuestId(cleanId)) {
					const chip:Sprite = buildChip(cleanId);
					chipContainer.addChild(chip);
				}
			}
			rearrangeChips();
		}

		public function hasQuestId(id:String):Boolean {
			for (var i:int = 0; i < chipContainer.numChildren; i++) {
				if (chipContainer.getChildAt(i).name == id) {
					return true;
				}
			}
			return false;
		}

		private static function createLabel(text:String, color:uint, size:Number, bold:Boolean = false, align:String = TextFormatAlign.LEFT):TextField {
			const tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			const fmt:TextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, align);
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}

		private static function drawRoundedRect(g:Graphics, x:Number, y:Number, w:Number, h:Number, r:Number, fillColor:uint, fillAlpha:Number, strokeColor:uint = 0, strokeThickness:Number = 0):void {
			g.clear();
			g.beginFill(fillColor, fillAlpha);
			if (strokeThickness > 0) {
				g.lineStyle(strokeThickness, strokeColor, 1.0);
			}
			g.drawRoundRect(x, y, w, h, r);
			g.endFill();
		}
	}
}
