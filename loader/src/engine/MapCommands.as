package engine {
    import flash.display.DisplayObject;

    public class MapCommands {

        private var game:Object;

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
