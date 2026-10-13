package engine {
    import flash.display.DisplayObject;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    public class MapCommands {

        private var game:Object;
        private var padCorrectionTimer:Timer;
        private var targetJumpCell:String = "";
        private var targetJumpPad:String = "";

        public function MapCommands(game:Object) {
            this.game = game;
        }

        public function setSpawnPoint():void {
            if (game != null && game.world != null) {
                game.world.setSpawnPoint(game.world.strFrame, game.world.strPad);
            }
        }

        public function jump(cell:String, pad:String = "Left"):void {
            if (game != null && game.world != null) {
                game.world.moveToCell(cell, pad);
            }
        }

        public function smartJump(cell:String, pad:String = null):void {
            if (cell == null || cell.length == 0)
                return;

            var curCell:String = getMyCell();
            var availPads:Array = getAvailablePads();

            var isWildcard:Boolean = (pad == null || pad.length == 0 || pad == "*");
            var targetPad:String = (!isWildcard) ? pad : "";

            // If already in target cell and available pads are known
            if (curCell != null && curCell.toLowerCase() == cell.toLowerCase() && availPads != null && availPads.length > 0) {
                stopPadCorrection();
                if (targetPad != "" && isPadInAvailable(targetPad, availPads)) {
                    jump(cell, capitalizeFirst(targetPad));
                } else {
                    jump(cell, chooseFallbackPad(availPads));
                }
                return;
            }

            // Determine initial pad to jump to (use targetPad if specified, else "Spawn")
            var initialPad:String = (targetPad != "") ? targetPad : "Spawn";

            targetJumpCell = cell;
            targetJumpPad = targetPad;

            // Perform initial jump
            jump(cell, capitalizeFirst(initialPad));

            // Schedule pad verification and correction once arrived in cell
            startPadCorrectionTimer();
        }

        private function startPadCorrectionTimer():void {
            if (padCorrectionTimer == null) {
                padCorrectionTimer = new Timer(150, 10);
                padCorrectionTimer.addEventListener(TimerEvent.TIMER, onPadCorrectionTick, false, 0, true);
                padCorrectionTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onPadCorrectionComplete, false, 0, true);
            }
            padCorrectionTimer.reset();
            padCorrectionTimer.start();
        }

        private function onPadCorrectionTick(e:TimerEvent):void {
            if (game == null || game.world == null) {
                stopPadCorrection();
                return;
            }

            var curCell:String = getMyCell();
            var curPad:String = getMyPad();
            var availPads:Array = getAvailablePads();

            // If traveling towards target cell, wait until cell matches
            if (targetJumpCell != "" && curCell != "" && curCell.toLowerCase() != targetJumpCell.toLowerCase()) {
                return;
            }

            if (availPads == null || availPads.length == 0) {
                return;
            }

            // If user requested a specific pad and that pad exists in the target cell
            if (targetJumpPad != "" && isPadInAvailable(targetJumpPad, availPads)) {
                if (curPad.toLowerCase() != targetJumpPad.toLowerCase()) {
                    jump(curCell, capitalizeFirst(targetJumpPad));
                }
                stopPadCorrection();
                return;
            }

            // Check if player's current pad exists in availablePads
            if (!isPadInAvailable(curPad, availPads)) {
                var fallbackPad:String = chooseFallbackPad(availPads);
                if (fallbackPad != null && fallbackPad.length > 0) {
                    jump(curCell, fallbackPad);
                }
            }

            stopPadCorrection();
        }

        private function onPadCorrectionComplete(e:TimerEvent):void {
            stopPadCorrection();
        }

        public function stopPadCorrection():void {
            if (padCorrectionTimer != null && padCorrectionTimer.running) {
                padCorrectionTimer.stop();
            }
            targetJumpCell = "";
            targetJumpPad = "";
        }

        public function isPadInAvailable(pad:String, availablePads:Array):Boolean {
            if (pad == null || pad.length == 0 || availablePads == null)
                return false;
            const padLower:String = pad.toLowerCase();
            for each (var p:String in availablePads) {
                if (p != null && p.toLowerCase() == padLower) {
                    return true;
                }
            }
            return false;
        }

        public function chooseFallbackPad(availablePads:Array):String {
            if (availablePads == null || availablePads.length == 0)
                return "Spawn";

            const priority:Array = ["spawn", "center", "left", "right", "top", "bottom", "up", "down"];
            for each (var pref:String in priority) {
                for each (var p:String in availablePads) {
                    if (p != null && p.toLowerCase() == pref) {
                        return capitalizeFirst(p);
                    }
                }
            }

            return capitalizeFirst(availablePads[0]);
        }

        public function capitalizeFirst(str:String):String {
            if (str == null || str.length == 0)
                return "";
            return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
        }

        public function getCells():String {
            var cells:Array = [];
            if (game != null && game.world != null && game.world.map != null && game.world.map.currentScene != null && game.world.map.currentScene.labels != null) {
                for each (var cell:Object in game.world.map.currentScene.labels)
                    cells.push(cell.name);
            }
            return JSON.stringify(cells);
        }

        public function getAvailablePads():Array {
            var padNames:RegExp = /^(Center|Spawn|Left|Right|Top|Bottom|Up|Down)$/i;
            var cellPads:Array = new Array();
            if (game != null && game.world != null && game.world.map != null) {
                var cellPadsCnt:int = game.world.map.numChildren;
                for (var i:int = 0; i < cellPadsCnt; ++i) {
                    var child:DisplayObject = game.world.map.getChildAt(i);
                    if (child != null && padNames.test(child.name)) {
                        cellPads.push(child.name.toLowerCase());
                    }
                }
            }
            return cellPads;
        }

        public function getMyCell():String {
            if (game != null && game.world != null && game.world.strFrame != null) {
                return game.world.strFrame;
            }
            return "";
        }

        public function getMyPad():String {
            if (game != null && game.world != null && game.world.strPad != null) {
                return game.world.strPad;
            }
            return "";
        }

        public function getAccessLevel(username:String):int {
            var accessLevel:int = 0;
            if (game != null && game.world != null && game.world.avatars != null) {
                var avatars:* = game.world.avatars;
                for (var a:String in avatars) {
                    var avatar:Object = avatars[a];
                    if (username != null && avatar != null && avatar.dataLeaf != null && avatar.dataLeaf.strUsername != null) {
                        if (avatar.dataLeaf.strUsername.toLowerCase() == username.toLowerCase()) {
                            var uid:int = int(avatar.uid);
                            var userAvatar:Object = game.world.getAvatarByUserID(uid);
                            if (userAvatar != null && userAvatar.objData != null) {
                                accessLevel = userAvatar.objData.intAccessLevel;
                            }
                            break;
                        }
                    }
                }
            }
            return accessLevel;
        }
    }
}
