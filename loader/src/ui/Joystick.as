package ui {
	import flash.display.*;
	import flash.geom.*;

	public class Joystick extends Sprite {

		public static const RADIUS:Number = 72;
		public static const KNOB_RADIUS:Number = 28;
		public static const LIMIT:Number = RADIUS - KNOB_RADIUS * 0.4;

		public static const DEFAULT_X:Number = 73;
		public static const DEFAULT_Y:Number = 348;

		public var dirX:Number = 0;
		public var dirY:Number = 0;

		private var base:Shape;
		private var guideTrack:Shape;
		private var dynamicBeam:Shape;
		private var knob:Sprite;
		private var knobShadow:Shape;
		private var knobBody:Shape;
		private var isDragging:Boolean = false;

		public function Joystick() {
			mouseChildren = false;
			mouseEnabled = false;

			buildBase();
			buildGuideTrack();
			buildDynamicBeam();
			buildKnob();
		}

		public function move(stageX:Number, stageY:Number):void {
			const local:Point = globalToLocal(new Point(stageX, stageY));
			var dx:Number = local.x;
			var dy:Number = local.y;

			const dist:Number = Math.sqrt(dx * dx + dy * dy);

			if (dist > LIMIT) {
				dx = dx / dist * LIMIT;
				dy = dy / dist * LIMIT;
			}

			knob.x = dx;
			knob.y = dy;

			dirX = dx / LIMIT;
			dirY = dy / LIMIT;

			if (!isDragging) {
				isDragging = true;
				redrawKnob();
			}

			updateDynamicBeam(dx, dy, dist);
		}

		public function snapHome():void {
			knob.x = 0;
			knob.y = 0;
			dirX = 0;
			dirY = 0;

			if (isDragging) {
				isDragging = false;
				redrawKnob();
			}

			dynamicBeam.graphics.clear();
		}

		public function hitTest(stageX:Number, stageY:Number):Boolean {
			const local:Point = globalToLocal(new Point(stageX, stageY));
			return Math.sqrt(local.x * local.x + local.y * local.y) <= RADIUS + 20;
		}

		// =========================================================================
		// Base Rendering (Glassmorphism + Neon Cyber Elements)
		// =========================================================================

		private function buildBase():void {
			base = new Shape();
			const g:Graphics = base.graphics;

			// 1. Soft Outer Ambient Glow (Cyan halo)
			const mGlow:Matrix = new Matrix();
			mGlow.createGradientBox((RADIUS + 16) * 2, (RADIUS + 16) * 2, 0, -(RADIUS + 16), -(RADIUS + 16));
			g.beginGradientFill(
					GradientType.RADIAL,
					[0x0ea5e9, 0x0284c7, 0x000000],
					[0.18, 0.08, 0],
					[120, 200, 255],
					mGlow
				);
			g.drawCircle(0, 0, RADIUS + 16);
			g.endFill();

			// 2. Translucent Glassmorphic Disc
			const mBase:Matrix = new Matrix();
			mBase.createGradientBox(RADIUS * 2, RADIUS * 2, Math.PI * 0.45, -RADIUS, -RADIUS);
			g.beginGradientFill(
					GradientType.LINEAR,
					[0x1e293b, 0x0f172a, 0x070b14],
					[0.65, 0.70, 0.85],
					[0, 140, 255],
					mBase
				);
			g.drawCircle(0, 0, RADIUS);
			g.endFill();

			// 3. Crisp Beveled Outer Rim
			g.lineStyle(1.8, 0x38bdf8, 0.5);
			g.drawCircle(0, 0, RADIUS);

			// 4. Subtle Inset Dark Ring
			g.lineStyle(1.0, 0x0f172a, 0.6);
			g.drawCircle(0, 0, RADIUS - 2.5);

			// 5. Crosshair Division Lines (Subtle hair lines)
			g.lineStyle(1.0, 0x38bdf8, 0.12);
			g.moveTo(-RADIUS + 8, 0);
			g.lineTo(RADIUS - 8, 0);
			g.moveTo(0, -RADIUS + 8);
			g.lineTo(0, RADIUS - 8);

			addChild(base);
		}

		// =========================================================================
		// Directional Guide Track & Chevrons
		// =========================================================================

		private function buildGuideTrack():void {
			guideTrack = new Shape();
			const g:Graphics = guideTrack.graphics;

			// 1. Mid-range Telemetry Ring
			g.lineStyle(1.0, 0x38bdf8, 0.22);
			g.drawCircle(0, 0, RADIUS * 0.62);

			// 2. Inner Deadzone Boundary Ring
			g.lineStyle(1.0, 0x38bdf8, 0.18);
			g.drawCircle(0, 0, RADIUS * 0.26);

			// 3. Cardinal Direction Chevrons (Up, Down, Left, Right)
			const distN:Number = RADIUS * 0.80;
			drawChevron(g, 0, -distN, 0); // Up
			drawChevron(g, distN, 0, 90); // Right
			drawChevron(g, 0, distN, 180); // Down
			drawChevron(g, -distN, 0, 270); // Left

			// 4. Diagonal Accent Pips (45, 135, 225, 315 deg)
			const distDiag:Number = RADIUS * 0.80;
			const diagCoords:Array = [
					Math.cos(Math.PI * 0.25) * distDiag, Math.sin(Math.PI * 0.25) * distDiag,
					Math.cos(Math.PI * 0.75) * distDiag, Math.sin(Math.PI * 0.75) * distDiag,
					Math.cos(Math.PI * 1.25) * distDiag, Math.sin(Math.PI * 1.25) * distDiag,
					Math.cos(Math.PI * 1.75) * distDiag, Math.sin(Math.PI * 1.75) * distDiag
				];

			for (var i:int = 0; i < diagCoords.length; i += 2) {
				g.beginFill(0x38bdf8, 0.28);
				g.drawCircle(diagCoords[i], diagCoords[i + 1], 1.8);
				g.endFill();
			}

			addChild(guideTrack);
		}

		private function drawChevron(g:Graphics, cx:Number, cy:Number, rotationDeg:Number):void {
			const rad:Number = rotationDeg * Math.PI / 180;
			const cos:Number = Math.cos(rad);
			const sin:Number = Math.sin(rad);

			// Local triangle coordinates pointing up
			const pts:Array = [
					{x: 0, y: -4},
					{x: 4, y: 3},
					{x: -4, y: 3}
				];

			g.beginFill(0x38bdf8, 0.65);
			for (var i:int = 0; i < pts.length; i++) {
				var rx:Number = cx + (pts[i].x * cos - pts[i].y * sin);
				var ry:Number = cy + (pts[i].x * sin + pts[i].y * cos);
				if (i == 0)
					g.moveTo(rx, ry);
				else
					g.lineTo(rx, ry);
			}
			g.endFill();
		}

		// =========================================================================
		// Dynamic Energy Beam (Connects Base Center to Knob)
		// =========================================================================

		private function buildDynamicBeam():void {
			dynamicBeam = new Shape();
			addChild(dynamicBeam);
		}

		private function updateDynamicBeam(dx:Number, dy:Number, dist:Number):void {
			const g:Graphics = dynamicBeam.graphics;
			g.clear();

			if (dist < 4)
				return;

			const intensity:Number = Math.min(1.0, dist / LIMIT);

			// Outer luminous chord
			g.lineStyle(3.5, 0x0284c7, intensity * 0.35);
			g.moveTo(0, 0);
			g.lineTo(dx, dy);

			// Inner bright laser line
			g.lineStyle(1.5, 0x38bdf8, intensity * 0.75);
			g.moveTo(0, 0);
			g.lineTo(dx, dy);

			// Center anchor pulse dot
			g.beginFill(0x38bdf8, intensity * 0.6);
			g.drawCircle(0, 0, 3);
			g.endFill();
		}

		// =========================================================================
		// Knob / Thumb Handle Rendering
		// =========================================================================

		private function buildKnob():void {
			knob = new Sprite();
			knob.mouseChildren = false;
			knob.mouseEnabled = false;

			knobShadow = new Shape();
			knob.addChild(knobShadow);

			knobBody = new Shape();
			knob.addChild(knobBody);

			redrawKnob();

			knob.x = 0;
			knob.y = 0;

			addChild(knob);
		}

		private function redrawKnob():void {
			// 1. Soft Elevation Drop Shadow
			const gs:Graphics = knobShadow.graphics;
			gs.clear();

			const mSh:Matrix = new Matrix();
			mSh.createGradientBox((KNOB_RADIUS + 6) * 2, (KNOB_RADIUS + 6) * 2, 0, -(KNOB_RADIUS + 6), -(KNOB_RADIUS + 6) + 5);
			gs.beginGradientFill(
					GradientType.RADIAL,
					[0x000000, 0x000000],
					[isDragging ? 0.45 : 0.30, 0],
					[70, 255],
					mSh
				);
			gs.drawCircle(0, 5, KNOB_RADIUS + 6);
			gs.endFill();

			// 2. Knob Cap & Concentric Dish
			const g:Graphics = knobBody.graphics;
			g.clear();

			// Outer Beveled Rim Gradient
			const mRim:Matrix = new Matrix();
			mRim.createGradientBox(KNOB_RADIUS * 2, KNOB_RADIUS * 2, -Math.PI * 0.35, -KNOB_RADIUS, -KNOB_RADIUS);
			g.beginGradientFill(
					GradientType.LINEAR,
					[0x475569, 0x1e293b, 0x0f172a],
					[0.9, 0.95, 0.95],
					[0, 120, 255],
					mRim
				);
			g.drawCircle(0, 0, KNOB_RADIUS);
			g.endFill();

			// Outer glowing edge stroke
			const rimColor:uint = isDragging ? 0x67e8f9 : 0x38bdf8;
			const rimAlpha:Number = isDragging ? 0.85 : 0.50;
			g.lineStyle(1.6, rimColor, rimAlpha);
			g.drawCircle(0, 0, KNOB_RADIUS);

			// Ergonomic Concave Thumb Dish (Inner Depression)
			const dishRadius:Number = KNOB_RADIUS - 4;
			const mDish:Matrix = new Matrix();
			mDish.createGradientBox(dishRadius * 2, dishRadius * 2, 0, -dishRadius, -dishRadius);
			g.beginGradientFill(
					GradientType.RADIAL,
					[0x090d16, 0x1e293b],
					[0.95, 0.85],
					[40, 255],
					mDish
				);
			g.drawCircle(0, 0, dishRadius);
			g.endFill();

			// Tactile Concentric Micro-Grooves for Grip
			g.lineStyle(1.0, 0x38bdf8, 0.16);
			g.drawCircle(0, 0, 16);
			g.lineStyle(1.0, 0x38bdf8, 0.14);
			g.drawCircle(0, 0, 11);

			// Center Illuminated Core Pip
			const coreRadius:Number = 5.5;
			const mCore:Matrix = new Matrix();
			mCore.createGradientBox(coreRadius * 2, coreRadius * 2, 0, -coreRadius, -coreRadius);
			g.beginGradientFill(
					GradientType.RADIAL,
					isDragging ? [0xffffff, 0x38bdf8, 0x0284c7] : [0x7dd3fc, 0x0284c7, 0x0369a1],
					[1.0, 0.9, 0.7],
					[30, 140, 255],
					mCore
				);
			g.drawCircle(0, 0, coreRadius);
			g.endFill();

			// Center Core Border
			g.lineStyle(1.0, isDragging ? 0xffffff : 0x38bdf8, isDragging ? 0.9 : 0.6);
			g.drawCircle(0, 0, coreRadius);
		}

	}
}
