package input {

	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	import ui.BaseModal;
	import ui.ChipTag;
	import ui.CloseButton;
	import ui.ConfirmationMessage;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyTextField;
	import ui.ScrollContainer;
	import ui.UIUtils;
	import commands.BotCommand;
	import engine.BotEngine;
	import Config;
	import com.aqw.battery.BatteryOptimizer;
	import Utils;
	import commands.KillCommand;
	import commands.JoinCommand;
	import commands.JumpCommand;
	import commands.QuestAcceptCommand;
	import commands.QuestCompleteCommand;
	import commands.DelayCommand;
	import commands.TransferToBankCommand;
	import commands.TransferToInventoryCommand;
	import commands.NotifCommand;

	public class BotManagerUI extends BaseModal {

		public static var instance:BotManagerUI;

		private static const MODAL_W:Number = 620;
		private static const MODAL_H:Number = 380;
		private static const COL_LEFT_W:Number = 236;
		private static const COL_RIGHT_X:Number = 260;
		private static const COL_RIGHT_W:Number = MODAL_W - COL_RIGHT_X - BaseModal.PADDING; // 348

		private var game:Object;
		public var botEngine:BotEngine;

		// Left Column: Command List & Controls
		private var commandCountLabel:TextField;
		private var commandScroll:ScrollContainer;
		private var emptyCommandLabel:TextField;
		private var startBtn:MyButton;
		private var pauseBtn:MyButton;
		private var stopBtn:MyButton;
		private var clearBtn:MyButton;
		private var moveUpBtn:MyButton;
		private var moveDownBtn:MyButton;
		private var botStatsTimeLabel:TextField;
		private var botStatsLoopLabel:TextField;
		private var statsTimer:Timer;
		private var selectedCommandIndex:int = -1;

		// Right Column: Tab & Action Buttons
		private var tabCombatBtn:MyButton;
		private var tabQuestBtn:MyButton;
		private var tabMapBtn:MyButton;
		private var tabItemBtn:MyButton;
		private var tabMiscBtn:MyButton;
		private var loadBtn:MyButton;
		private var saveBtn:MyButton;

		// Right Column: Tab Viewports
		private var tabContentContainer:Sprite;
		private var combatTab:Sprite;
		private var questTab:Sprite;
		private var mapTab:Sprite;
		private var itemTab:Sprite;
		private var miscTab:Sprite;
		private var currentTab:int = 0; // 0=Combat, 1=Quest, 2=Map, 3=Item, 4=Misc

		// Item Tab Fields
		private var itemTransferInput:MyTextField;

		// Combat Tab Fields
		private var monsterTargetInput:MyTextField;
		private var killModeOnceBtn:MyButton;
		private var killModeCountBtn:MyButton;
		private var killModeItemBtn:MyButton;
		private var currentKillMode:String = KillCommand.MODE_NONE;

		private var killCountContainer:Sprite;
		private var killCountInput:MyTextField;

		private var killItemContainer:Sprite;
		private var killItemNameInput:MyTextField;
		private var killItemQtyInput:MyTextField;

		// Misc Tab Fields
		private var botRepeatCheckbox:MyCheckbox;
		private var leaveCombatCheckbox:MyCheckbox;
		private var notifyDropsCheckbox:MyCheckbox;
		private var whitelistStatusLabel:TextField;

		// Load / Save / Whitelist Modals
		private var loadModal:BotLoadModal;
		private var saveModal:BotSaveModal;
		private var whitelistModal:BotWhitelistModal;

		// Edit Command Dialog Overlay
		private var editModalOverlay:Sprite;
		private var editModalSub:TextField;
		private var editModalFormContainer:Sprite;
		private var editingIndex:int = -1;
		private var editingCmd:BotCommand;

		private var editMonInput:MyTextField;
		private var editKillMode:String = KillCommand.MODE_NONE;
		private var editKillOnceBtn:MyButton;
		private var editKillCountBtn:MyButton;
		private var editKillItemBtn:MyButton;
		private var editKillCountBox:Sprite;
		private var editKillCountInput:MyTextField;
		private var editKillItemBox:Sprite;
		private var editKillItemNameInput:MyTextField;
		private var editKillItemQtyInput:MyTextField;

		private var editMapInput:MyTextField;
		private var editCellInput:MyTextField;
		private var editPadInput:MyTextField;

		private var editQuestIdInput:MyTextField;
		private var editQuestItemIdInput:MyTextField;

		private var editDelayInput:MyTextField;

		private var editItemTransferInput:MyTextField;

		private var editNotifTitleInput:MyTextField;
		private var editNotifMsgInput:MyTextField;

		public function BotManagerUI(game:Object = null) {
			super(MODAL_W, MODAL_H, "Bot Manager", "Script Builder");
			instance = this;
			this.game = game;

			botEngine = new BotEngine(game);
			botEngine.onStateChange = onEngineStateChange;
			botEngine.onStepChange = onEngineStepChange;

			buildLeftSection();
			buildVerticalDivider();
			buildRightSection();
			loadModal = new BotLoadModal(botEngine, onBotScriptLoaded);
			addChild(loadModal);

			saveModal = new BotSaveModal(botEngine);
			addChild(saveModal);

			whitelistModal = new BotWhitelistModal(botEngine, onWhitelistChanged);
			addChild(whitelistModal);

			buildEditModalOverlay();

			if (Config.isAndroid) {
				const pipBtn:MyButton = new MyButton("PiP", 38, 22, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						try {
							BatteryOptimizer.enterPipMode();
						}
						catch (err:Error) {
						}
					}, 10);
				pipBtn.x = MODAL_W - BaseModal.PADDING - 22 - 44;
				pipBtn.y = 7;
				addHeaderControl(pipBtn);
			}

			switchTab(0);

			addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
		}

		private function onAdded(e:Event):void {
			if (stage != null) {
				centerOnStage();
			}
		}

		// =========================================================================
		// Left Section: Command List & Controls
		// =========================================================================
		private function buildLeftSection():void {
			const leftX:Number = BaseModal.PADDING;
			const topY:Number = BaseModal.HEADER_HEIGHT + 10; // 46

			const listTitle:TextField = UIUtils.createLabel("COMMAND LIST", UIUtils.TEXT_DIM, 9.5, true);
			listTitle.x = leftX;
			listTitle.y = topY;
			addChild(listTitle);

			commandCountLabel = UIUtils.createLabel("(0 items)", UIUtils.TEXT_DIM, 9.5, false, TextFormatAlign.RIGHT);
			commandCountLabel.x = leftX + COL_LEFT_W - 80;
			commandCountLabel.y = topY;
			commandCountLabel.width = 80;
			addChild(commandCountLabel);

			// Bottom Toolbar (Start ▶, Pause ⏸, Stop ⏹, Clear, Move Up ▲, Move Down ▼)
			// Positioned at the very bottom of the modal
			const toolbarH:Number = 26;
			const toolbarY:Number = MODAL_H - BaseModal.PADDING - toolbarH; // 380 - 12 - 26 = 342
			const scrollH:Number = toolbarY - (topY + 18) - 8; // 342 - 64 - 8 = 270

			commandScroll = new ScrollContainer(COL_LEFT_W, scrollH, 10, true);
			commandScroll.x = leftX;
			commandScroll.y = topY + 18; // 64
			addChild(commandScroll);

			emptyCommandLabel = UIUtils.createLabel(
					"No commands added yet.\n\nConfigure actions on the right\nand add them to the script.",
					UIUtils.TEXT_DIM,
					10.5,
					false,
					TextFormatAlign.CENTER
				);
			emptyCommandLabel.width = COL_LEFT_W - 16;
			emptyCommandLabel.x = 8;
			emptyCommandLabel.y = 80;
			emptyCommandLabel.multiline = true;
			emptyCommandLabel.wordWrap = true;
			commandScroll.addItem(emptyCommandLabel);

			const gap:Number = 4;

			startBtn = new MyButton("▶", 34, 26, MyButton.TYPE_SUCCESS, onStartClick, 11);
			startBtn.x = leftX;
			startBtn.y = toolbarY;
			addChild(startBtn);

			pauseBtn = new MyButton("⏸", 34, 26, MyButton.TYPE_SECONDARY, onPauseClick, 10);
			pauseBtn.x = leftX + 34 + gap;
			pauseBtn.y = toolbarY;
			pauseBtn.enabled = false;
			addChild(pauseBtn);

			stopBtn = new MyButton("⏹", 34, 26, MyButton.TYPE_DANGER, onStopClick, 11);
			stopBtn.x = leftX + (34 + gap) * 2;
			stopBtn.y = toolbarY;
			stopBtn.enabled = false;
			addChild(stopBtn);

			const rightAreaX:Number = leftX + (34 + gap) * 3; // 12 + 38 * 3 = 126
			const rightAreaW:Number = (leftX + COL_LEFT_W) - rightAreaX; // 248 - 126 = 122

			clearBtn = new MyButton("Clear", 44, 26, MyButton.TYPE_MUTED, onClearClick, 10);
			clearBtn.x = rightAreaX;
			clearBtn.y = toolbarY;
			addChild(clearBtn);

			moveUpBtn = new MyButton("▲", 34, 26, MyButton.TYPE_SECONDARY, onMoveUpClick, 11);
			moveUpBtn.x = rightAreaX + 44 + gap; // 174
			moveUpBtn.y = toolbarY;
			moveUpBtn.enabled = false;
			addChild(moveUpBtn);

			moveDownBtn = new MyButton("▼", 34, 26, MyButton.TYPE_SECONDARY, onMoveDownClick, 11);
			moveDownBtn.x = rightAreaX + 44 + gap + 34 + gap; // 212
			moveDownBtn.y = toolbarY;
			moveDownBtn.enabled = false;
			addChild(moveDownBtn);

			// Running Time & Completed Loops Status Info (Vertical layout replacing clear/up/down buttons when running)
			botStatsTimeLabel = UIUtils.createLabel("", 0x34d399, 9.5, true, TextFormatAlign.LEFT);
			botStatsTimeLabel.x = rightAreaX + 2;
			botStatsTimeLabel.y = toolbarY - 1;
			botStatsTimeLabel.width = rightAreaW - 2;
			botStatsTimeLabel.height = 14;
			botStatsTimeLabel.visible = false;
			addChild(botStatsTimeLabel);

			botStatsLoopLabel = UIUtils.createLabel("", UIUtils.TEXT_MUTED, 9.5, false, TextFormatAlign.LEFT);
			botStatsLoopLabel.x = rightAreaX + 2;
			botStatsLoopLabel.y = toolbarY + 13;
			botStatsLoopLabel.width = rightAreaW - 2;
			botStatsLoopLabel.height = 14;
			botStatsLoopLabel.visible = false;
			addChild(botStatsLoopLabel);
		}

		// =========================================================================
		// Vertical Divider
		// =========================================================================
		private function buildVerticalDivider():void {
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(COL_RIGHT_X - 12, BaseModal.HEADER_HEIGHT + 8);
			div.graphics.lineTo(COL_RIGHT_X - 12, MODAL_H - BaseModal.PADDING);
			addChild(div);
		}

		// =========================================================================
		// Right Section: Tabs & Tab Viewports
		// =========================================================================
		private function buildRightSection():void {
			const topY:Number = BaseModal.HEADER_HEIGHT + 8; // 44
			const tabH:Number = 26;
			const gap:Number = 4;

			tabCombatBtn = new MyButton("Combat", 52, tabH, MyButton.TYPE_SECONDARY, onTabCombatClick);
			tabCombatBtn.x = COL_RIGHT_X;
			tabCombatBtn.y = topY;
			addChild(tabCombatBtn);

			tabQuestBtn = new MyButton("Quest", 48, tabH, MyButton.TYPE_SECONDARY, onTabQuestClick);
			tabQuestBtn.x = tabCombatBtn.x + 52 + gap;
			tabQuestBtn.y = topY;
			addChild(tabQuestBtn);

			tabMapBtn = new MyButton("Map", 46, tabH, MyButton.TYPE_SECONDARY, onTabMapClick);
			tabMapBtn.x = tabQuestBtn.x + 48 + gap;
			tabMapBtn.y = topY;
			addChild(tabMapBtn);

			tabItemBtn = new MyButton("Item", 46, tabH, MyButton.TYPE_SECONDARY, onTabItemClick);
			tabItemBtn.x = tabMapBtn.x + 46 + gap;
			tabItemBtn.y = topY;
			addChild(tabItemBtn);

			tabMiscBtn = new MyButton("Misc", 46, tabH, MyButton.TYPE_SECONDARY, onTabMiscClick);
			tabMiscBtn.x = tabItemBtn.x + 46 + gap;
			tabMiscBtn.y = topY;
			addChild(tabMiscBtn);

			tabContentContainer = new Sprite();
			tabContentContainer.x = COL_RIGHT_X;
			tabContentContainer.y = topY + tabH + 8; // 78
			addChild(tabContentContainer);

			const frameBg:Shape = new Shape();
			const frameH:Number = MODAL_H - tabContentContainer.y - BaseModal.PADDING; // 290
			UIUtils.drawRoundedRect(frameBg.graphics, 0, 0, COL_RIGHT_W, frameH, 6, UIUtils.BG_RECESSED, 0.6, UIUtils.BORDER_SUBTLE, 1);
			tabContentContainer.addChild(frameBg);

			buildCombatTab();
			buildQuestTab();
			buildMapTab();
			buildItemTab();
			buildMiscTab();
		}

		// =========================================================================
		// 1. Combat Tab
		// =========================================================================
		private function buildCombatTab():void {
			combatTab = new Sprite();
			combatTab.x = 10;
			combatTab.y = 10;

			// Monster Target Input (fontSize defaults to 12.5)
			const monsterLbl:TextField = UIUtils.createLabel("Monster Target (* for any):", UIUtils.TEXT_MUTED, 10.5);
			monsterLbl.y = 4;
			combatTab.addChild(monsterLbl);

			monsterTargetInput = new MyTextField(COL_RIGHT_W - 20, 24);
			monsterTargetInput.y = 22;
			monsterTargetInput.text = "*";
			combatTab.addChild(monsterTargetInput);

			// Kill Until Condition Selector
			const condLbl:TextField = UIUtils.createLabel("Kill Until (Condition):", UIUtils.TEXT_MUTED, 10.5);
			condLbl.y = 54;
			combatTab.addChild(condLbl);

			const btnW:Number = 96;
			const btnH:Number = 22;

			killModeOnceBtn = new MyButton("Kill Once", btnW, btnH, MyButton.TYPE_SECONDARY, onKillModeOnceClick);
			killModeOnceBtn.y = 88;
			combatTab.addChild(killModeOnceBtn);

			killModeCountBtn = new MyButton("Kill Count", btnW, btnH, MyButton.TYPE_SECONDARY, onKillModeCountClick);
			killModeCountBtn.x = btnW + 6;
			killModeCountBtn.y = 88;
			combatTab.addChild(killModeCountBtn);

			killModeItemBtn = new MyButton("Kill for Items", 112, btnH, MyButton.TYPE_SECONDARY, onKillModeItemClick);
			killModeItemBtn.x = (btnW + 6) * 2;
			killModeItemBtn.y = 88;
			combatTab.addChild(killModeItemBtn);

			// Kill Count Section
			killCountContainer = new Sprite();
			killCountContainer.y = 118;
			combatTab.addChild(killCountContainer);

			const countLbl:TextField = UIUtils.createLabel("Target Kill Count:", UIUtils.TEXT_MUTED, 10.5);
			killCountContainer.addChild(countLbl);

			killCountInput = new MyTextField(90, 24);
			killCountInput.y = 18;
			killCountInput.text = "5";
			killCountInput.restrict = "0-9";
			killCountContainer.addChild(killCountInput);

			// Kill For Items Section
			killItemContainer = new Sprite();
			killItemContainer.y = 118;
			combatTab.addChild(killItemContainer);

			const itemLbl:TextField = UIUtils.createLabel("Item Name (Inventory or Temp):", UIUtils.TEXT_MUTED, 10.5);
			killItemContainer.addChild(itemLbl);

			killItemNameInput = new MyTextField(185, 24);
			killItemNameInput.y = 18;
			killItemNameInput.text = "";
			killItemContainer.addChild(killItemNameInput);

			const qtyLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
			qtyLbl.x = 195;
			killItemContainer.addChild(qtyLbl);

			killItemQtyInput = new MyTextField(60, 24);
			killItemQtyInput.x = 195;
			killItemQtyInput.y = 18;
			killItemQtyInput.text = "1";
			killItemQtyInput.restrict = "0-9";
			killItemContainer.addChild(killItemQtyInput);

			const noteTf:TextField = UIUtils.createLabel("Loops kill until item in inventory or temp inventory reaches quantity.", UIUtils.TEXT_DIM, 9.5);
			noteTf.y = 46;
			noteTf.width = COL_RIGHT_W - 20;
			killItemContainer.addChild(noteTf);

			setKillMode(KillCommand.MODE_NONE);

			const addCombatBtn:MyButton = new MyButton("Add Combat Command", 154, 26, MyButton.TYPE_PRIMARY, onAddCombatCommandClick);
			addCombatBtn.y = 200;
			combatTab.addChild(addCombatBtn);

			tabContentContainer.addChild(combatTab);
		}

		private function setKillMode(mode:String):void {
			currentKillMode = mode;

			killModeOnceBtn.setType(mode == KillCommand.MODE_NONE ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			killModeCountBtn.setType(mode == KillCommand.MODE_COUNT ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			killModeItemBtn.setType(mode == KillCommand.MODE_ITEM ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);

			killModeOnceBtn.active = (mode == KillCommand.MODE_NONE);
			killModeCountBtn.active = (mode == KillCommand.MODE_COUNT);
			killModeItemBtn.active = (mode == KillCommand.MODE_ITEM);

			killCountContainer.visible = (mode == KillCommand.MODE_COUNT);
			killItemContainer.visible = (mode == KillCommand.MODE_ITEM);
		}

		// =========================================================================
		// 2. Quest Tab
		// =========================================================================
		private function buildQuestTab():void {
			questTab = new Sprite();
			questTab.x = 10;
			questTab.y = 10;

			// Quest ID
			const qLbl:TextField = UIUtils.createLabel("Quest ID:", UIUtils.TEXT_MUTED, 10.5);
			qLbl.x = 0;
			qLbl.y = 6;
			questTab.addChild(qLbl);

			const qInput:MyTextField = new MyTextField(110, 24);
			qInput.name = "questIdInput";
			qInput.x = 0;
			qInput.y = 24;
			qInput.restrict = "0-9";
			questTab.addChild(qInput);

			// Item ID (Reward Selection, default -1)
			const itemLbl:TextField = UIUtils.createLabel("Item ID:", UIUtils.TEXT_MUTED, 10.5);
			itemLbl.x = 120;
			itemLbl.y = 6;
			questTab.addChild(itemLbl);

			const itemInput:MyTextField = new MyTextField(110, 24);
			itemInput.name = "questItemIdInput";
			itemInput.x = 120;
			itemInput.y = 24;
			itemInput.text = "-1";
			itemInput.restrict = "0-9\\-";
			questTab.addChild(itemInput);

			// Buttons
			const addAcceptBtn:MyButton = new MyButton("Add Accept Quest", 130, 26, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var qid:int = parseInt(qInput.text);
					if (qid > 0) {
						addBotCommand(BotCommand.createQuestAccept(qid));
					}
				});
			addAcceptBtn.x = 0;
			addAcceptBtn.y = 64;
			questTab.addChild(addAcceptBtn);

			const addTurnInBtn:MyButton = new MyButton("Add Turn-In Quest", 130, 26, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var qid:int = parseInt(qInput.text);
					var iid:int = parseInt(itemInput.text);
					if (isNaN(iid)) {
						iid = -1;
					}
					if (qid > 0) {
						addBotCommand(BotCommand.createQuestComplete(qid, iid));
					}
				});
			addTurnInBtn.x = 138;
			addTurnInBtn.y = 64;
			questTab.addChild(addTurnInBtn);

			tabContentContainer.addChild(questTab);
		}

		// =========================================================================
		// 3. Map Tab (Join Map, Jump Cell, Delay)
		// =========================================================================
		private function buildMapTab():void {
			mapTab = new Sprite();
			mapTab.x = 10;
			mapTab.y = 10;

			// 1. Join Map Section
			const mapLbl:TextField = UIUtils.createLabel("Join Map:", UIUtils.TEXT_MUTED, 10.5);
			mapLbl.y = 4;
			mapTab.addChild(mapLbl);

			const mapInput:MyTextField = new MyTextField(130, 24);
			mapInput.y = 22;
			mapTab.addChild(mapInput);

			const cellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
			cellLbl.x = 138;
			cellLbl.y = 4;
			mapTab.addChild(cellLbl);

			const cellInput:MyTextField = new MyTextField(80, 24);
			cellInput.x = 138;
			cellInput.y = 22;
			cellInput.text = "Enter";
			mapTab.addChild(cellInput);

			const padLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
			padLbl.x = 226;
			padLbl.y = 4;
			mapTab.addChild(padLbl);

			const padInput:MyTextField = new MyTextField(80, 24);
			padInput.x = 226;
			padInput.y = 22;
			padInput.text = "Spawn";
			mapTab.addChild(padInput);

			const addJoinBtn:MyButton = new MyButton("Add Join Map", 110, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (mapInput.trimmedText.length > 0) {
						addBotCommand(BotCommand.createJoin(mapInput.trimmedText, cellInput.trimmedText, padInput.trimmedText));
					}
				});
			addJoinBtn.y = 52;
			mapTab.addChild(addJoinBtn);

			const getCurrentBtn:MyButton = new MyButton("Get Current", 100, 24, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					try {
						if (game != null && game.world != null) {
							if (game.world.strAreaName != null && String(game.world.strAreaName).length > 0) {
								mapInput.text = String(game.world.strAreaName);
							}
							var curCell:String = (game.world.strFrame != null && String(game.world.strFrame).length > 0) ? String(game.world.strFrame) : "Enter";
							var curPad:String = (game.world.strPad != null && String(game.world.strPad).length > 0) ? String(game.world.strPad) : "Spawn";

							cellInput.text = curCell;
							padInput.text = curPad;

							jCellInput.text = curCell;
							jPadInput.text = curPad;
						}
					}
					catch (err:Error) {
					}
				});
			getCurrentBtn.x = 118;
			getCurrentBtn.y = 52;
			mapTab.addChild(getCurrentBtn);

			// Divider between Join and Jump
			const div1:Shape = new Shape();
			div1.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div1.graphics.moveTo(0, 84);
			div1.graphics.lineTo(COL_RIGHT_W - 20, 84);
			mapTab.addChild(div1);

			// 2. Jump Cell Section (uses Player.Jump / moveToCell)
			const jumpTitle:TextField = UIUtils.createLabel("Jump Cell (Current Map):", UIUtils.TEXT_MUTED, 10.5);
			jumpTitle.y = 92;
			mapTab.addChild(jumpTitle);

			const jCellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
			jCellLbl.y = 110;
			mapTab.addChild(jCellLbl);

			const jCellInput:MyTextField = new MyTextField(100, 24);
			jCellInput.x = 0;
			jCellInput.y = 128;
			jCellInput.text = "Enter";
			mapTab.addChild(jCellInput);

			const jPadLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
			jPadLbl.x = 110;
			jPadLbl.y = 110;
			mapTab.addChild(jPadLbl);

			const jPadInput:MyTextField = new MyTextField(100, 24);
			jPadInput.x = 110;
			jPadInput.y = 128;
			jPadInput.text = "Spawn";
			mapTab.addChild(jPadInput);

			const addJumpBtn:MyButton = new MyButton("Add Jump Cell", 110, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (jCellInput.trimmedText.length > 0) {
						addBotCommand(BotCommand.createJump(jCellInput.trimmedText, jPadInput.trimmedText));
					}
				});
			addJumpBtn.x = 218;
			addJumpBtn.y = 128;
			mapTab.addChild(addJumpBtn);

			tabContentContainer.addChild(mapTab);
		}

		// =========================================================================
		// 4. Item Tab (TransferToBank & TransferToInventory)
		// =========================================================================
		private function buildItemTab():void {
			itemTab = new Sprite();
			itemTab.x = 10;
			itemTab.y = 10;

			const itemLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
			itemLbl.x = 0;
			itemLbl.y = 6;
			itemTab.addChild(itemLbl);

			itemTransferInput = new MyTextField(COL_RIGHT_W - 20, 24);
			itemTransferInput.x = 0;
			itemTransferInput.y = 24;
			itemTab.addChild(itemTransferInput);

			const addBankBtn:MyButton = new MyButton("Transfer To Bank", 130, 26, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (itemTransferInput.trimmedText.length > 0) {
						addBotCommand(BotCommand.createTransferToBank(itemTransferInput.trimmedText));
					}
				});
			addBankBtn.x = 0;
			addBankBtn.y = 60;
			itemTab.addChild(addBankBtn);

			const addInvBtn:MyButton = new MyButton("Transfer To Inv", 130, 26, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (itemTransferInput.trimmedText.length > 0) {
						addBotCommand(BotCommand.createTransferToInventory(itemTransferInput.trimmedText));
					}
				});
			addInvBtn.x = 138;
			addInvBtn.y = 60;
			itemTab.addChild(addInvBtn);

			tabContentContainer.addChild(itemTab);
		}

		// =========================================================================
		// 5. Misc Tab (Wait Delay, Notif Command, Whitelist Drops, Script Load & Save)
		// =========================================================================
		private function buildMiscTab():void {
			miscTab = new Sprite();
			miscTab.x = 10;
			miscTab.y = 10;

			// 1. Checkboxes Section
			botRepeatCheckbox = new MyCheckbox("Bot Repeat", botEngine.loop, function(val:Boolean):void {
					botEngine.loop = val;
				});
			botRepeatCheckbox.x = 0;
			botRepeatCheckbox.y = 0;
			miscTab.addChild(botRepeatCheckbox);

			leaveCombatCheckbox = new MyCheckbox("Leave combat on stop/pause", botEngine.leaveCombatOnStop, function(val:Boolean):void {
					botEngine.leaveCombatOnStop = val;
				});
			leaveCombatCheckbox.x = 0;
			leaveCombatCheckbox.y = 22;
			miscTab.addChild(leaveCombatCheckbox);

			// 2. Wait Delay & Notif Command Section
			const delayLbl:TextField = UIUtils.createLabel("Wait Delay (s):", UIUtils.TEXT_MUTED, 10.5);
			delayLbl.y = 48;
			miscTab.addChild(delayLbl);

			const delayInput:MyTextField = new MyTextField(60, 24);
			delayInput.y = 66;
			delayInput.text = "2";
			delayInput.restrict = "0-9.";
			miscTab.addChild(delayInput);

			const addWaitBtn:MyButton = new MyButton("Add Delay", 74, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					var secs:Number = parseFloat(delayInput.text);
					if (!isNaN(secs) && secs > 0) {
						addBotCommand(BotCommand.createDelay(secs));
					}
				});
			addWaitBtn.x = 68;
			addWaitBtn.y = 66;
			miscTab.addChild(addWaitBtn);

			// Notification Command Section
			const notifLbl:TextField = UIUtils.createLabel("Notification Message:", UIUtils.TEXT_MUTED, 10.5);
			notifLbl.y = 96;
			miscTab.addChild(notifLbl);

			const notifInput:MyTextField = new MyTextField(160, 24);
			notifInput.y = 114;
			notifInput.text = "";
			miscTab.addChild(notifInput);

			const addNotifBtn:MyButton = new MyButton("Add Notif", 78, 24, MyButton.TYPE_PRIMARY, function(e:MouseEvent):void {
					if (notifInput.trimmedText.length > 0) {
						addBotCommand(BotCommand.createNotif(notifInput.trimmedText));
						notifInput.text = "";
					}
				});
			addNotifBtn.x = 168;
			addNotifBtn.y = 114;
			miscTab.addChild(addNotifBtn);

			// Divider between Commands and Whitelist
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div.graphics.moveTo(0, 146);
			div.graphics.lineTo(COL_RIGHT_W - 20, 146);
			miscTab.addChild(div);

			// 3. Whitelist Drops Section
			const wlSectionLbl:TextField = UIUtils.createLabel("Drops Whitelist:", UIUtils.TEXT_MUTED, 10.5);
			wlSectionLbl.y = 154;
			miscTab.addChild(wlSectionLbl);

			whitelistStatusLabel = UIUtils.createLabel("No items whitelisted.", UIUtils.TEXT_DIM, 9.5);
			whitelistStatusLabel.x = 94;
			whitelistStatusLabel.y = 154;
			whitelistStatusLabel.width = COL_RIGHT_W - 20 - 94;
			miscTab.addChild(whitelistStatusLabel);

			const manageWlBtn:MyButton = new MyButton("Manage Whitelist", 124, 24, MyButton.TYPE_PRIMARY, onOpenWhitelistModal);
			manageWlBtn.x = 0;
			manageWlBtn.y = 176;
			miscTab.addChild(manageWlBtn);

			notifyDropsCheckbox = new MyCheckbox("Drop Notif", botEngine.notifyItemDrops, function(val:Boolean):void {
					botEngine.notifyItemDrops = val;
				}, 10.5);
			notifyDropsCheckbox.x = 132;
			notifyDropsCheckbox.y = 180;
			miscTab.addChild(notifyDropsCheckbox);

			// Divider between Whitelist and Script Files
			const div2:Shape = new Shape();
			div2.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 0.7);
			div2.graphics.moveTo(0, 210);
			div2.graphics.lineTo(COL_RIGHT_W - 20, 210);
			miscTab.addChild(div2);

			// 4. Script Files Section (Load & Save)
			const scriptLbl:TextField = UIUtils.createLabel("Script Management:", UIUtils.TEXT_MUTED, 10.5);
			scriptLbl.y = 218;
			miscTab.addChild(scriptLbl);

			loadBtn = new MyButton("Load Script", 100, 26, MyButton.TYPE_MUTED, onLoadClick);
			loadBtn.setColors(0x064e3b, 0x065f46, 0x059669, 0x10b981, 0xa7f3d0, 0xffffff);
			loadBtn.x = 0;
			loadBtn.y = 238;
			miscTab.addChild(loadBtn);

			saveBtn = new MyButton("Save Script", 100, 26, MyButton.TYPE_MUTED, onSaveClick);
			saveBtn.setColors(0x1e1b4b, 0x2e1065, 0x4338ca, 0x6366f1, 0xc7d2fe, 0xffffff);
			saveBtn.x = 108;
			saveBtn.y = 238;
			miscTab.addChild(saveBtn);

			updateWhitelistStatus();

			tabContentContainer.addChild(miscTab);
		}

		public function switchTab(index:int):void {
			currentTab = index;

			tabCombatBtn.setType(index == 0 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabQuestBtn.setType(index == 1 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabMapBtn.setType(index == 2 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabItemBtn.setType(index == 3 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabMiscBtn.setType(index == 4 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);

			tabCombatBtn.active = (index == 0);
			tabQuestBtn.active = (index == 1);
			tabMapBtn.active = (index == 2);
			tabItemBtn.active = (index == 3);
			tabMiscBtn.active = (index == 4);

			combatTab.visible = (index == 0);
			questTab.visible = (index == 1);
			mapTab.visible = (index == 2);
			itemTab.visible = (index == 3);
			miscTab.visible = (index == 4);

			if (index == 4) {
				updateWhitelistStatus();
			}
		}

		private function onTabCombatClick(e:MouseEvent):void {
			switchTab(0);
		}

		private function onTabQuestClick(e:MouseEvent):void {
			switchTab(1);
		}

		private function onTabMapClick(e:MouseEvent):void {
			switchTab(2);
		}

		private function onTabItemClick(e:MouseEvent):void {
			switchTab(3);
		}

		private function onTabMiscClick(e:MouseEvent):void {
			switchTab(4);
		}

		private function onKillModeOnceClick(e:MouseEvent):void {
			setKillMode(KillCommand.MODE_NONE);
		}

		private function onKillModeCountClick(e:MouseEvent):void {
			setKillMode(KillCommand.MODE_COUNT);
		}

		private function onKillModeItemClick(e:MouseEvent):void {
			setKillMode(KillCommand.MODE_ITEM);
		}

		// =========================================================================
		// Script Actions
		// =========================================================================
		private function onAddCombatCommandClick(e:MouseEvent):void {
			var mon:String = monsterTargetInput.trimmedText;
			if (mon.length == 0)
				mon = "*";

			var cmd:BotCommand;
			if (currentKillMode == KillCommand.MODE_ITEM) {
				var itemName:String = killItemNameInput.trimmedText;
				var itemQty:int = parseInt(killItemQtyInput.text);
				if (itemName.length == 0)
					return;
				cmd = BotCommand.createKill(mon, KillCommand.MODE_ITEM, 1, itemName, itemQty);
			}
			else if (currentKillMode == KillCommand.MODE_COUNT) {
				var kCount:int = parseInt(killCountInput.text);
				cmd = BotCommand.createKill(mon, KillCommand.MODE_COUNT, kCount);
			}
			else {
				cmd = BotCommand.createKill(mon, KillCommand.MODE_NONE);
			}

			addBotCommand(cmd);
		}

		public function addBotCommand(cmd:BotCommand):void {
			if (cmd == null)
				return;
			botEngine.addCommand(cmd);
			refreshCommandList();
			commandScroll.scrollToBottom();
		}

		private function refreshCommandList(resetScroll:Boolean = false):void {
			const savedScrollY:Number = resetScroll ? 0 : commandScroll.scrollY;
			commandScroll.clearContent(resetScroll);

			const cmds:Array = botEngine.commandList;
			commandCountLabel.text = "(" + cmds.length + " items)";

			if (cmds.length == 0) {
				commandScroll.addItem(emptyCommandLabel);
				emptyCommandLabel.visible = true;
				selectedCommandIndex = -1;
				updateMoveButtonsState();
				commandScroll.updateScroll(0);
				return;
			}

			emptyCommandLabel.visible = false;

			const rowW:Number = commandScroll.contentWidth;
			const rowH:Number = 24;

			for (var i:int = 0; i < cmds.length; i++) {
				const cmd:BotCommand = cmds[i] as BotCommand;
				const row:Sprite = buildCommandRow(i, cmd, rowW, rowH);
				row.y = i * (rowH + 3);
				commandScroll.addItem(row);
			}

			commandScroll.updateScroll(cmds.length * (rowH + 3));
			if (!resetScroll) {
				commandScroll.scrollY = savedScrollY;
			}
			updateMoveButtonsState();
		}

		private function buildCommandRow(index:int, cmd:BotCommand, w:Number, h:Number):Sprite {
			const row:Sprite = new Sprite();
			row.name = String(index);

			const isRunning:Boolean = botEngine.isRunning;
			row.buttonMode = !isRunning;
			row.useHandCursor = !isRunning;

			const isCurrent:Boolean = isRunning && (botEngine.currentStep == index);
			const isSelected:Boolean = !isRunning && (selectedCommandIndex == index);

			var bgCol:uint = 0x0f172a;
			var borderCol:uint = 0x1e293b;
			var txtCol:uint = UIUtils.TEXT_MAIN;

			if (isCurrent) {
				bgCol = 0x1e3a5f;
				borderCol = 0x3b82f6;
				txtCol = 0xffffff;
			}
			else if (isSelected) {
				bgCol = 0x1e293b;
				borderCol = 0x60a5fa;
				txtCol = 0x93c5fd;
			}

			const bg:Shape = new Shape();
			UIUtils.drawRoundedRect(bg.graphics, 0, 0, w, h, 4, bgCol, 0.95, borderCol, 1);
			row.addChild(bg);

			const badgeTf:TextField = UIUtils.createLabel(String(index + 1) + ".", isSelected ? 0x60a5fa : UIUtils.TEXT_DIM, 9.5, true);
			badgeTf.x = 4;
			badgeTf.y = 4;
			badgeTf.width = 20;
			row.addChild(badgeTf);

			const textW:Number = isRunning ? (w - 28) : (w - 70);
			const txtTf:TextField = UIUtils.createLabel(cmd.toString(), txtCol, 9.5, false);
			txtTf.x = 24;
			txtTf.y = 4;
			txtTf.width = textW;
			row.addChild(txtTf);

			// Edit and Delete buttons & Selection click (only available when bot is NOT running)
			if (!isRunning) {
				// Edit button
				const editBtn:Sprite = new Sprite();
				editBtn.buttonMode = true;
				editBtn.useHandCursor = true;

				const editBg:Shape = new Shape();
				UIUtils.drawRoundedRect(editBg.graphics, 0, 0, 16, 16, 3, 0x1e293b, 1.0);
				editBtn.addChild(editBg);

				const editLabel:TextField = UIUtils.createLabel("✎", UIUtils.TEXT_MUTED, 10.5, true, TextFormatAlign.CENTER);
				editLabel.width = 16;
				editLabel.height = 16;
				editLabel.y = 0;
				editBtn.addChild(editLabel);

				editBtn.x = w - 45;
				editBtn.y = 4;

				editBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(editBg.graphics, 0, 0, 16, 16, 3, 0x2563eb, 1.0);
						editLabel.textColor = 0xffffff;
					});
				editBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(editBg.graphics, 0, 0, 16, 16, 3, 0x1e293b, 1.0);
						editLabel.textColor = UIUtils.TEXT_MUTED;
					});
				editBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						e.stopPropagation();
						openEditCommandModal(index, cmd);
					});
				row.addChild(editBtn);

				// Delete button
				const delBtn:Sprite = new Sprite();
				delBtn.buttonMode = true;
				delBtn.useHandCursor = true;

				const delBg:Shape = new Shape();
				UIUtils.drawRoundedRect(delBg.graphics, 0, 0, 16, 16, 3, 0x1e293b, 1.0);
				delBtn.addChild(delBg);

				const delLabel:TextField = UIUtils.createLabel("×", UIUtils.TEXT_MUTED, 10.5, true, TextFormatAlign.CENTER);
				delLabel.width = 16;
				delLabel.height = 16;
				delLabel.y = 0;
				delBtn.addChild(delLabel);

				delBtn.x = w - 26;
				delBtn.y = 4;

				delBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(delBg.graphics, 0, 0, 16, 16, 3, 0xb91c1c, 1.0);
						delLabel.textColor = 0xffffff;
					});
				delBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
						UIUtils.drawRoundedRect(delBg.graphics, 0, 0, 16, 16, 3, 0x1e293b, 1.0);
						delLabel.textColor = UIUtils.TEXT_MUTED;
					});
				delBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						e.stopPropagation();
						if (selectedCommandIndex == index) {
							selectedCommandIndex = -1;
						}
						else if (selectedCommandIndex > index) {
							selectedCommandIndex--;
						}
						botEngine.removeCommandAt(index);
						updateMoveButtonsState();
						refreshCommandList();
					});
				row.addChild(delBtn);

				row.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
						if (selectedCommandIndex == index) {
							selectedCommandIndex = -1;
						}
						else {
							selectedCommandIndex = index;
						}
						updateMoveButtonsState();
						refreshCommandList();
					});
			}

			return row;
		}

		private function updateMoveButtonsState():void {
			if (moveUpBtn == null || moveDownBtn == null)
				return;

			var hasSel:Boolean = (selectedCommandIndex >= 0 && selectedCommandIndex < botEngine.commandList.length);
			moveUpBtn.enabled = hasSel && (selectedCommandIndex > 0);
			moveDownBtn.enabled = hasSel && (selectedCommandIndex < botEngine.commandList.length - 1);
		}

		private function onMoveUpClick(e:MouseEvent):void {
			if (selectedCommandIndex > 0) {
				if (botEngine.moveCommandUp(selectedCommandIndex)) {
					selectedCommandIndex--;
					updateMoveButtonsState();
					refreshCommandList();
					commandScroll.ensureVisible(selectedCommandIndex * (24 + 3), 24);
				}
			}
		}

		private function onMoveDownClick(e:MouseEvent):void {
			if (selectedCommandIndex >= 0 && selectedCommandIndex < botEngine.commandList.length - 1) {
				if (botEngine.moveCommandDown(selectedCommandIndex)) {
					selectedCommandIndex++;
					updateMoveButtonsState();
					refreshCommandList();
					commandScroll.ensureVisible(selectedCommandIndex * (24 + 3), 24);
				}
			}
		}

		private function onStartClick(e:MouseEvent):void {
			if (botEngine.isPaused) {
				botEngine.resume();
			}
			else {
				botEngine.start();
			}

			if (AutoQuestUI.instance != null) {
				AutoQuestUI.instance.startAutoQuest();
			}
		}

		private function onPauseClick(e:MouseEvent):void {
			if (botEngine.isRunning) {
				botEngine.pause();
			}
		}

		private function onStopClick(e:MouseEvent):void {
			botEngine.stop();

			if (AutoQuestUI.instance != null) {
				AutoQuestUI.instance.stopAutoQuest();
			}
		}

		private function onClearClick(e:MouseEvent):void {
			if (botEngine.commandList.length == 0) {
				return;
			}

			const confirmDialog:ConfirmationMessage = new ConfirmationMessage(
					"Clear Script",
					"Are you sure you want to remove all commands from the script list?",
					function():void {
						selectedCommandIndex = -1;
						botEngine.clearCommands();
						updateMoveButtonsState();
						refreshCommandList(true);
					},
					null,
					"Clear",
					"Cancel",
					MyButton.TYPE_DANGER
				);

			if (stage != null) {
				stage.addChild(confirmDialog);
			}
			else if (parent != null) {
				parent.addChild(confirmDialog);
			}
		}

		private function onLoadClick(e:MouseEvent):void {
			loadModal.open();
		}

		private function onSaveClick(e:MouseEvent):void {
			saveModal.open();
		}

		private function onBotScriptLoaded(fileName:String):void {
			selectedCommandIndex = -1;
			if (botRepeatCheckbox != null) {
				botRepeatCheckbox.checked = botEngine.loop;
			}
			if (leaveCombatCheckbox != null) {
				leaveCombatCheckbox.checked = botEngine.leaveCombatOnStop;
			}
			if (notifyDropsCheckbox != null) {
				notifyDropsCheckbox.checked = botEngine.notifyItemDrops;
			}
			refreshCommandList(true);
			updateWhitelistStatus();
			if (whitelistModal != null && whitelistModal.visible) {
				whitelistModal.refreshChips();
			}
			if (AutoQuestUI.instance != null && botEngine != null && botEngine.autoQuestList != null) {
				AutoQuestUI.instance.setQuestIds(botEngine.autoQuestList);
			}
		}

		private function onEngineStateChange(state:int):void {
			if (state == BotEngine.STATE_RUNNING) {
				selectedCommandIndex = -1;
				startBtn.enabled = false;
				pauseBtn.enabled = true;
				stopBtn.enabled = true;
				clearBtn.enabled = false;
				moveUpBtn.enabled = false;
				moveDownBtn.enabled = false;

				if (AutoQuestUI.instance != null) {
					AutoQuestUI.instance.startAutoQuest();
				}

				if (statsTimer == null) {
					statsTimer = new Timer(1000);
					statsTimer.addEventListener(TimerEvent.TIMER, onStatsTimerTick, false, 0, true);
				}
				if (!statsTimer.running) {
					statsTimer.start();
				}
			}
			else if (state == BotEngine.STATE_PAUSED) {
				startBtn.enabled = true;
				pauseBtn.enabled = false;
				stopBtn.enabled = true;
				clearBtn.enabled = false;
				moveUpBtn.enabled = false;
				moveDownBtn.enabled = false;
			}
			else // STATE_IDLE
			{
				startBtn.enabled = true;
				pauseBtn.enabled = false;
				stopBtn.enabled = false;
				clearBtn.enabled = true;
				updateMoveButtonsState();

				if (AutoQuestUI.instance != null) {
					AutoQuestUI.instance.stopAutoQuest();
				}

				if (statsTimer != null && statsTimer.running) {
					statsTimer.stop();
				}
			}

			updateBotStats();
			refreshCommandList();
			dispatchEvent(new Event("botStateChange"));
		}

		private function onEngineStepChange(step:int, cmd:BotCommand):void {
			updateBotStats();
			refreshCommandList();
		}

		private function onStatsTimerTick(e:TimerEvent):void {
			updateBotStats();
		}

		private function updateBotStats():void {
			if (botStatsTimeLabel == null || botStatsLoopLabel == null) {
				return;
			}

			const isRunningOrPaused:Boolean = (botEngine.state != BotEngine.STATE_IDLE);

			if (clearBtn != null)
				clearBtn.visible = !isRunningOrPaused;
			if (moveUpBtn != null)
				moveUpBtn.visible = !isRunningOrPaused;
			if (moveDownBtn != null)
				moveDownBtn.visible = !isRunningOrPaused;

			botStatsTimeLabel.visible = isRunningOrPaused;
			botStatsLoopLabel.visible = isRunningOrPaused;

			if (!isRunningOrPaused) {
				botStatsTimeLabel.text = "";
				botStatsLoopLabel.text = "";
				return;
			}

			const timeFormatted:String = Utils.formatDuration(botEngine.runningTimeSeconds);
			const loopCount:int = botEngine.completedLoops;

			if (botEngine.state == BotEngine.STATE_PAUSED) {
				botStatsTimeLabel.textColor = 0xfbbf24;
				botStatsTimeLabel.text = "⏸ Time: " + timeFormatted;
			}
			else {
				botStatsTimeLabel.textColor = 0x34d399;
				botStatsTimeLabel.text = "▶ Time: " + timeFormatted;
			}

			botStatsLoopLabel.text = "Completed: " + loopCount;
		}

		// =========================================================================
		// Whitelist Modal Dialog Handlers
		// =========================================================================
		private function onOpenWhitelistModal(e:MouseEvent):void {
			whitelistModal.open();
		}

		private function onWhitelistChanged():void {
			updateWhitelistStatus();
		}

		private function updateWhitelistStatus():void {
			if (whitelistStatusLabel == null) {
				return;
			}
			const count:int = botEngine.whitelist.length;
			if (count == 0) {
				whitelistStatusLabel.text = "No items whitelisted yet (Auto-accept inactive).";
			}
			else {
				whitelistStatusLabel.text = count + " item" + (count == 1 ? "" : "s") + " configured to auto-accept drops.";
			}
		}

		// =========================================================================
		// Edit Command Modal Dialog Overlay
		// =========================================================================
		private function buildEditModalOverlay():void {
			editModalOverlay = new Sprite();
			editModalOverlay.visible = false;

			// Dimmer
			const dimmer:Shape = new Shape();
			dimmer.graphics.beginFill(0x000000, 0.75);
			dimmer.graphics.drawRoundRect(0, 0, MODAL_W, MODAL_H, 8);
			dimmer.graphics.endFill();
			editModalOverlay.addChild(dimmer);

			// Card
			const boxW:Number = 400;
			const boxH:Number = 260;
			const boxX:Number = int((MODAL_W - boxW) / 2);
			const boxY:Number = int((MODAL_H - boxH) / 2);

			const boxBg:Shape = new Shape();
			UIUtils.drawRoundedRect(boxBg.graphics, boxX, boxY, boxW, boxH, 8, UIUtils.BG_DARK, 0.98, UIUtils.BORDER_NORMAL, 1);
			boxBg.filters = [UIUtils.createShadow()];
			editModalOverlay.addChild(boxBg);

			// Title & Subtitle
			const title:TextField = UIUtils.createLabel("EDIT COMMAND", UIUtils.TEXT_WHITE, 12, true);
			title.x = boxX + 16;
			title.y = boxY + 12;
			editModalOverlay.addChild(title);

			editModalSub = UIUtils.createLabel("", UIUtils.TEXT_DIM, 9.5, false);
			editModalSub.x = boxX + 115;
			editModalSub.y = boxY + 14;
			editModalSub.width = 200;
			editModalOverlay.addChild(editModalSub);

			const closeBtn:CloseButton = new CloseButton();
			closeBtn.x = boxX + boxW - 32;
			closeBtn.y = boxY + 10;
			closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					editModalOverlay.visible = false;
				});
			editModalOverlay.addChild(closeBtn);

			// Divider under header
			const div:Shape = new Shape();
			div.graphics.lineStyle(1, UIUtils.BORDER_SUBTLE, 1);
			div.graphics.moveTo(boxX + 16, boxY + 36);
			div.graphics.lineTo(boxX + boxW - 16, boxY + 36);
			editModalOverlay.addChild(div);

			// Form Container
			editModalFormContainer = new Sprite();
			editModalFormContainer.x = boxX + 16;
			editModalFormContainer.y = boxY + 44;
			editModalOverlay.addChild(editModalFormContainer);

			// Footer Buttons
			const saveEditBtn:MyButton = new MyButton("Save Changes", 100, 26, MyButton.TYPE_PRIMARY, onSaveEditClick);
			saveEditBtn.x = boxX + boxW - 16 - 100;
			saveEditBtn.y = boxY + boxH - 38;
			editModalOverlay.addChild(saveEditBtn);

			const cancelEditBtn:MyButton = new MyButton("Cancel", 64, 26, MyButton.TYPE_MUTED, function(e:MouseEvent):void {
					editModalOverlay.visible = false;
				});
			cancelEditBtn.x = saveEditBtn.x - 70;
			cancelEditBtn.y = boxY + boxH - 38;
			editModalOverlay.addChild(cancelEditBtn);

			addChild(editModalOverlay);
		}

		private function openEditCommandModal(index:int, cmd:BotCommand):void {
			if (cmd == null)
				return;
			editingIndex = index;
			editingCmd = cmd;

			// Clear previous form controls
			while (editModalFormContainer.numChildren > 0) {
				editModalFormContainer.removeChildAt(0);
			}

			editModalSub.text = "#" + (index + 1) + " " + cmd.type.toUpperCase();

			const formW:Number = 368;

			if (cmd is KillCommand) {
				var kcmd:KillCommand = cmd as KillCommand;
				editKillMode = kcmd.killMode;

				var monLbl:TextField = UIUtils.createLabel("Monster Target (* for any):", UIUtils.TEXT_MUTED, 10.5);
				monLbl.y = 0;
				editModalFormContainer.addChild(monLbl);

				editMonInput = new MyTextField(formW, 24);
				editMonInput.y = 18;
				editMonInput.text = kcmd.monster;
				editModalFormContainer.addChild(editMonInput);

				var condLbl:TextField = UIUtils.createLabel("Kill Until:", UIUtils.TEXT_MUTED, 10.5);
				condLbl.y = 50;
				editModalFormContainer.addChild(condLbl);

				var btnW:Number = 110;
				var btnH:Number = 22;

				editKillOnceBtn = new MyButton("Kill Once", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_NONE);
					});
				editKillOnceBtn.y = 68;
				editModalFormContainer.addChild(editKillOnceBtn);

				editKillCountBtn = new MyButton("Kill Count", btnW, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_COUNT);
					});
				editKillCountBtn.x = btnW + 6;
				editKillCountBtn.y = 68;
				editModalFormContainer.addChild(editKillCountBtn);

				editKillItemBtn = new MyButton("Kill for Items", 124, btnH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
						setEditKillMode(KillCommand.MODE_ITEM);
					});
				editKillItemBtn.x = (btnW + 6) * 2;
				editKillItemBtn.y = 68;
				editModalFormContainer.addChild(editKillItemBtn);

				// Kill Count Box
				editKillCountBox = new Sprite();
				editKillCountBox.y = 96;
				var cLbl:TextField = UIUtils.createLabel("Target Kill Count:", UIUtils.TEXT_MUTED, 10.5);
				editKillCountBox.addChild(cLbl);
				editKillCountInput = new MyTextField(100, 24);
				editKillCountInput.y = 18;
				editKillCountInput.text = String(kcmd.killCount);
				editKillCountInput.restrict = "0-9";
				editKillCountBox.addChild(editKillCountInput);
				editModalFormContainer.addChild(editKillCountBox);

				// Kill Item Box
				editKillItemBox = new Sprite();
				editKillItemBox.y = 96;
				var iLbl:TextField = UIUtils.createLabel("Item Name:", UIUtils.TEXT_MUTED, 10.5);
				editKillItemBox.addChild(iLbl);
				editKillItemNameInput = new MyTextField(200, 24);
				editKillItemNameInput.y = 18;
				editKillItemNameInput.text = kcmd.itemName;
				editKillItemBox.addChild(editKillItemNameInput);

				var qLbl:TextField = UIUtils.createLabel("Qty:", UIUtils.TEXT_MUTED, 10.5);
				qLbl.x = 210;
				editKillItemBox.addChild(qLbl);
				editKillItemQtyInput = new MyTextField(70, 24);
				editKillItemQtyInput.x = 210;
				editKillItemQtyInput.y = 18;
				editKillItemQtyInput.text = String(kcmd.itemQty);
				editKillItemQtyInput.restrict = "0-9";
				editKillItemBox.addChild(editKillItemQtyInput);
				editModalFormContainer.addChild(editKillItemBox);

				setEditKillMode(kcmd.killMode);
			}
			else if (cmd is JoinCommand) {
				var jcmd:JoinCommand = cmd as JoinCommand;

				var mapLbl:TextField = UIUtils.createLabel("Map Name:", UIUtils.TEXT_MUTED, 10.5);
				mapLbl.y = 10;
				editModalFormContainer.addChild(mapLbl);

				editMapInput = new MyTextField(formW, 24);
				editMapInput.y = 28;
				editMapInput.text = jcmd.map;
				editModalFormContainer.addChild(editMapInput);

				var cellLbl:TextField = UIUtils.createLabel("Cell:", UIUtils.TEXT_MUTED, 10.5);
				cellLbl.y = 66;
				editModalFormContainer.addChild(cellLbl);

				editCellInput = new MyTextField(160, 24);
				editCellInput.y = 84;
				editCellInput.text = jcmd.cell;
				editModalFormContainer.addChild(editCellInput);

				var padLbl:TextField = UIUtils.createLabel("Pad:", UIUtils.TEXT_MUTED, 10.5);
				padLbl.x = 180;
				padLbl.y = 66;
				editModalFormContainer.addChild(padLbl);

				editPadInput = new MyTextField(160, 24);
				editPadInput.x = 180;
				editPadInput.y = 84;
				editPadInput.text = jcmd.pad;
				editModalFormContainer.addChild(editPadInput);
			}
			else if (cmd is JumpCommand) {
				var jumpCmd:JumpCommand = cmd as JumpCommand;

				var jcLbl:TextField = UIUtils.createLabel("Cell Name:", UIUtils.TEXT_MUTED, 10.5);
				jcLbl.y = 16;
				editModalFormContainer.addChild(jcLbl);

				editCellInput = new MyTextField(formW, 24);
				editCellInput.y = 34;
				editCellInput.text = jumpCmd.cell;
				editModalFormContainer.addChild(editCellInput);

				var jpLbl:TextField = UIUtils.createLabel("Pad Name:", UIUtils.TEXT_MUTED, 10.5);
				jpLbl.y = 72;
				editModalFormContainer.addChild(jpLbl);

				editPadInput = new MyTextField(formW, 24);
				editPadInput.y = 90;
				editPadInput.text = jumpCmd.pad;
				editModalFormContainer.addChild(editPadInput);
			}
			else if (cmd is QuestAcceptCommand) {
				var qacmd:QuestAcceptCommand = cmd as QuestAcceptCommand;

				var qLbl1:TextField = UIUtils.createLabel("Quest ID to Accept:", UIUtils.TEXT_MUTED, 10.5);
				qLbl1.y = 20;
				editModalFormContainer.addChild(qLbl1);

				editQuestIdInput = new MyTextField(180, 24);
				editQuestIdInput.y = 40;
				editQuestIdInput.text = String(qacmd.questId);
				editQuestIdInput.restrict = "0-9";
				editModalFormContainer.addChild(editQuestIdInput);
			}
			else if (cmd is QuestCompleteCommand) {
				var qccmd:QuestCompleteCommand = cmd as QuestCompleteCommand;

				var qLbl2:TextField = UIUtils.createLabel("Quest ID to Turn-In:", UIUtils.TEXT_MUTED, 10.5);
				qLbl2.y = 10;
				editModalFormContainer.addChild(qLbl2);

				editQuestIdInput = new MyTextField(180, 24);
				editQuestIdInput.y = 28;
				editQuestIdInput.text = String(qccmd.questId);
				editQuestIdInput.restrict = "0-9";
				editModalFormContainer.addChild(editQuestIdInput);

				var iLbl2:TextField = UIUtils.createLabel("Item ID (Reward selection, -1 if none):", UIUtils.TEXT_MUTED, 10.5);
				iLbl2.y = 66;
				editModalFormContainer.addChild(iLbl2);

				editQuestItemIdInput = new MyTextField(180, 24);
				editQuestItemIdInput.y = 84;
				editQuestItemIdInput.text = String(qccmd.itemId);
				editQuestItemIdInput.restrict = "0-9\\-";
				editModalFormContainer.addChild(editQuestItemIdInput);
			}
			else if (cmd is DelayCommand) {
				var dcmd:DelayCommand = cmd as DelayCommand;

				var dLbl:TextField = UIUtils.createLabel("Delay Duration (seconds):", UIUtils.TEXT_MUTED, 10.5);
				dLbl.y = 20;
				editModalFormContainer.addChild(dLbl);

				editDelayInput = new MyTextField(180, 24);
				editDelayInput.y = 40;
				editDelayInput.text = String(dcmd.delaySeconds);
				editDelayInput.restrict = "0-9.";
				editModalFormContainer.addChild(editDelayInput);
			}
			else if (cmd is TransferToBankCommand) {
				var tbc:TransferToBankCommand = cmd as TransferToBankCommand;

				var tbLbl:TextField = UIUtils.createLabel("Item Name to Bank:", UIUtils.TEXT_MUTED, 10.5);
				tbLbl.y = 20;
				editModalFormContainer.addChild(tbLbl);

				editItemTransferInput = new MyTextField(formW, 24);
				editItemTransferInput.y = 40;
				editItemTransferInput.text = tbc.itemName;
				editModalFormContainer.addChild(editItemTransferInput);
			}
			else if (cmd is TransferToInventoryCommand) {
				var tic:TransferToInventoryCommand = cmd as TransferToInventoryCommand;

				var tiLbl:TextField = UIUtils.createLabel("Item Name to Inventory:", UIUtils.TEXT_MUTED, 10.5);
				tiLbl.y = 20;
				editModalFormContainer.addChild(tiLbl);

				editItemTransferInput = new MyTextField(formW, 24);
				editItemTransferInput.y = 40;
				editItemTransferInput.text = tic.itemName;
				editModalFormContainer.addChild(editItemTransferInput);
			}
			else if (cmd is NotifCommand) {
				var ncmd:NotifCommand = cmd as NotifCommand;

				var ntLbl:TextField = UIUtils.createLabel("Notification Title:", UIUtils.TEXT_MUTED, 10.5);
				ntLbl.y = 10;
				editModalFormContainer.addChild(ntLbl);

				editNotifTitleInput = new MyTextField(formW, 24);
				editNotifTitleInput.y = 28;
				editNotifTitleInput.text = ncmd.title;
				editModalFormContainer.addChild(editNotifTitleInput);

				var nmLbl:TextField = UIUtils.createLabel("Notification Message:", UIUtils.TEXT_MUTED, 10.5);
				nmLbl.y = 66;
				editModalFormContainer.addChild(nmLbl);

				editNotifMsgInput = new MyTextField(formW, 24);
				editNotifMsgInput.y = 84;
				editNotifMsgInput.text = ncmd.message;
				editModalFormContainer.addChild(editNotifMsgInput);
			}

			editModalOverlay.visible = true;
			setChildIndex(editModalOverlay, numChildren - 1);
		}

		private function setEditKillMode(mode:String):void {
			editKillMode = mode;
			if (editKillOnceBtn != null) {
				editKillOnceBtn.setType(mode == KillCommand.MODE_NONE ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillOnceBtn.active = (mode == KillCommand.MODE_NONE);
			}
			if (editKillCountBtn != null) {
				editKillCountBtn.setType(mode == KillCommand.MODE_COUNT ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillCountBtn.active = (mode == KillCommand.MODE_COUNT);
			}
			if (editKillItemBtn != null) {
				editKillItemBtn.setType(mode == KillCommand.MODE_ITEM ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
				editKillItemBtn.active = (mode == KillCommand.MODE_ITEM);
			}

			if (editKillCountBox != null) {
				editKillCountBox.visible = (mode == KillCommand.MODE_COUNT);
			}
			if (editKillItemBox != null) {
				editKillItemBox.visible = (mode == KillCommand.MODE_ITEM);
			}
		}

		private function onSaveEditClick(e:MouseEvent):void {
			if (editingCmd == null || editingIndex < 0 || editingIndex >= botEngine.commandList.length) {
				editModalOverlay.visible = false;
				return;
			}

			if (editingCmd is KillCommand) {
				var kcmd:KillCommand = editingCmd as KillCommand;
				var mon:String = editMonInput.trimmedText;
				kcmd.monster = (mon.length > 0) ? mon : "*";
				kcmd.killMode = editKillMode;
				if (editKillMode == KillCommand.MODE_COUNT) {
					kcmd.killCount = Math.max(1, parseInt(editKillCountInput.text));
				}
				else if (editKillMode == KillCommand.MODE_ITEM) {
					kcmd.itemName = editKillItemNameInput.trimmedText;
					kcmd.itemQty = Math.max(1, parseInt(editKillItemQtyInput.text));
				}
			}
			else if (editingCmd is JoinCommand) {
				var jcmd:JoinCommand = editingCmd as JoinCommand;
				jcmd.map = editMapInput.trimmedText;
				jcmd.cell = editCellInput.trimmedText.length > 0 ? editCellInput.trimmedText : "Enter";
				jcmd.pad = editPadInput.trimmedText.length > 0 ? editPadInput.trimmedText : "Spawn";
			}
			else if (editingCmd is JumpCommand) {
				var jumpCmd:JumpCommand = editingCmd as JumpCommand;
				jumpCmd.cell = editCellInput.trimmedText.length > 0 ? editCellInput.trimmedText : "Enter";
				jumpCmd.pad = editPadInput.trimmedText.length > 0 ? editPadInput.trimmedText : "Spawn";
			}
			else if (editingCmd is QuestAcceptCommand) {
				var qacmd:QuestAcceptCommand = editingCmd as QuestAcceptCommand;
				var qid:int = parseInt(editQuestIdInput.text);
				if (qid > 0) {
					qacmd.questId = qid;
				}
			}
			else if (editingCmd is QuestCompleteCommand) {
				var qccmd:QuestCompleteCommand = editingCmd as QuestCompleteCommand;
				var qid2:int = parseInt(editQuestIdInput.text);
				if (qid2 > 0) {
					qccmd.questId = qid2;
				}
				qccmd.itemId = parseInt(editQuestItemIdInput.text);
			}
			else if (editingCmd is DelayCommand) {
				var dcmd:DelayCommand = editingCmd as DelayCommand;
				var s:Number = parseFloat(editDelayInput.text);
				if (!isNaN(s) && s > 0) {
					dcmd.delaySeconds = s;
				}
			}
			else if (editingCmd is TransferToBankCommand) {
				var tbcmd:TransferToBankCommand = editingCmd as TransferToBankCommand;
				var iname1:String = editItemTransferInput.trimmedText;
				if (iname1.length > 0) {
					tbcmd.itemName = iname1;
				}
			}
			else if (editingCmd is TransferToInventoryCommand) {
				var ticmd:TransferToInventoryCommand = editingCmd as TransferToInventoryCommand;
				var iname2:String = editItemTransferInput.trimmedText;
				if (iname2.length > 0) {
					ticmd.itemName = iname2;
				}
			}
			else if (editingCmd is NotifCommand) {
				var ncmdEdit:NotifCommand = editingCmd as NotifCommand;
				var tText:String = editNotifTitleInput.trimmedText;
				var mText:String = editNotifMsgInput.trimmedText;
				if (tText.length > 0) {
					ncmdEdit.title = tText;
				}
				ncmdEdit.message = mText;
			}

			editModalOverlay.visible = false;
			refreshCommandList();
		}

		public function toggle():void {
			this.visible = !this.visible;
			if (this.visible) {
				if (botRepeatCheckbox != null) {
					botRepeatCheckbox.checked = botEngine.loop;
				}
				if (leaveCombatCheckbox != null) {
					leaveCombatCheckbox.checked = botEngine.leaveCombatOnStop;
				}
				if (notifyDropsCheckbox != null) {
					notifyDropsCheckbox.checked = botEngine.notifyItemDrops;
				}
				updateBotStats();
				centerOnStage();
				if (parent != null) {
					parent.setChildIndex(this, parent.numChildren - 1);
				}
			}
		}
	}
}
