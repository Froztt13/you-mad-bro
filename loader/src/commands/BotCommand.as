package commands {

	import engine.BotEngine;
	import commands.conditions.BaseConditionalCommand;

	public class BotCommand {

		public static const TYPE_KILL:String = "kill";
		public static const TYPE_HUNT:String = "hunt";
		public static const TYPE_JOIN:String = "join";
		public static const TYPE_JUMP:String = "jump";
		public static const TYPE_QUEST_ACCEPT:String = "quest_accept";
		public static const TYPE_QUEST_COMPLETE:String = "quest_complete";
		public static const TYPE_DELAY:String = "delay";
		public static const TYPE_TRANSFER_TO_BANK:String = "transfer_to_bank";
		public static const TYPE_TRANSFER_TO_INVENTORY:String = "transfer_to_inventory";
		public static const TYPE_NOTIF:String = "notif";
		public static const TYPE_LABEL:String = "label";
		public static const TYPE_GOTO_LABEL:String = "goto_label";
		public static const TYPE_RESTART_BOT:String = "restart_bot";
		public static const TYPE_STOP_BOT:String = "stop_bot";
		public static const TYPE_WALK:String = "walk";
		public static const TYPE_EQUIP_ITEM:String = "equip_item";
		public static const TYPE_GET_MAP_ITEM:String = "get_map_item";
		public static const TYPE_BUY_ITEM:String = "buy_item";

		public static const TYPE_IS_ITEM_IN_INV:String = "is_item_in_inventory";
		public static const TYPE_IS_ITEM_NOT_IN_INV:String = "is_item_not_in_inventory";
		public static const TYPE_IS_ITEM_EQUIPED:String = "is_item_equiped";
		public static const TYPE_IS_ITEM_NOT_EQUIPED:String = "is_item_not_equiped";
		public static const TYPE_IS_QUEST_AVAILABLE:String = "is_quest_available";
		public static const TYPE_IS_QUEST_NOT_AVAILABLE:String = "is_quest_not_available";
		public static const TYPE_IS_QUEST_CAN_BE_TURNED_IN:String = "is_quest_can_be_turned_in";
		public static const TYPE_IS_GOLD_GREATER:String = "is_gold_greater";
		public static const TYPE_IS_GOLD_LESS:String = "is_gold_less";
		public static const TYPE_IS_MAP:String = "is_map";
		public static const TYPE_IS_MAP_NOT:String = "is_map_not";
		public static const TYPE_IS_CELL:String = "is_cell";
		public static const TYPE_IS_CELL_NOT:String = "is_cell_not";
		public static const TYPE_IS_PLAYER_MEMBER:String = "is_player_member";

		public var type:String;

		public function BotCommand(type:String) {
			this.type = type;
		}

		public function toJSON():Object {
			return {"type": type};
		}

		public static function fromJSON(data:Object):BotCommand {
			if (data == null || data.type == null)
				return null;
			switch (String(data.type)) {
				case TYPE_KILL:
					return KillCommand.fromJSON(data);
				case TYPE_HUNT:
					return HuntCommand.fromJSON(data);
				case TYPE_JOIN:
					return JoinCommand.fromJSON(data);
				case TYPE_JUMP:
					return JumpCommand.fromJSON(data);
				case TYPE_WALK:
					return WalkCommand.fromJSON(data);
				case TYPE_EQUIP_ITEM:
					return EquipItemCommand.fromJSON(data);
				case TYPE_GET_MAP_ITEM:
					return GetMapItemCommand.fromJSON(data);
				case TYPE_BUY_ITEM:
					return BuyItemCommand.fromJSON(data);
				case TYPE_QUEST_ACCEPT:
					return QuestAcceptCommand.fromJSON(data);
				case TYPE_QUEST_COMPLETE:
					return QuestCompleteCommand.fromJSON(data);
				case TYPE_DELAY:
					return DelayCommand.fromJSON(data);
				case TYPE_TRANSFER_TO_BANK:
					return TransferToBankCommand.fromJSON(data);
				case TYPE_TRANSFER_TO_INVENTORY:
					return TransferToInventoryCommand.fromJSON(data);
				case TYPE_NOTIF:
					return NotifCommand.fromJSON(data);
				case TYPE_LABEL:
					return LabelCommand.fromJSON(data);
				case TYPE_GOTO_LABEL:
					return GotoLabelCommand.fromJSON(data);
				case TYPE_RESTART_BOT:
					return RestartBotCommand.fromJSON(data);
				case TYPE_STOP_BOT:
					return StopBotCommand.fromJSON(data);

				case TYPE_IS_ITEM_IN_INV:
				case TYPE_IS_ITEM_NOT_IN_INV:
				case TYPE_IS_ITEM_EQUIPED:
				case TYPE_IS_ITEM_NOT_EQUIPED:
				case TYPE_IS_QUEST_AVAILABLE:
				case TYPE_IS_QUEST_NOT_AVAILABLE:
				case TYPE_IS_QUEST_CAN_BE_TURNED_IN:
				case TYPE_IS_GOLD_GREATER:
				case TYPE_IS_GOLD_LESS:
				case TYPE_IS_MAP:
				case TYPE_IS_MAP_NOT:
				case TYPE_IS_CELL:
				case TYPE_IS_CELL_NOT:
				case TYPE_IS_PLAYER_MEMBER:
					return BaseConditionalCommand.fromJSON(data);
				default:
					if (BaseConditionalCommand.isConditionType(String(data.type))) {
						return BaseConditionalCommand.fromJSON(data);
					}
					return null;
			}
		}

		public function execute(bot:BotEngine):void {
			bot.advanceStep();
		}

		public function toString():String {
			return "Command [" + type + "]";
		}
	}
}
