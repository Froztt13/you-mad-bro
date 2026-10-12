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
					{label: IsQuestAvailableCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_QUEST_AVAILABLE},
					{label: IsQuestNotAvailableCommand.COMMAND_LABEL, value: BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE},
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
				case BotCommand.TYPE_IS_QUEST_AVAILABLE:
					return IsQuestAvailableCommand.fromJSON(data);
				case BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE:
					return IsQuestNotAvailableCommand.fromJSON(data);
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
				case BotCommand.TYPE_IS_QUEST_AVAILABLE:
					var qId1:int = parseInt(var1);
					return new IsQuestAvailableCommand(qId1);
				case BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE:
					var qId2:int = parseInt(var1);
					return new IsQuestNotAvailableCommand(qId2);
				case BotCommand.TYPE_IS_PLAYER_MEMBER:
					return new IsPlayerMemberCommand();
				default:
					return null;
			}
		}
	}
}
