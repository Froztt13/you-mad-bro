package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;

	/**
	 * Abstract base class for conditional bot commands.
	 * Evaluates a state condition returning boolean.
	 * If true: continues execution sequentially to the next command.
	 * If false: skips 1 command immediately after this command.
	 */
	public class BaseConditionalCommand extends BotCommand {

		public var var1:String = "";
		public var var2:String = "";

		public function BaseConditionalCommand(type:String, var1:String = "", var2:String = "") {
			super(type);
			this.var1 = (var1 != null) ? var1 : "";
			this.var2 = (var2 != null) ? var2 : "";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"var1": var1,
					"var2": var2
				};
		}

		/**
		 * Subclasses should override this method to evaluate their condition.
		 * Return true to execute next command, or false to skip the next command.
		 */
		public function checkCondition(bot:BotEngine):Boolean {
			return false;
		}

		override public function execute(bot:BotEngine):void {
			var passed:Boolean = false;
			try {
				passed = checkCondition(bot);
			}
			catch (e:Error) {
				bot.log("[" + toString() + "] Condition evaluation error: " + e.message);
				passed = false;
			}

			if (passed) {
				bot.log("[" + toString() + "] Condition MET (true). Executing next command.");
				bot.advanceStep(100);
			}
			else {
				bot.log("[" + toString() + "] Condition NOT met (false). Skipping next command.");
				bot.skipNextStep(100);
			}
		}

		/**
		 * Human-readable display label for this conditional command.
		 */
		public function get commandLabel():String {
			return "Conditional";
		}

		/**
		 * UI metadata for var1 & var2 (Single Source of Truth).
		 * If a label is empty or null, that variable is not used and the UI will hide it.
		 */
		public function get var1Label():String {
			return "";
		}

		public function get var1Restrict():String {
			return null;
		}

		public function get var1Default():String {
			return "";
		}

		public function get var2Label():String {
			return "";
		}

		public function get var2Restrict():String {
			return null;
		}

		public function get var2Default():String {
			return "";
		}

		override public function toString():String {
			return commandLabel + " (" + var1 + (var2 != "" ? ", " + var2 : "") + ")";
		}

		// =========================================================================
		// Registry & Metadata Helpers for UI
		// =========================================================================

		public static function getAvailableConditions():Array {
			return [
					{label: IsItemInInventoryCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_ITEM_IN_INV},
					{label: IsItemNotInInventoryCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_ITEM_NOT_IN_INV},
					{label: IsItemEquipedCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_ITEM_EQUIPED},
					{label: IsItemNotEquipedCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_ITEM_NOT_EQUIPED},
					{label: IsQuestAvailableCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_QUEST_AVAILABLE},
					{label: IsQuestNotAvailableCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE},
					{label: IsQuestCanBeTurnedInCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_QUEST_CAN_BE_TURNED_IN},
					{label: IsGoldGreaterThanCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_GOLD_GREATER},
					{label: IsGoldLessThanCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_GOLD_LESS},
					{label: IsMapCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_MAP},
					{label: IsMapNotCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_MAP_NOT},
					{label: IsCellCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_CELL},
					{label: IsCellNotCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_CELL_NOT},
					{label: IsPlayerMemberCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_PLAYER_MEMBER}
				];
		}

		public static function getDefinition(type:String):Object {
			switch (type) {
				case BotCommand.TYPE_IS_ITEM_IN_INV:
					return {
							type: type,
							label: IsItemInInventoryCommand.COMMAND_LABEL,
							var1Label: IsItemInInventoryCommand.VAR1_LABEL,
							var1Restrict: IsItemInInventoryCommand.VAR1_RESTRICT,
							var1Default: IsItemInInventoryCommand.VAR1_DEFAULT,
							var2Label: IsItemInInventoryCommand.VAR2_LABEL,
							var2Restrict: IsItemInInventoryCommand.VAR2_RESTRICT,
							var2Default: IsItemInInventoryCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_ITEM_NOT_IN_INV:
					return {
							type: type,
							label: IsItemNotInInventoryCommand.COMMAND_LABEL,
							var1Label: IsItemNotInInventoryCommand.VAR1_LABEL,
							var1Restrict: IsItemNotInInventoryCommand.VAR1_RESTRICT,
							var1Default: IsItemNotInInventoryCommand.VAR1_DEFAULT,
							var2Label: IsItemNotInInventoryCommand.VAR2_LABEL,
							var2Restrict: IsItemNotInInventoryCommand.VAR2_RESTRICT,
							var2Default: IsItemNotInInventoryCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_ITEM_EQUIPED:
					return {
							type: type,
							label: IsItemEquipedCommand.COMMAND_LABEL,
							var1Label: IsItemEquipedCommand.VAR1_LABEL,
							var1Restrict: IsItemEquipedCommand.VAR1_RESTRICT,
							var1Default: IsItemEquipedCommand.VAR1_DEFAULT,
							var2Label: IsItemEquipedCommand.VAR2_LABEL,
							var2Restrict: IsItemEquipedCommand.VAR2_RESTRICT,
							var2Default: IsItemEquipedCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_ITEM_NOT_EQUIPED:
					return {
							type: type,
							label: IsItemNotEquipedCommand.COMMAND_LABEL,
							var1Label: IsItemNotEquipedCommand.VAR1_LABEL,
							var1Restrict: IsItemNotEquipedCommand.VAR1_RESTRICT,
							var1Default: IsItemNotEquipedCommand.VAR1_DEFAULT,
							var2Label: IsItemNotEquipedCommand.VAR2_LABEL,
							var2Restrict: IsItemNotEquipedCommand.VAR2_RESTRICT,
							var2Default: IsItemNotEquipedCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_QUEST_AVAILABLE:
					return {
							type: type,
							label: IsQuestAvailableCommand.COMMAND_LABEL,
							var1Label: IsQuestAvailableCommand.VAR1_LABEL,
							var1Restrict: IsQuestAvailableCommand.VAR1_RESTRICT,
							var1Default: IsQuestAvailableCommand.VAR1_DEFAULT,
							var2Label: IsQuestAvailableCommand.VAR2_LABEL,
							var2Restrict: IsQuestAvailableCommand.VAR2_RESTRICT,
							var2Default: IsQuestAvailableCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE:
					return {
							type: type,
							label: IsQuestNotAvailableCommand.COMMAND_LABEL,
							var1Label: IsQuestNotAvailableCommand.VAR1_LABEL,
							var1Restrict: IsQuestNotAvailableCommand.VAR1_RESTRICT,
							var1Default: IsQuestNotAvailableCommand.VAR1_DEFAULT,
							var2Label: IsQuestNotAvailableCommand.VAR2_LABEL,
							var2Restrict: IsQuestNotAvailableCommand.VAR2_RESTRICT,
							var2Default: IsQuestNotAvailableCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_QUEST_CAN_BE_TURNED_IN:
					return {
							type: type,
							label: IsQuestCanBeTurnedInCommand.COMMAND_LABEL,
							var1Label: IsQuestCanBeTurnedInCommand.VAR1_LABEL,
							var1Restrict: IsQuestCanBeTurnedInCommand.VAR1_RESTRICT,
							var1Default: IsQuestCanBeTurnedInCommand.VAR1_DEFAULT,
							var2Label: IsQuestCanBeTurnedInCommand.VAR2_LABEL,
							var2Restrict: IsQuestCanBeTurnedInCommand.VAR2_RESTRICT,
							var2Default: IsQuestCanBeTurnedInCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_GOLD_GREATER:
					return {
							type: type,
							label: IsGoldGreaterThanCommand.COMMAND_LABEL,
							var1Label: IsGoldGreaterThanCommand.VAR1_LABEL,
							var1Restrict: IsGoldGreaterThanCommand.VAR1_RESTRICT,
							var1Default: IsGoldGreaterThanCommand.VAR1_DEFAULT,
							var2Label: IsGoldGreaterThanCommand.VAR2_LABEL,
							var2Restrict: IsGoldGreaterThanCommand.VAR2_RESTRICT,
							var2Default: IsGoldGreaterThanCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_GOLD_LESS:
					return {
							type: type,
							label: IsGoldLessThanCommand.COMMAND_LABEL,
							var1Label: IsGoldLessThanCommand.VAR1_LABEL,
							var1Restrict: IsGoldLessThanCommand.VAR1_RESTRICT,
							var1Default: IsGoldLessThanCommand.VAR1_DEFAULT,
							var2Label: IsGoldLessThanCommand.VAR2_LABEL,
							var2Restrict: IsGoldLessThanCommand.VAR2_RESTRICT,
							var2Default: IsGoldLessThanCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_MAP:
					return {
							type: type,
							label: IsMapCommand.COMMAND_LABEL,
							var1Label: IsMapCommand.VAR1_LABEL,
							var1Restrict: IsMapCommand.VAR1_RESTRICT,
							var1Default: IsMapCommand.VAR1_DEFAULT,
							var2Label: IsMapCommand.VAR2_LABEL,
							var2Restrict: IsMapCommand.VAR2_RESTRICT,
							var2Default: IsMapCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_MAP_NOT:
					return {
							type: type,
							label: IsMapNotCommand.COMMAND_LABEL,
							var1Label: IsMapNotCommand.VAR1_LABEL,
							var1Restrict: IsMapNotCommand.VAR1_RESTRICT,
							var1Default: IsMapNotCommand.VAR1_DEFAULT,
							var2Label: IsMapNotCommand.VAR2_LABEL,
							var2Restrict: IsMapNotCommand.VAR2_RESTRICT,
							var2Default: IsMapNotCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_CELL:
					return {
							type: type,
							label: IsCellCommand.COMMAND_LABEL,
							var1Label: IsCellCommand.VAR1_LABEL,
							var1Restrict: IsCellCommand.VAR1_RESTRICT,
							var1Default: IsCellCommand.VAR1_DEFAULT,
							var2Label: IsCellCommand.VAR2_LABEL,
							var2Restrict: IsCellCommand.VAR2_RESTRICT,
							var2Default: IsCellCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_CELL_NOT:
					return {
							type: type,
							label: IsCellNotCommand.COMMAND_LABEL,
							var1Label: IsCellNotCommand.VAR1_LABEL,
							var1Restrict: IsCellNotCommand.VAR1_RESTRICT,
							var1Default: IsCellNotCommand.VAR1_DEFAULT,
							var2Label: IsCellNotCommand.VAR2_LABEL,
							var2Restrict: IsCellNotCommand.VAR2_RESTRICT,
							var2Default: IsCellNotCommand.VAR2_DEFAULT
						};
				case BotCommand.TYPE_IS_PLAYER_MEMBER:
					return {
							type: type,
							label: IsPlayerMemberCommand.COMMAND_LABEL,
							var1Label: IsPlayerMemberCommand.VAR1_LABEL,
							var1Restrict: IsPlayerMemberCommand.VAR1_RESTRICT,
							var1Default: IsPlayerMemberCommand.VAR1_DEFAULT,
							var2Label: IsPlayerMemberCommand.VAR2_LABEL,
							var2Restrict: IsPlayerMemberCommand.VAR2_RESTRICT,
							var2Default: IsPlayerMemberCommand.VAR2_DEFAULT
						};
				default:
					return null;
			}
		}

		public static function isConditionType(type:String):Boolean {
			return getDefinition(type) != null;
		}

		public static function fromJSON(data:Object):BaseConditionalCommand {
			if (data == null || data.type == null)
				return null;
			var type:String = String(data.type);
			switch (type) {
				case BotCommand.TYPE_IS_ITEM_IN_INV:
					return IsItemInInventoryCommand.fromJSON(data);
				case BotCommand.TYPE_IS_ITEM_NOT_IN_INV:
					return IsItemNotInInventoryCommand.fromJSON(data);
				case BotCommand.TYPE_IS_ITEM_EQUIPED:
					return IsItemEquipedCommand.fromJSON(data);
				case BotCommand.TYPE_IS_ITEM_NOT_EQUIPED:
					return IsItemNotEquipedCommand.fromJSON(data);
				case BotCommand.TYPE_IS_QUEST_AVAILABLE:
					return IsQuestAvailableCommand.fromJSON(data);
				case BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE:
					return IsQuestNotAvailableCommand.fromJSON(data);
				case BotCommand.TYPE_IS_QUEST_CAN_BE_TURNED_IN:
					return IsQuestCanBeTurnedInCommand.fromJSON(data);
				case BotCommand.TYPE_IS_GOLD_GREATER:
					return IsGoldGreaterThanCommand.fromJSON(data);
				case BotCommand.TYPE_IS_GOLD_LESS:
					return IsGoldLessThanCommand.fromJSON(data);
				case BotCommand.TYPE_IS_MAP:
					return IsMapCommand.fromJSON(data);
				case BotCommand.TYPE_IS_MAP_NOT:
					return IsMapNotCommand.fromJSON(data);
				case BotCommand.TYPE_IS_CELL:
					return IsCellCommand.fromJSON(data);
				case BotCommand.TYPE_IS_CELL_NOT:
					return IsCellNotCommand.fromJSON(data);
				case BotCommand.TYPE_IS_PLAYER_MEMBER:
					return IsPlayerMemberCommand.fromJSON(data);
				default:
					return null;
			}
		}

		public static function createCommand(type:String, var1:String, var2:String):BaseConditionalCommand {
			switch (type) {
				case BotCommand.TYPE_IS_ITEM_IN_INV:
					var qty1:int = parseInt(var2);
					if (isNaN(qty1) || qty1 <= 0) {
						qty1 = 1;
					}
					return new IsItemInInventoryCommand(var1, qty1);
				case BotCommand.TYPE_IS_ITEM_NOT_IN_INV:
					var qty2:int = parseInt(var2);
					if (isNaN(qty2) || qty2 <= 0) {
						qty2 = 1;
					}
					return new IsItemNotInInventoryCommand(var1, qty2);
				case BotCommand.TYPE_IS_ITEM_EQUIPED:
					return new IsItemEquipedCommand(var1);
				case BotCommand.TYPE_IS_ITEM_NOT_EQUIPED:
					return new IsItemNotEquipedCommand(var1);
				case BotCommand.TYPE_IS_QUEST_AVAILABLE:
					var qId1:int = parseInt(var1);
					return new IsQuestAvailableCommand(qId1);
				case BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE:
					var qId2:int = parseInt(var1);
					return new IsQuestNotAvailableCommand(qId2);
				case BotCommand.TYPE_IS_QUEST_CAN_BE_TURNED_IN:
					var qId3:int = parseInt(var1);
					return new IsQuestCanBeTurnedInCommand(qId3);
				case BotCommand.TYPE_IS_GOLD_GREATER:
					var gAmt1:int = parseInt(var1);
					return new IsGoldGreaterThanCommand(gAmt1);
				case BotCommand.TYPE_IS_GOLD_LESS:
					var gAmt2:int = parseInt(var1);
					return new IsGoldLessThanCommand(gAmt2);
				case BotCommand.TYPE_IS_MAP:
					return new IsMapCommand(var1);
				case BotCommand.TYPE_IS_MAP_NOT:
					return new IsMapNotCommand(var1);
				case BotCommand.TYPE_IS_CELL:
					return new IsCellCommand(var1);
				case BotCommand.TYPE_IS_CELL_NOT:
					return new IsCellNotCommand(var1);
				case BotCommand.TYPE_IS_PLAYER_MEMBER:
					return new IsPlayerMemberCommand();
				default:
					return null;
			}
		}
	}
}
