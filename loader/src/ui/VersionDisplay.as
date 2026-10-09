package ui {

	import flash.display.*;
	import flash.text.*;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	import SFSEvent;

	public class VersionDisplay extends Sprite {

		private var tf:TextField;

		public function VersionDisplay(version:String) {
			tf = new TextField();

			const format:TextFormat = new TextFormat("_sans", 11, 0xffffff, false, null, null, null, null, TextFormatAlign.RIGHT);

			tf.defaultTextFormat = format;
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.width = 200;
			tf.height = 20;
			tf.x = -210; // offset from parent right edge
			tf.y = 10;
			tf.alpha = 0.5;
			tf.text = "YouMadBro " + version;

			// Simple glow/outline
			tf.filters = [new GlowFilter(0x000000, 0.8, 2, 2, 3, 1)];

			addChild(tf);

			if (stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private function onAdded(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.x = stage.stageWidth;
			this.y = 0;
		}

		public function updateStatus(isLoggedIn:Boolean):void {
			this.visible = !isLoggedIn;
		}
	}
}
