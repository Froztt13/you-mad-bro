package ui {

	import flash.display.*;
	import flash.text.*;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import engine.AppUpdater;

	public class VersionDisplay extends Sprite {

		private var tf:TextField;

		public function VersionDisplay(version:String) {
			mouseChildren = false;
			buttonMode = true;
			useHandCursor = true;

			// Transparent hit area for reliable clicks
			graphics.beginFill(0x000000, 0.0);
			graphics.drawRect(-215, 5, 210, 24);
			graphics.endFill();

			tf = new TextField();

			const format:TextFormat = new TextFormat("_sans", 11, 0xffffff, false, null, null, null, null, TextFormatAlign.RIGHT);

			tf.defaultTextFormat = format;
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.width = 200;
			tf.height = 20;
			tf.x = -210;
			tf.y = 10;
			tf.alpha = 0.5;
			tf.text = "YouMadBro " + version;
			tf.filters = [new GlowFilter(0x000000, 0.8, 2, 2, 3, 1)];

			addChild(tf);

			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);
			addEventListener(MouseEvent.CLICK, onClick);

			if (stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private function onRollOver(e:MouseEvent):void {
			if (tf != null) {
				tf.alpha = 1.0;
			}
		}

		private function onRollOut(e:MouseEvent):void {
			if (tf != null) {
				tf.alpha = 0.5;
			}
		}

		private function onClick(e:MouseEvent):void {
			if (stage != null) {
				AppUpdater.checkUpdate(stage, true);
			}
		}

		private function onAdded(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			if (stage != null) {
				this.x = stage.stageWidth;
				this.y = 0;
				stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			}
		}

		private function onStageResize(e:Event):void {
			if (stage != null) {
				this.x = stage.stageWidth;
			}
		}

		public function updateStatus(isLoggedIn:Boolean):void {
			this.visible = !isLoggedIn;
		}
	}
}
