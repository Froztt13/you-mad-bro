package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;

	import ui.BaseModal;
	import ui.MyButton;
	import ui.MyTextField;
	import ui.UIUtils;
	import Utils;

	public class CustomCharUI extends BaseModal {

		private static const MODAL_W:Number = 360;
		private static const MODAL_H:Number = 356;
		private static const X_PAD:Number = 14;

		private var game:Object;

		// Input fields
		private var nameInput:MyTextField;
		private var guildInput:MyTextField;
		private var levelInput:MyTextField;
		private var colorInput:MyTextField;
		private var colorPreview:Shape;

		// Status display
		private var statusLabel:TextField;
		private var statusTimer:Timer;

		public function CustomCharUI(game:Object = null) {
			super(MODAL_W, MODAL_H, "Custom Char", "Visual modifier");
			this.game = game;

			buildUI();
			this.visible = false;
		}

		private function buildUI():void {
			var yPos:Number = 42;

			// --- 1. CHARACTER NAME ---
			var nameLbl:TextField = UIUtils.createLabel("CHARACTER NAME", UIUtils.TEXT_MUTED, 9.5, true);
			nameLbl.x = X_PAD;
			nameLbl.y = yPos;
			addChild(nameLbl);

			yPos += 16;
			nameInput = new MyTextField(248, 24, 11);
			nameInput.x = X_PAD;
			nameInput.y = yPos;
			addChild(nameInput);

			var nameBtn:MyButton = new MyButton("Apply", 78, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					applyName();
				});
			nameBtn.x = 268;
			nameBtn.y = yPos;
			addChild(nameBtn);

			yPos += 30;

			// --- 2. GUILD NAME ---
			var guildLbl:TextField = UIUtils.createLabel("GUILD NAME", UIUtils.TEXT_MUTED, 9.5, true);
			guildLbl.x = X_PAD;
			guildLbl.y = yPos;
			addChild(guildLbl);

			yPos += 16;
			guildInput = new MyTextField(248, 24, 11);
			guildInput.x = X_PAD;
			guildInput.y = yPos;
			addChild(guildInput);

			var guildBtn:MyButton = new MyButton("Apply", 78, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					applyGuild();
				});
			guildBtn.x = 268;
			guildBtn.y = yPos;
			addChild(guildBtn);

			yPos += 30;

			// --- 3. CHARACTER LEVEL ---
			var lvlLbl:TextField = UIUtils.createLabel("CHARACTER LEVEL", UIUtils.TEXT_MUTED, 9.5, true);
			lvlLbl.x = X_PAD;
			lvlLbl.y = yPos;
			addChild(lvlLbl);

			yPos += 16;
			levelInput = new MyTextField(90, 24, 11);
			levelInput.restrict = "0-9";
			levelInput.maxChars = 3;
			levelInput.x = X_PAD;
			levelInput.y = yPos;
			addChild(levelInput);

			var lvl100Btn:MyButton = new MyButton("Max 100", 68, 24, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					levelInput.text = "100";
					applyLevel();
				});
			lvl100Btn.x = 110;
			lvl100Btn.y = yPos;
			addChild(lvl100Btn);

			var lvl1Btn:MyButton = new MyButton("Lvl 1", 50, 24, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					levelInput.text = "1";
					applyLevel();
				});
			lvl1Btn.x = 184;
			lvl1Btn.y = yPos;
			addChild(lvl1Btn);

			var lvlBtn:MyButton = new MyButton("Apply", 78, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					applyLevel();
				});
			lvlBtn.x = 268;
			lvlBtn.y = yPos;
			addChild(lvlBtn);

			yPos += 30;

			// --- 4. ACCESS LEVEL (BADGE) ---
			var accLbl:TextField = UIUtils.createLabel("ACCESS LEVEL (BADGE / COLOR)", UIUtils.TEXT_MUTED, 9.5, true);
			accLbl.x = X_PAD;
			accLbl.y = yPos;
			addChild(accLbl);

			yPos += 16;
			const btnW:Number = 106;
			const btnH:Number = 22;

			// Row 1: Non Member, Member, Moderator
			var nonMemBtn:MyButton = new MyButton("Non-Member", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("Non Member");
					showStatus("Access Level: Non Member", 0xffffff);
				}, 10);
			nonMemBtn.x = X_PAD;
			nonMemBtn.y = yPos;
			addChild(nonMemBtn);

			var memBtn:MyButton = new MyButton("Member", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("Member");
					showStatus("Access Level: Member (Upgraded)", 0x8cd5ff);
				}, 10);
			memBtn.x = X_PAD + btnW + 6;
			memBtn.y = yPos;
			addChild(memBtn);

			var modBtn:MyButton = new MyButton("Mod (60)", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("Moderator");
					showStatus("Access Level: Moderator (Gold)", 0xfecb38);
				}, 10);
			modBtn.x = X_PAD + (btnW + 6) * 2;
			modBtn.y = yPos;
			addChild(modBtn);

			yPos += 26;

			// Row 2: 30 (Dark Green), 40 (Light Green), 50 (Purple)
			var acc30Btn:MyButton = new MyButton("Access 30", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("30");
					showStatus("Access Level: 30 (Dark Green)", 0x00ce91);
				}, 10);
			acc30Btn.x = X_PAD;
			acc30Btn.y = yPos;
			addChild(acc30Btn);

			var acc40Btn:MyButton = new MyButton("Access 40", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("40");
					showStatus("Access Level: 40 (Light Green)", 0x50ff28);
				}, 10);
			acc40Btn.x = X_PAD + btnW + 6;
			acc40Btn.y = yPos;
			addChild(acc40Btn);

			var acc50Btn:MyButton = new MyButton("Access 50", btnW, btnH, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					changeAccessLevel("50");
					showStatus("Access Level: 50 (Purple)", 0xbb6dff);
				}, 10);
			acc50Btn.x = X_PAD + (btnW + 6) * 2;
			acc50Btn.y = yPos;
			addChild(acc50Btn);

			yPos += 30;

			// --- 5. NAME COLOR ---
			var colLbl:TextField = UIUtils.createLabel("NAME COLOR (HEX / PALETTE)", UIUtils.TEXT_MUTED, 9.5, true);
			colLbl.x = X_PAD;
			colLbl.y = yPos;
			addChild(colLbl);

			yPos += 16;
			colorInput = new MyTextField(68, 24, 11);
			colorInput.maxChars = 8;
			colorInput.text = "FFFFFF";
			colorInput.x = X_PAD;
			colorInput.y = yPos;
			colorInput.addEventListener(Event.CHANGE, onColorInputChange);
			colorInput.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
					if (e.keyCode == 13) {
						applyColor();
					}
				});
			addChild(colorInput);

			colorPreview = new Shape();
			colorPreview.x = 86;
			colorPreview.y = yPos;
			updateColorPreview(0xffffff);
			addChild(colorPreview);

			// Palette swatches
			const palette:Array = [
					0xffffff, // White
					0x8cd5ff, // Member Blue
					0xfecb38, // Mod Gold
					0xff3b30, // Red
					0x22c55e, // Green
					0x50ff28, // Light Green
					0x00ce91, // Teal
					0xbb6dff, // Purple
					0xff9500, // Orange
					0xff2d55 // Pink
				];

			var swatchX:Number = 118;
			for (var i:int = 0; i < palette.length; i++) {
				var sw:Sprite = createColorSwatch(swatchX + (i * 22), yPos + 3, 18, palette[i]);
				addChild(sw);
			}

			// --- Divider & Bottom Section ---
			yPos += 34;
			addDivider(yPos);

			yPos += 10;
			var grabBtn:MyButton = new MyButton("Grab Current", 110, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					grabCurrentData();
					showStatus("Grabbed current character stats", 0x38bdf8);
				});
			grabBtn.x = X_PAD;
			grabBtn.y = yPos;
			addChild(grabBtn);

			statusLabel = UIUtils.createLabel("", UIUtils.TEXT_MAIN, 10, true, TextFormatAlign.LEFT);
			statusLabel.x = X_PAD + 118;
			statusLabel.y = yPos + 5;
			statusLabel.width = MODAL_W - X_PAD - 118 - X_PAD;
			addChild(statusLabel);
		}

		private function createColorSwatch(xPos:Number, yPos:Number, size:Number, color:uint):Sprite {
			var s:Sprite = new Sprite();
			s.x = xPos;
			s.y = yPos;
			s.buttonMode = true;
			s.useHandCursor = true;

			s.graphics.beginFill(color, 1.0);
			s.graphics.lineStyle(1, 0x334155, 1.0);
			s.graphics.drawRoundRect(0, 0, size, size, 3);
			s.graphics.endFill();

			s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					var hex:String = color.toString(16).toUpperCase();
					while (hex.length < 6) {
						hex = "0" + hex;
					}
					colorInput.text = hex;
					updateColorPreview(color);
					changeColorName(int(color));
					showStatus("Color applied: #" + hex, color);
				});
			return s;
		}

		private function updateColorPreview(color:uint):void {
			colorPreview.graphics.clear();
			colorPreview.graphics.beginFill(color, 1.0);
			colorPreview.graphics.lineStyle(1, UIUtils.BORDER_NORMAL, 1.0);
			colorPreview.graphics.drawRoundRect(0, 0, 24, 24, 4);
			colorPreview.graphics.endFill();
		}

		private function onColorInputChange(e:Event):void {
			var c:int = parseColor(colorInput.trimmedText);
			if (c >= 0) {
				updateColorPreview(uint(c));
				var hexOnly:String = colorInput.trimmedText.replace("#", "").replace("0x", "").replace("0X", "");
				if (hexOnly.length == 6) {
					changeColorName(c);
					showStatus("Color applied: #" + hexOnly.toUpperCase(), uint(c));
				}
			}
		}

		private function parseColor(str:String):int {
			if (str == null || str.length == 0)
				return -1;
			var cleaned:String = Utils.trim(str);
			if (cleaned.indexOf("#") == 0) {
				cleaned = cleaned.substr(1);
			}
			else if (cleaned.indexOf("0x") == 0 || cleaned.indexOf("0X") == 0) {
				cleaned = cleaned.substr(2);
			}
			if (cleaned.length == 0)
				return -1;
			var val:Number = parseInt(cleaned, 16);
			if (isNaN(val)) {
				val = parseInt(str, 10);
			}
			return isNaN(val) ? -1 : int(val);
		}

		// --- Core Actions ---

		private function applyName():void {
			var n:String = nameInput.trimmedText;
			if (n.length == 0) {
				showStatus("Please enter a character name.", 0xf87171);
				return;
			}
			changeName(n);
			showStatus("Name updated to: " + n.toUpperCase(), 0x4ade80);
		}

		private function applyGuild():void {
			var g:String = guildInput.trimmedText;
			changeGuild(g);
			showStatus("Guild updated to: " + (g.length > 0 ? g.toUpperCase() : "<None>"), 0x4ade80);
		}

		private function applyLevel():void {
			var lvlStr:String = levelInput.trimmedText;
			var lvl:int = parseInt(lvlStr);
			if (isNaN(lvl) || lvl <= 0) {
				showStatus("Please enter a valid level.", 0xf87171);
				return;
			}
			changeLevel(lvl);
			showStatus("Level updated to: " + lvl, 0x4ade80);
		}

		private function applyColor():void {
			var c:int = parseColor(colorInput.trimmedText);
			if (c < 0) {
				showStatus("Invalid color hex format.", 0xf87171);
				return;
			}
			changeColorName(c);
			showStatus("Name color updated.", uint(c));
		}

		public function grabCurrentData():void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				var myAvatar:* = game.world.myAvatar;
				if (myAvatar.objData != null) {
					if (myAvatar.objData.strUsername != null) {
						nameInput.text = myAvatar.objData.strUsername;
					}
					if (myAvatar.objData.guild != null && myAvatar.objData.guild.Name != null) {
						guildInput.text = myAvatar.objData.guild.Name;
					}
					if (myAvatar.objData.intLevel != null) {
						levelInput.text = String(myAvatar.objData.intLevel);
					}
				}

				if (myAvatar.pMC != null && myAvatar.pMC.pname != null && myAvatar.pMC.pname.ti != null) {
					var col:uint = uint(myAvatar.pMC.pname.ti.textColor);
					var hex:String = col.toString(16).toUpperCase();
					while (hex.length < 6) {
						hex = "0" + hex;
					}
					colorInput.text = hex;
					updateColorPreview(col);
				}
			}
			catch (err:Error) {
			}
		}

		// --- Functions matching references/commands/Player.as ---

		public function ChangeName(name:String):void {
			changeName(name);
		}

		public function changeName(name:String):void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				var upperName:String = name.toUpperCase();
				if (game.world.myAvatar.pMC != null && game.world.myAvatar.pMC.pname != null && game.world.myAvatar.pMC.pname.ti != null) {
					game.world.myAvatar.pMC.pname.ti.text = upperName;
				}
				if (game.ui != null && game.ui.mcPortrait != null && game.ui.mcPortrait.strName != null) {
					game.ui.mcPortrait.strName.text = upperName;
				}
				game.world.myAvatar.objData.strUsername = upperName;
				if (game.world.myAvatar.pMC != null && game.world.myAvatar.pMC.pAV != null && game.world.myAvatar.pMC.pAV.objData != null) {
					game.world.myAvatar.pMC.pAV.objData.strUsername = upperName;
				}
				if (game.world.updatePortrait != null) {
					game.world.updatePortrait(game.world.myAvatar);
				}
			}
			catch (e:Error) {
			}
		}

		public function ChangeGuild(guild:String):void {
			changeGuild(guild);
		}

		public function changeGuild(guild:String):void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				var upperGuild:String = guild.toUpperCase();
				if (game.world.myAvatar.objData.guild != null) {
					game.world.myAvatar.objData.guild.Name = upperGuild;
				}
				else {
					game.world.myAvatar.objData.guild = {Name: upperGuild};
				}

				if (game.world.myAvatar.pMC != null && game.world.myAvatar.pMC.pname != null && game.world.myAvatar.pMC.pname.tg != null) {
					game.world.myAvatar.pMC.pname.tg.text = upperGuild;
				}

				if (game.world.myAvatar.pMC != null && game.world.myAvatar.pMC.pAV != null && game.world.myAvatar.pMC.pAV.objData != null) {
					if (game.world.myAvatar.pMC.pAV.objData.guild != null) {
						game.world.myAvatar.pMC.pAV.objData.guild.Name = upperGuild;
					}
					else {
						game.world.myAvatar.pMC.pAV.objData.guild = {Name: upperGuild};
					}
				}
			}
			catch (e:Error) {
			}
		}

		public function ChangeAccessLevel(accessLevel:String):void {
			changeAccessLevel(accessLevel);
		}

		public function changeAccessLevel(accessLevel:String):void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				var pMC:* = game.world.myAvatar.pMC;
				var objData:* = game.world.myAvatar.objData;
				var glow:GlowFilter = new GlowFilter(0, 1, 3, 3, 64, 1);

				if (accessLevel == "Non Member" || accessLevel == "0") {
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 16777215;
						pMC.pname.filters = [glow];
					}
					objData.iUpgDays = -1;
					objData.iUpg = 0;
					objData.intAccessLevel = 0;
				}
				else if (accessLevel == "Member" || accessLevel == "1") {
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 9229823;
						pMC.pname.filters = [glow];
					}
					objData.iUpgDays = 30;
					objData.iUpg = 1;
					objData.intAccessLevel = 1;
				}
				else if (accessLevel == "Moderator" || accessLevel == "60") {
					// Yellow
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 16698168;
						pMC.pname.filters = [glow];
					}
					objData.intAccessLevel = 60;
				}
				else if (accessLevel == "30") {
					// Dark Green
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 52881;
						pMC.pname.filters = [glow];
					}
					objData.intAccessLevel = 30;
				}
				else if (accessLevel == "40") {
					// Light Green
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 5308200;
						pMC.pname.filters = [glow];
					}
					objData.intAccessLevel = 40;
				}
				else if (accessLevel == "50") {
					// Purple
					if (pMC != null && pMC.pname != null && pMC.pname.ti != null) {
						pMC.pname.ti.textColor = 12283391;
						pMC.pname.filters = [glow];
					}
					objData.intAccessLevel = 50;
				}
			}
			catch (e:Error) {
			}
		}

		public function ChangeColorName(color:int):void {
			changeColorName(color);
		}

		public function changeColorName(color:int):void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				if (game.world.myAvatar.pMC != null && game.world.myAvatar.pMC.pname != null && game.world.myAvatar.pMC.pname.ti != null) {
					game.world.myAvatar.pMC.pname.ti.textColor = color;
				}
			}
			catch (e:Error) {
			}
		}

		public function ChangeLevel(level:int):void {
			changeLevel(level);
		}

		public function changeLevel(level:int):void {
			if (game == null || game.world == null || game.world.myAvatar == null) {
				return;
			}
			try {
				game.world.myAvatar.objData.intLevel = level;
				if (game.world.myAvatar.dataLeaf != null) {
					game.world.myAvatar.dataLeaf.intLevel = level;
				}
				if (game.ui != null && game.ui.mcPortrait != null && game.ui.mcPortrait.strLevel != null) {
					game.ui.mcPortrait.strLevel.text = String(level);
				}
				if (game.world.updatePortrait != null) {
					game.world.updatePortrait(game.world.myAvatar);
				}
			}
			catch (e:Error) {
			}
		}

		public function toggle():void {
			this.visible = !this.visible;
			if (this.visible) {
				grabCurrentData();
				centerOnStage();
				if (parent != null) {
					parent.setChildIndex(this, parent.numChildren - 1);
				}
			}
		}

		private function showStatus(msg:String, color:uint):void {
			if (statusLabel != null) {
				statusLabel.text = msg;
				statusLabel.textColor = color;

				if (statusTimer != null) {
					statusTimer.stop();
				}
				statusTimer = new Timer(3000, 1);
				statusTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
						if (statusLabel != null) {
							statusLabel.text = "";
						}
					});
				statusTimer.start();
			}
		}
	}
}
