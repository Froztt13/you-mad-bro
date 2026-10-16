package input.bot_manager {

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;

	import commands.BotCommand;
	import engine.BotEngine;
	import input.AutoQuestUI;
	import input.bot_manager.modals.*;
	import input.bot_manager.tabs.*;
	import ui.BaseModal;
	import ui.ConfirmationMessage;
	import ui.MyButton;
	import ui.ScrollContainer;
	import ui.UIUtils;
	import Config;
	import Utils;
	import com.aqw.battery.BatteryOptimizer;

	public class BotManagerUI extends BaseModal {

		public static var instance:BotManagerUI;

		public static const MODAL_W:Number = 620;
		public static const MODAL_H:Number = 380;
		public static const COL_LEFT_W:Number = 236;
		public static const COL_RIGHT_X:Number = 260;
		public static const COL_RIGHT_W:Number = MODAL_W - COL_RIGHT_X - BaseModal.PADDING; // 348

		public var game:Object;
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

		// Right Column: Tab Buttons
		private var tabCombatBtn:MyButton;
		private var tabQuestBtn:MyButton;
		private var tabMapBtn:MyButton;
		private var tabItemBtn:MyButton;
		private var tabMiscBtn:MyButton;
		private var tabSettingsBtn:MyButton;

		// Right Column: Tab Viewports
		private var tabContentContainer:Sprite;
		private var combatTab:BotCombatTab;
		private var questTab:BotQuestTab;
		private var mapTab:BotMapTab;
		private var itemTab:BotItemTab;
		private var miscTab:BotMiscTab;
		private var settingsTab:BotSettingsTab;
		private var currentTab:int = 0; // 0=Combat, 1=Quest, 2=Map, 3=Item, 4=Misc, 5=Settings

		// Modals
		private var loadModal:BotLoadModal;
		private var saveModal:BotSaveModal;
		private var whitelistModal:BotWhitelistModal;
		private var labelsModal:BotLabelsModal;
		private var editModal:BotEditCommandModal;
		private var conditionsModal:BotConditionsModal;

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

			// Initialize Modals
			loadModal = new BotLoadModal(botEngine, onBotScriptLoaded);
			addChild(loadModal);

			saveModal = new BotSaveModal(botEngine);
			addChild(saveModal);

			whitelistModal = new BotWhitelistModal(botEngine, onWhitelistChanged);
			addChild(whitelistModal);

			labelsModal = new BotLabelsModal(botEngine, onLabelSelected);
			addChild(labelsModal);

			conditionsModal = new BotConditionsModal(onConditionSelected);
			addChild(conditionsModal);

			editModal = new BotEditCommandModal(botEngine, function():void {
					refreshCommandList();
				});
			addChild(editModal);

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

			const toolbarH:Number = 26;
			const toolbarY:Number = MODAL_H - BaseModal.PADDING - toolbarH; // 342
			const scrollH:Number = toolbarY - (topY + 18) - 8; // 270

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

			const rightAreaX:Number = leftX + (34 + gap) * 3;
			const rightAreaW:Number = (leftX + COL_LEFT_W) - rightAreaX;

			clearBtn = new MyButton("Clear", 44, 26, MyButton.TYPE_MUTED, onClearClick, 10);
			clearBtn.x = rightAreaX;
			clearBtn.y = toolbarY;
			addChild(clearBtn);

			moveUpBtn = new MyButton("▲", 34, 26, MyButton.TYPE_SECONDARY, onMoveUpClick, 11);
			moveUpBtn.x = rightAreaX + 44 + gap;
			moveUpBtn.y = toolbarY;
			moveUpBtn.enabled = false;
			addChild(moveUpBtn);

			moveDownBtn = new MyButton("▼", 34, 26, MyButton.TYPE_SECONDARY, onMoveDownClick, 11);
			moveDownBtn.x = rightAreaX + 44 + gap + 34 + gap;
			moveDownBtn.y = toolbarY;
			moveDownBtn.enabled = false;
			addChild(moveDownBtn);

			// Running Time & Completed Loops Status Info
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

			tabCombatBtn = new MyButton("Combat", 50, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(0);
				});
			tabCombatBtn.x = COL_RIGHT_X;
			tabCombatBtn.y = topY;
			addChild(tabCombatBtn);

			tabQuestBtn = new MyButton("Quest", 46, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(1);
				});
			tabQuestBtn.x = tabCombatBtn.x + 50 + gap;
			tabQuestBtn.y = topY;
			addChild(tabQuestBtn);

			tabMapBtn = new MyButton("Map", 42, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(2);
				});
			tabMapBtn.x = tabQuestBtn.x + 46 + gap;
			tabMapBtn.y = topY;
			addChild(tabMapBtn);

			tabItemBtn = new MyButton("Item", 42, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(3);
				});
			tabItemBtn.x = tabMapBtn.x + 42 + gap;
			tabItemBtn.y = topY;
			addChild(tabItemBtn);

			tabMiscBtn = new MyButton("Misc", 44, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(4);
				});
			tabMiscBtn.x = tabItemBtn.x + 42 + gap;
			tabMiscBtn.y = topY;
			addChild(tabMiscBtn);

			tabSettingsBtn = new MyButton("Settings", 58, tabH, MyButton.TYPE_SECONDARY, function(e:MouseEvent):void {
					switchTab(5);
				});
			tabSettingsBtn.x = tabMiscBtn.x + 44 + gap;
			tabSettingsBtn.y = topY;
			addChild(tabSettingsBtn);

			tabContentContainer = new Sprite();
			tabContentContainer.x = COL_RIGHT_X;
			tabContentContainer.y = topY + tabH + 8; // 78
			addChild(tabContentContainer);

			const frameBg:Shape = new Shape();
			const frameH:Number = MODAL_H - tabContentContainer.y - BaseModal.PADDING; // 290
			UIUtils.drawRoundedRect(frameBg.graphics, 0, 0, COL_RIGHT_W, frameH, 6, UIUtils.BG_RECESSED, 0.6, UIUtils.BORDER_SUBTLE, 1);
			tabContentContainer.addChild(frameBg);

			// Instantiate Tab Components
			combatTab = new BotCombatTab(this);
			tabContentContainer.addChild(combatTab);

			questTab = new BotQuestTab(this);
			tabContentContainer.addChild(questTab);

			mapTab = new BotMapTab(this);
			tabContentContainer.addChild(mapTab);

			itemTab = new BotItemTab(this);
			tabContentContainer.addChild(itemTab);

			miscTab = new BotMiscTab(this);
			tabContentContainer.addChild(miscTab);

			settingsTab = new BotSettingsTab(this);
			tabContentContainer.addChild(settingsTab);
		}

		public function switchTab(index:int):void {
			currentTab = index;

			tabCombatBtn.setType(index == 0 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabQuestBtn.setType(index == 1 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabMapBtn.setType(index == 2 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabItemBtn.setType(index == 3 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabMiscBtn.setType(index == 4 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);
			tabSettingsBtn.setType(index == 5 ? MyButton.TYPE_PRIMARY : MyButton.TYPE_SECONDARY);

			tabCombatBtn.active = (index == 0);
			tabQuestBtn.active = (index == 1);
			tabMapBtn.active = (index == 2);
			tabItemBtn.active = (index == 3);
			tabMiscBtn.active = (index == 4);
			tabSettingsBtn.active = (index == 5);

			combatTab.visible = (index == 0);
			questTab.visible = (index == 1);
			mapTab.visible = (index == 2);
			itemTab.visible = (index == 3);
			miscTab.visible = (index == 4);
			settingsTab.visible = (index == 5);

			if (index == 3 && itemTab != null) {
				itemTab.updateWhitelistStatus();
			}
		}

		// =========================================================================
		// Modal Opener Methods
		// =========================================================================
		public function openLoadModal():void {
			if (loadModal != null) {
				loadModal.open();
			}
		}

		public function openSaveModal():void {
			if (saveModal != null) {
				saveModal.open();
			}
		}

		public function openWhitelistModal():void {
			if (whitelistModal != null) {
				whitelistModal.open();
			}
		}

		public function openCurrentLabelsModal():void {
			if (labelsModal != null) {
				labelsModal.open();
			}
		}

		public function openConditionsModal():void {
			if (conditionsModal != null) {
				var curType:String = (miscTab != null) ? miscTab.selectedConditionType : null;
				conditionsModal.open(curType);
			}
		}

		public function openEditCommandModal(index:int, cmd:BotCommand):void {
			if (editModal != null) {
				editModal.open(index, cmd);
			}
		}

		private function onLabelSelected(labelName:String):void {
			if (miscTab != null) {
				miscTab.setLabelText(labelName);
			}
		}

		private function onConditionSelected(condType:String):void {
			if (miscTab != null) {
				miscTab.setSelectedCondition(condType);
			}
		}

		private function onWhitelistChanged():void {
			if (itemTab != null) {
				itemTab.updateWhitelistStatus();
			}
		}

		private function onBotScriptLoaded(fileName:String):void {
			selectedCommandIndex = -1;
			if (settingsTab != null) {
				settingsTab.updateCheckboxes();
			}
			if (itemTab != null) {
				itemTab.updateCheckboxes();
				itemTab.updateWhitelistStatus();
			}
			refreshCommandList(true);
			if (whitelistModal != null && whitelistModal.visible) {
				whitelistModal.refreshChips();
			}
			if (AutoQuestUI.instance != null && botEngine != null && botEngine.autoQuestList != null) {
				AutoQuestUI.instance.setQuestIds(botEngine.autoQuestList);
			}
		}

		// =========================================================================
		// Script Commands Manipulation
		// =========================================================================
		public function addBotCommand(cmd:BotCommand):void {
			if (cmd == null)
				return;

			var hasSelection:Boolean = (selectedCommandIndex >= 0 && selectedCommandIndex < botEngine.commandList.length);
			if (hasSelection) {
				var targetIndex:int = selectedCommandIndex + 1;
				botEngine.insertCommand(targetIndex, cmd);
				selectedCommandIndex = targetIndex;
				refreshCommandList();
				commandScroll.ensureVisible(targetIndex * (24 + 3), 24);
			}
			else {
				botEngine.addCommand(cmd);
				refreshCommandList();
				commandScroll.scrollToBottom();
			}
		}

		public function refreshCommandList(resetScroll:Boolean = false):void {
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

		public function toggle():void {
			this.visible = !this.visible;
			if (this.visible) {
				if (settingsTab != null) {
					settingsTab.updateCheckboxes();
				}
				if (itemTab != null) {
					itemTab.updateCheckboxes();
					itemTab.updateWhitelistStatus();
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
