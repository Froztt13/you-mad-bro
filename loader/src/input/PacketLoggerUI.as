package input {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.system.System;
	import flash.text.*;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	import ui.CloseButton;
	import ui.MyButton;
	import ui.MyTextField;

	public class PacketLoggerUI extends Sprite {

		public static const UI_WIDTH:Number = 500;
		public static const UI_HEIGHT:Number = 405;
		private static const PADDING:Number = 12;
		private static const HEADER_HEIGHT:Number = 36;
		private static const ITEM_HEIGHT:Number = 22;
		private static const ITEM_SPACING:Number = 2;
		private static const SCROLLBAR_WIDTH:Number = 8;
		private static const LIST_Y:Number = 44;
		private static const LIST_HEIGHT:Number = 276;

		public static var instance:PacketLoggerUI;

		private var game:Object;

		private var modalBg:Shape;
		private var listContainer:Sprite;
		private var scrollContent:Sprite;
		private var emptyLabel:TextField;
		private var scrollbar:Sprite;
		private var scrollThumb:Sprite;
		private var isDragging:Boolean = false;
		private var dragStartY:Number = 0;
		private var thumbStartY:Number = 0;
		private var scrollY:Number = 0;
		private var maxScrollY:Number = 0;
		private var thumbHeight:Number = 30;

		private var clientBtn:Sprite;
		private var serverBtn:Sprite;
		private var showClient:Boolean = false;
		private var showServer:Boolean = false;

		private var packets:Array = [];
		private static var pendingLogs:Array = [];

		// Send Packet Controls
		private var sendContainer:Sprite;
		private var packetInput:MyTextField;
		private var sendBtn:MyButton;
		private var sendStatusTf:TextField;
		private var serverRadioBtn:Sprite;
		private var clientRadioBtn:Sprite;
		private var serverRadioDot:Shape;
		private var clientRadioDot:Shape;
		private var serverRadioLabel:TextField;
		private var clientRadioLabel:TextField;
		private var qtyContainer:Sprite;
		private var qtyInput:MyTextField;
		private var sendTarget:String = "server"; // "server" or "client"
		private var statusResetTimer:Timer;
		private var sendTimer:Timer;
		private var isSendingMulti:Boolean = false;

		public function PacketLoggerUI(game:Object = null) {
			instance = this;
			this.game = game;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		public function setGame(game:Object):void {
			this.game = game;
		}

		private function getGame():Object {
			if (game != null)
				return game;
			if (MainMenuUI.instance != null && MainMenuUI.instance.getGame() != null)
				return MainMenuUI.instance.getGame();
			return null;
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			buildUI();
			if (pendingLogs.length > 0) {
				for each (var p:Object in pendingLogs) {
					packets.push(p);
				}
				pendingLogs = [];
				refresh();
			}
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
			this.addEventListener(MouseEvent.MOUSE_DOWN, onPanelMouseDown);

			// Header Bar (Draggable)
			const headerBar:Sprite = new Sprite();
			headerBar.graphics.beginFill(0x0a0e1a, 0.98);
			headerBar.graphics.drawRoundRectComplex(0, 0, UI_WIDTH, HEADER_HEIGHT, 8, 8, 0, 0);
			headerBar.graphics.endFill();
			headerBar.graphics.lineStyle(1, 0x1e293b, 1);
			headerBar.graphics.moveTo(0, HEADER_HEIGHT);
			headerBar.graphics.lineTo(UI_WIDTH, HEADER_HEIGHT);
			addChild(headerBar);

			headerBar.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					startDrag();
					stage.addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
				});

			const titleTf:TextField = createLabel("Packet Logger", 0xf8fafc, 12, true);
			titleTf.x = PADDING;
			titleTf.y = 9;
			titleTf.width = 90;
			headerBar.addChild(titleTf);

			// Filter Buttons in Header
			clientBtn = createToggleButton("Client", 108, 7, 52, 22, 0x0284c7, 0x0369a1, 0x38bdf8, function(val:Boolean):void {
					showClient = val;
				}, false);
			headerBar.addChild(clientBtn);

			serverBtn = createToggleButton("Server", 166, 7, 54, 22, 0x059669, 0x047857, 0x34d399, function(val:Boolean):void {
					showServer = val;
				}, false);
			headerBar.addChild(serverBtn);

			// Clear Button
			const clearBtn:Sprite = createHeaderButton("Clear", 46, 22);
			clearBtn.x = UI_WIDTH - PADDING - 22 - 6 - 46; // 414
			clearBtn.y = 7;
			clearBtn.addEventListener(MouseEvent.CLICK, onClearClick);
			headerBar.addChild(clearBtn);

			// Close Button
			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = UI_WIDTH - PADDING - 22;
			closeBtn.y = 7;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					if (sendTimer != null && sendTimer.running) {
						sendTimer.stop();
					}
					isSendingMulti = false;
					visible = false;
				});
			headerBar.addChild(closeBtn);

			// Recessed Log Container Box
			const listBox:Shape = new Shape();
			drawRoundedRect(listBox.graphics, PADDING, LIST_Y, UI_WIDTH - PADDING * 2, LIST_HEIGHT, 6, 0x070b14, 0.95, 0x1e293b, 1);
			addChild(listBox);

			listContainer = new Sprite();
			listContainer.x = PADDING + 6;
			listContainer.y = LIST_Y + 6;
			addChild(listContainer);

			const listContentWidth:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4;
			const listContentHeight:Number = LIST_HEIGHT - 12;

			// Mask
			const mask:Shape = new Shape();
			mask.graphics.beginFill(0x000000);
			mask.graphics.drawRect(0, 0, listContentWidth, listContentHeight);
			mask.graphics.endFill();
			listContainer.addChild(mask);

			// Scroll content
			scrollContent = new Sprite();
			scrollContent.mask = mask;
			listContainer.addChild(scrollContent);

			// Empty label
			emptyLabel = createLabel("No packets captured yet.\nEnable 'Client' or 'Server' above to start logging.", 0x64748b, 10.5, false, TextFormatAlign.CENTER);
			emptyLabel.x = PADDING;
			emptyLabel.y = LIST_Y + int(LIST_HEIGHT / 2) - 16;
			emptyLabel.width = UI_WIDTH - PADDING * 2;
			emptyLabel.height = 40;
			emptyLabel.multiline = true;
			emptyLabel.wordWrap = true;
			addChild(emptyLabel);

			// Scrollbar
			scrollbar = new Sprite();
			scrollbar.x = UI_WIDTH - PADDING - 6 - SCROLLBAR_WIDTH;
			scrollbar.y = LIST_Y + 6;
			scrollbar.visible = false;
			addChild(scrollbar);

			const trackBg:Shape = new Shape();
			drawRoundedRect(trackBg.graphics, 0, 0, SCROLLBAR_WIDTH, listContentHeight, 4, 0x070b14, 0.5);
			scrollbar.addChild(trackBg);

			scrollThumb = new Sprite();
			const thumbBg:Shape = new Shape();
			drawRoundedRect(thumbBg.graphics, 0, 0, SCROLLBAR_WIDTH, 30, 4, 0x334155, 0.9);
			scrollThumb.addChild(thumbBg);
			scrollThumb.buttonMode = true;
			scrollThumb.useHandCursor = true;
			scrollbar.addChild(scrollThumb);

			scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
			scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver);
			scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut);

			// Divider line above send section
			const divider:Shape = new Shape();
			divider.graphics.lineStyle(1, 0x1e293b, 1);
			divider.graphics.moveTo(PADDING, 328);
			divider.graphics.lineTo(UI_WIDTH - PADDING, 328);
			addChild(divider);

			// Build Send Section
			buildSendSection();
		}

		private function buildSendSection():void {
			sendContainer = new Sprite();
			sendContainer.x = PADDING;
			sendContainer.y = 336;
			addChild(sendContainer);

			// Row 1: Header + Radio buttons + Qty + Status
			const label:TextField = createLabel("SEND TO:", 0x64748b, 9.5, true);
			label.x = 0;
			label.y = 1;
			label.width = 58;
			sendContainer.addChild(label);

			// Radio 1: Server
			serverRadioBtn = new Sprite();
			serverRadioBtn.x = 64;
			serverRadioBtn.y = 1;
			serverRadioBtn.buttonMode = true;
			serverRadioBtn.useHandCursor = true;

			const sOuterCircle:Shape = new Shape();
			drawCircle(sOuterCircle.graphics, 7, 7, 6.5, 0x1e293b, 1.0, 0x475569, 1.5);
			serverRadioBtn.addChild(sOuterCircle);

			serverRadioDot = new Shape();
			drawCircle(serverRadioDot.graphics, 7, 7, 3.5, 0x4ade80, 1.0);
			serverRadioBtn.addChild(serverRadioDot);

			serverRadioLabel = createLabel("Server", 0xf8fafc, 10.5, true);
			serverRadioLabel.x = 18;
			serverRadioLabel.y = -1;
			serverRadioBtn.addChild(serverRadioLabel);

			serverRadioBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					setSendTarget("server");
				});
			sendContainer.addChild(serverRadioBtn);

			// Radio 2: Client
			clientRadioBtn = new Sprite();
			clientRadioBtn.x = 132;
			clientRadioBtn.y = 1;
			clientRadioBtn.buttonMode = true;
			clientRadioBtn.useHandCursor = true;

			const cOuterCircle:Shape = new Shape();
			drawCircle(cOuterCircle.graphics, 7, 7, 6.5, 0x1e293b, 1.0, 0x475569, 1.5);
			clientRadioBtn.addChild(cOuterCircle);

			clientRadioDot = new Shape();
			drawCircle(clientRadioDot.graphics, 7, 7, 3.5, 0x38bdf8, 1.0);
			clientRadioDot.visible = false;
			clientRadioBtn.addChild(clientRadioDot);

			clientRadioLabel = createLabel("Client", 0x94a3b8, 10.5, false);
			clientRadioLabel.x = 18;
			clientRadioLabel.y = -1;
			clientRadioBtn.addChild(clientRadioLabel);

			clientRadioBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					setSendTarget("client");
				});
			sendContainer.addChild(clientRadioBtn);

			// Qty Container (for Server)
			qtyContainer = new Sprite();
			qtyContainer.x = 202;
			qtyContainer.y = 0;

			const qtyLbl:TextField = createLabel("Qty:", 0x64748b, 9.5, true);
			qtyLbl.x = 0;
			qtyLbl.y = 1;
			qtyLbl.width = 24;
			qtyContainer.addChild(qtyLbl);

			qtyInput = new MyTextField(34, 20, 10, TextFormatAlign.CENTER, true);
			qtyInput.x = 26;
			qtyInput.y = 0;
			qtyInput.text = "1";
			qtyInput.restrict = "0-9";
			qtyInput.maxChars = 4;
			qtyContainer.addChild(qtyInput);

			sendContainer.addChild(qtyContainer);

			// Status / Hint label
			sendStatusTf = createLabel("Press Enter to send", 0x475569, 8.5, false, TextFormatAlign.RIGHT);
			sendStatusTf.x = 270;
			sendStatusTf.y = 2;
			sendStatusTf.width = UI_WIDTH - PADDING * 2 - 270;
			sendContainer.addChild(sendStatusTf);

			// Row 2: Input Field + Send Button
			const inputHeight:Number = 26;
			const inputWidth:Number = UI_WIDTH - PADDING * 2 - 72; // 404

			packetInput = new MyTextField(inputWidth, inputHeight, 11);
			packetInput.x = 0;
			packetInput.y = 24;
			packetInput.maxChars = 2048;
			packetInput.addEventListener(KeyboardEvent.KEY_DOWN, onPacketInputKeyDown, false, 0, true);
			packetInput.addEventListener(Event.CHANGE, onPacketInputChange, false, 0, true);
			sendContainer.addChild(packetInput);

			sendBtn = new MyButton("Send", 64, inputHeight, MyButton.TYPE_PRIMARY, onSendClick);
			sendBtn.x = inputWidth + 8;
			sendBtn.y = 24;
			sendContainer.addChild(sendBtn);
		}

		private function setSendTarget(target:String):void {
			sendTarget = target;
			if (sendTarget == "server") {
				serverRadioDot.visible = true;
				serverRadioLabel.textColor = 0xf8fafc;
				clientRadioDot.visible = false;
				clientRadioLabel.textColor = 0x94a3b8;
				if (qtyContainer != null) {
					qtyContainer.visible = true;
				}
			}
			else {
				serverRadioDot.visible = false;
				serverRadioLabel.textColor = 0x94a3b8;
				clientRadioDot.visible = true;
				clientRadioLabel.textColor = 0xf8fafc;
				if (qtyContainer != null) {
					qtyContainer.visible = false;
				}
			}
		}

		private function onPacketInputChange(e:Event):void {
			if (packetInput == null)
				return;
			var txt:String = Utils.trim(packetInput.text);
			if (txt.length >= 4) {
				if (txt.indexOf("%xt%") == 0) {
					setSendTarget("server");
				}
				else if (txt.charAt(0) == "{" || txt.charAt(0) == "<") {
					setSendTarget("client");
				}
			}
		}

		private function isXtPacket(packet:String):Boolean {
			if (packet == null)
				return false;
			var str:String = Utils.trim(packet);
			return str.indexOf("%xt%") == 0;
		}

		private function onSendClick(e:MouseEvent):void {
			sendPacketFromInput();
		}

		private function onPacketInputKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				sendPacketFromInput();
				e.preventDefault();
			}
		}

		private function sendPacketFromInput():void {
			if (packetInput == null)
				return;
			var raw:String = packetInput.text;
			if (raw == null)
				return;
			raw = Utils.trim(raw);
			if (raw.length == 0)
				return;

			if (sendTarget == "server") {
				if (!isXtPacket(raw)) {
					flashStatus("Server only accepts %xt%...% packets", 0xef4444);
					packets.push({msg: "[Validation Error]: Only %xt%...% packets can be sent to Server. Other packets must be sent to Client.", isClient: true, type: "client", time: new Date().toTimeString().substr(0, 8)});
					refresh();
					return;
				}
				if (raw.charAt(raw.length - 1) != "%") {
					raw += "%";
					packetInput.text = raw;
				}
				sendPacketToServer(raw);
			}
			else {
				sendPacketToClient(raw);
			}
		}

		private function sendPacketToServer(packet:String):void {
			var g:Object = getGame();
			if (g == null || g.sfc == null) {
				packets.push({msg: "[Error]: Game not connected or SFC unavailable.", isClient: true, type: "client", time: new Date().toTimeString().substr(0, 8)});
				refresh();
				flashStatus("Error: Not connected", 0xef4444);
				return;
			}

			var qty:int = (qtyInput != null) ? int(qtyInput.text) : 1;
			if (qty <= 0)
				qty = 1;
			if (qty > 500)
				qty = 500;

			if (qty == 1) {
				try {
					if (g.sfc.sendString != null) {
						g.sfc.sendString(packet);
						flashStatus("Sent to Server", 0x4ade80);
					}
					else {
						flashStatus("Error: sendString unavailable", 0xef4444);
					}
				}
				catch (e:Error) {
					packets.push({msg: "[Server Send Error]: " + e.message, isClient: true, type: "client", time: new Date().toTimeString().substr(0, 8)});
					refresh();
					flashStatus("Error: " + e.message, 0xef4444);
				}
				return;
			}

			// Multi-packet send with 1 second delay between packets
			if (isSendingMulti)
				return;

			isSendingMulti = true;
			sendBtn.enabled = false;
			var currentCount:int = 1;

			// Send the first packet immediately
			try {
				g.sfc.sendString(packet);
			}
			catch (err:Error) {
			}
			if (sendBtn != null) {
				sendBtn.label = "1/" + qty;
			}
			if (sendStatusTf != null) {
				sendStatusTf.text = "Sending 1/" + qty + "...";
				sendStatusTf.textColor = 0x38bdf8;
			}

			if (sendTimer != null) {
				sendTimer.stop();
			}

			sendTimer = new Timer(1000, qty - 1);
			sendTimer.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void {
					currentCount++;
					try {
						g.sfc.sendString(packet);
					}
					catch (err:Error) {
					}
					if (sendBtn != null) {
						sendBtn.label = currentCount + "/" + qty;
					}
					if (sendStatusTf != null) {
						sendStatusTf.text = "Sending " + currentCount + "/" + qty + "...";
						sendStatusTf.textColor = 0x38bdf8;
					}
				});

			sendTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent):void {
					isSendingMulti = false;
					if (sendBtn != null) {
						sendBtn.enabled = true;
						sendBtn.label = "Done";
					}
					flashStatus("Sent " + qty + " packets to Server", 0x4ade80);
				});

			sendTimer.start();
		}

		private function sendPacketToClient(packet:String):void {
			var g:Object = getGame();
			if (g == null || g.sfc == null) {
				packets.push({msg: "[Error]: Game not connected or SFC unavailable.", isClient: false, type: "server", time: new Date().toTimeString().substr(0, 8)});
				refresh();
				flashStatus("Error: Not connected", 0xef4444);
				return;
			}

			try {
				if ("handleMessage" in g.sfc) {
					g.sfc.handleMessage(packet);
					flashStatus("Injected to Client", 0x38bdf8);
				}
				else {
					g.sfc["handleMessage"](packet);
					flashStatus("Injected to Client", 0x38bdf8);
				}
			}
			catch (e:Error) {
				packets.push({msg: "[Client Inject Error]: " + e.message, isClient: false, type: "server", time: new Date().toTimeString().substr(0, 8)});
				refresh();
				flashStatus("Error: " + e.message, 0xef4444);
			}
		}

		private function flashStatus(msg:String, color:uint):void {
			if (sendBtn != null) {
				sendBtn.label = "Sent!";
			}
			if (sendStatusTf != null) {
				sendStatusTf.text = msg;
				sendStatusTf.textColor = color;
			}
			if (statusResetTimer != null) {
				statusResetTimer.stop();
			}
			statusResetTimer = new Timer(1200, 1);
			statusResetTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
					if (sendBtn != null) {
						sendBtn.label = "Send";
					}
					if (sendStatusTf != null) {
						sendStatusTf.text = "Press Enter to send";
						sendStatusTf.textColor = 0x475569;
					}
				});
			statusResetTimer.start();
		}

		private function createToggleButton(
				label:String,
				px:Number,
				py:Number,
				w:Number,
				h:Number,
				activeBg:uint,
				activeBorder:uint,
				activeText:uint,
				callback:Function,
				defaultActive:Boolean = false
			):Sprite {
			const btn:Sprite = new Sprite();
			btn.x = px;
			btn.y = py;
			btn.buttonMode = true;
			btn.useHandCursor = true;

			var active:Boolean = defaultActive;

			const bg:Shape = new Shape();
			if (active) {
				drawRoundedRect(bg.graphics, 0, 0, w, h, 4, activeBg, 1.0, activeBorder, 1);
			}
			else {
				drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
			}
			btn.addChild(bg);

			const tf:TextField = createLabel(label, active ? 0xffffff : 0x94a3b8, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 14) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					active = !active;
					if (active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, activeBg, 1.0, activeBorder, 1);
						tf.textColor = 0xffffff;
					}
					else {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
						tf.textColor = 0x94a3b8;
					}
					callback(active);
				});

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					if (!active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x475569, 1);
						tf.textColor = 0xffffff;
					}
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					if (!active) {
						drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
						tf.textColor = 0x94a3b8;
					}
				});

			return btn;
		}

		private function createHeaderButton(label:String, w:Number, h:Number):Sprite {
			const btn:Sprite = new Sprite();
			btn.buttonMode = true;
			btn.useHandCursor = true;

			const bg:Shape = new Shape();
			drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
			btn.addChild(bg);

			const tf:TextField = createLabel(label, 0x94a3b8, 9.5, true, TextFormatAlign.CENTER);
			tf.width = w;
			tf.height = h;
			tf.y = int((h - 14) / 2);
			btn.addChild(tf);

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x334155, 1.0, 0x475569, 1);
					tf.textColor = 0xffffff;
				});

			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
					drawRoundedRect(bg.graphics, 0, 0, w, h, 4, 0x1e293b, 1.0, 0x334155, 1);
					tf.textColor = 0x94a3b8;
				});

			return btn;
		}

		public function logPacket(msg:String, isClient:Boolean):void {
			if (isClient && !showClient)
				return;
			if (!isClient && !showServer)
				return;

			packets.push({msg: msg, isClient: isClient, type: isClient ? "client" : "server", time: new Date().toTimeString().substr(0, 8)});
			if (packets.length > 100)
				packets.shift();
			refresh();
		}

		public function logBot(msg:String):void {
			AppLogUI.bot(msg);
		}

		public static function logBot(msg:String):void {
			AppLogUI.bot(msg);
		}

		private function refresh():void {
			while (scrollContent.numChildren > 0)
				scrollContent.removeChildAt(0);

			emptyLabel.visible = (packets.length == 0);

			const listContentWidth:Number = UI_WIDTH - PADDING * 2 - 12 - SCROLLBAR_WIDTH - 4;
			const listContentHeight:Number = LIST_HEIGHT - 12;
			const totalHeight:Number = packets.length * (ITEM_HEIGHT + ITEM_SPACING);

			for (var i:int = 0; i < packets.length; i++) {
				const p:Object = packets[i];
				const itemY:Number = i * (ITEM_HEIGHT + ITEM_SPACING);

				const item:Sprite = new Sprite();
				item.y = itemY;

				const itemBg:Shape = new Shape();
				drawRoundedRect(itemBg.graphics, 0, 0, listContentWidth, ITEM_HEIGHT, 3, 0x0f172a, 0.6, 0x1e293b, 1);
				item.addChild(itemBg);

				// Direction Badge
				var badgeColor:uint = 0x059669;
				var badgeTextColor:uint = 0x4ade80;
				var badgeText:String = "SRV";
				var textColor:uint = 0x86efac;

				if (p.isClient || p.type == "client") {
					badgeColor = 0x0284c7;
					badgeTextColor = 0x38bdf8;
					badgeText = "CLI";
					textColor = 0x7dd3fc;
				}

				const badge:Sprite = new Sprite();
				const badgeBg:Shape = new Shape();
				drawRoundedRect(badgeBg.graphics, 0, 0, 26, 16, 3, badgeColor, 0.35, badgeColor, 1);
				badge.addChild(badgeBg);
				const badgeTf:TextField = createLabel(badgeText, badgeTextColor, 8.5, true, TextFormatAlign.CENTER);
				badgeTf.width = 26;
				badgeTf.height = 16;
				badgeTf.y = 1;
				badge.addChild(badgeTf);
				badge.x = 4;
				badge.y = 3;
				item.addChild(badge);

				// Timestamp + Packet content
				const labelText:String = "[" + p.time + "] " + p.msg;
				const label:TextField = createLabel(labelText, textColor, 9.5, false);
				label.width = listContentWidth - 36 - 44;
				label.height = ITEM_HEIGHT;
				label.x = 34;
				label.y = 3;
				item.addChild(label);

				// Copy Button
				const copyBtn:Sprite = new Sprite();
				copyBtn.buttonMode = true;
				copyBtn.useHandCursor = true;

				const copyBg:Shape = new Shape();
				drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x1e293b, 1.0, 0x334155, 1);
				copyBtn.addChild(copyBg);

				const copyTf:TextField = createLabel("Copy", 0x94a3b8, 8.5, true, TextFormatAlign.CENTER);
				copyTf.width = 36;
				copyTf.height = 16;
				copyTf.y = 1;
				copyBtn.addChild(copyTf);

				copyBtn.x = listContentWidth - 40;
				copyBtn.y = 3;

				copyBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x334155, 1.0, 0x475569, 1);
						copyTf.textColor = 0xffffff;
					});

				copyBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						drawRoundedRect(copyBg.graphics, 0, 0, 36, 16, 3, 0x1e293b, 1.0, 0x334155, 1);
						copyTf.textColor = 0x94a3b8;
					});

				copyBtn.addEventListener(MouseEvent.CLICK, createCopyHandler(p.msg, copyTf));
				item.addChild(copyBtn);

				scrollContent.addChild(item);
			}

			if (totalHeight > listContentHeight) {
				maxScrollY = totalHeight - listContentHeight;
				thumbHeight = Math.max(24, (listContentHeight / totalHeight) * listContentHeight);

				const tBg:Shape = Shape(scrollThumb.getChildAt(0));
				drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);

				scrollbar.visible = true;
				scrollY = maxScrollY; // Auto-scroll to latest
			}
			else {
				scrollbar.visible = false;
				scrollY = 0;
				maxScrollY = 0;
			}
			updateScrollPosition();
		}

		private function updateScrollPosition():void {
			scrollContent.y = -scrollY;
			if (maxScrollY > 0) {
				const listContentHeight:Number = LIST_HEIGHT - 12;
				const maxThumbY:Number = listContentHeight - thumbHeight;
				scrollThumb.y = (scrollY / maxScrollY) * maxThumbY;
			}
		}

		private function onThumbMouseDown(e:MouseEvent):void {
			isDragging = true;
			dragStartY = e.stageY;
			thumbStartY = scrollThumb.y;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			e.stopImmediatePropagation();
		}

		private function onStageMouseMove(e:MouseEvent):void {
			if (!isDragging)
				return;
			const listContentHeight:Number = LIST_HEIGHT - 12;
			const deltaY:Number = e.stageY - dragStartY;
			var newThumbY:Number = thumbStartY + deltaY;
			const maxThumbY:Number = listContentHeight - thumbHeight;
			newThumbY = Math.max(0, Math.min(newThumbY, maxThumbY));
			scrollY = (newThumbY / maxThumbY) * maxScrollY;
			updateScrollPosition();
		}

		private function onStageMouseUp(e:MouseEvent):void {
			isDragging = false;
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			}
		}

		private function onThumbRollOver(e:MouseEvent):void {
			const tBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x475569, 1.0);
		}

		private function onThumbRollOut(e:MouseEvent):void {
			const tBg:Shape = Shape(scrollThumb.getChildAt(0));
			drawRoundedRect(tBg.graphics, 0, 0, SCROLLBAR_WIDTH, thumbHeight, 4, 0x334155, 0.9);
		}

		private function onClearClick(e:MouseEvent):void {
			packets = [];
			refresh();
		}

		private function createCopyHandler(packetMsg:String, btnTf:TextField):Function {
			return function(e:MouseEvent):void {
				System.setClipboard(packetMsg);
				btnTf.text = "Done";
				btnTf.textColor = 0x4ade80;
				var timer:Timer = new Timer(1200, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent):void {
						btnTf.text = "Copy";
						btnTf.textColor = 0x94a3b8;
					});
				timer.start();
			};
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

		private static function drawCircle(g:Graphics, x:Number, y:Number, r:Number, fillColor:uint, fillAlpha:Number, strokeColor:uint = 0, strokeThickness:Number = 0):void {
			g.clear();
			g.beginFill(fillColor, fillAlpha);
			if (strokeThickness > 0) {
				g.lineStyle(strokeThickness, strokeColor, 1.0);
			}
			g.drawCircle(x, y, r);
			g.endFill();
		}
	}
}
