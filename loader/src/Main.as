package {

	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.display.NativeWindow;
	import flash.display.Screen;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.SharedObject;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	import SFSEvent;
	import com.aqw.battery.BatteryOptimizer;
	import ui.VersionDisplay;
	import ui.BaseModal;
	import ui.ChipTag;
	import ui.MyButton;
	import ui.MyCheckbox;
	import ui.MyTextField;
	import ui.ScrollContainer;
	import ui.UIUtils;
	import ui.ChatPreviewUI;
	import input.AccountManagerUI;
	import input.BotManagerUI;
	import input.MainMenuUI;
	import input.PacketLoggerUI;
	import input.AppLogUI;
	import handler.PacketHandler;

	[SWF(width="960", height="550", frameRate="30", backgroundColor="#000")]
	public dynamic class Main extends MovieClip {

		MovieClip.prototype.removeAllChildren = function():void {
			var i:int = this.numChildren - 1;
			while (i >= 0) {
				this.removeChildAt(i);
				i--;
			}
		};

		public static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("_sans", 22, 0xc8d8ee, true, null, null, null, null, TextFormatAlign.CENTER);
		public static const TEXT_FORMAT_LOG:TextFormat = new TextFormat("_typewriter", 12, 0x00ff66, false, null, null, null, null, TextFormatAlign.LEFT);

		private static const STATE_BACKGROUND:int = 0;
		private static const STATE_GAME:int = 1;
		private static const STATE_READY:int = 2;

		private var loading:TextField;
		private var logField:TextField;
		private var backgroundDomain:ApplicationDomain = new ApplicationDomain();
		private var backgroundContext:LoaderContext = createLoaderContext(backgroundDomain);
		private var clientDomain:ApplicationDomain = new ApplicationDomain();
		private var clientContext:LoaderContext = createLoaderContext(clientDomain);
		private var gameMovieClip:MovieClip;
		private var titleFile:String;
		private var backgroundFile:String;
		private var loadState:int = STATE_BACKGROUND;
		private var packetHandler:PacketHandler;

		private var container:Sprite = new Sprite();
		private var versionDisplay:VersionDisplay;
		private var accountManagerUI:AccountManagerUI;
		private var windowCentered:Boolean = false;
		private var appStage:Stage;

		public function Main() {
			var _uiDeps:Array = [BaseModal, BotManagerUI, ChipTag, MyButton, MyCheckbox, MyTextField, ScrollContainer, UIUtils];
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;

			if (stage != null) {
				initStage();
			}
			else {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}

			addChild(container);

			prepareContext(backgroundContext);
			prepareContext(clientContext);

			versionDisplay = new VersionDisplay(Config.APP_VERSION);
			container.addChild(versionDisplay);

			accountManagerUI = new AccountManagerUI(function():MovieClip {
					return gameMovieClip;
				});
			container.addChild(accountManagerUI);

			loading = new TextField();
			loading.defaultTextFormat = TEXT_FORMAT_DEFAULT;
			loading.width = 400;
			loading.height = 30;
			loading.x = (960 - 400) / 2;
			loading.y = (550 - 30) / 2;
			loading.selectable = false;
			loading.text = "Loading...";

			addChild(loading);

			logField = new TextField();
			logField.defaultTextFormat = TEXT_FORMAT_LOG;
			logField.width = 920;
			logField.height = 200;
			logField.x = 20;
			logField.y = 330;
			logField.multiline = true;
			logField.wordWrap = true;
			logField.selectable = true;
			logField.background = true;
			logField.backgroundColor = 0x111111;
			logField.border = true;
			logField.borderColor = 0x444444;
			logField.visible = false;

			container.addChild(logField);

			if (loaderInfo != null && "uncaughtErrorEvents" in loaderInfo && loaderInfo.uncaughtErrorEvents != null) {
				loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalUncaughtError);
			}

			log("Init");

			if (Config.isAndroid) {
				try {
					BatteryOptimizer.requestNotificationPermission();
				}
				catch (eNotifPerm:Error) {
				}
			}

			// checkForUpdates();

			fetchJSON(Config.API_VERSION_URL, onVersionComplete);
		}

		private function onGlobalUncaughtError(e:UncaughtErrorEvent):void {
			if (e != null) {
				e.preventDefault();
			}

			var errText:String = "";
			if (e.error is Error) {
				var err:Error = e.error as Error;
				errText = err.name + " (" + err.errorID + "): " + err.message + "\n" + err.getStackTrace();
			}
			else if (e.error is ErrorEvent) {
				errText = ErrorEvent(e.error).text;
			}
			else {
				errText = String(e.error);
			}

			log("[Game] ERR uncaught: " + errText);

			if (loadState != STATE_READY) {
				showError("Global Uncaught Error:\n" + errText);
			}
		}

		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			initStage();
		}

		private var gcTimer:Timer;

		private function initStage():void {
			if (stage != null) {
				appStage = stage;
				try {
					stage.quality = StageQuality.LOW;
					stage.scaleMode = StageScaleMode.SHOW_ALL;
					stage.align = "";
					if (Config.isAndroid) {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					}
					else {
						stage.displayState = StageDisplayState.NORMAL;
					}
				}
				catch (err:Error) {
				}
			}

			try {
				if (Screen.mainScreen != null) {
					log("Screen bounds: " + Screen.mainScreen.bounds + " | visibleBounds: " + Screen.mainScreen.visibleBounds + " | stage: " + (stage ? (stage.stageWidth + "x" + stage.stageHeight) : "null"));
				}
			}
			catch (err:Error) {
			}

			try {
				NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, function(e:Event):void {
						try {
							if (Config.isAndroid) {
								var targetStage:Stage = appStage != null ? appStage : stage;
								if (targetStage != null) {
									targetStage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
								}
							}
						}
						catch (err2:Error) {
						}
					});
			}
			catch (err:Error) {
			}

			centerWindow();
			if (!windowCentered && stage != null && "nativeWindow" in stage && stage.nativeWindow != null) {
				stage.nativeWindow.addEventListener(Event.ACTIVATE, onWindowActivateOnce);
			}

			startMemoryCleanupTimer();
			checkBatteryOptimization();
		}

		private function checkBatteryOptimization():void {
			if (!Config.isAndroid)
				return;
			try {
				// Jika aplikasi sudah masuk daftar Unrestricted, tidak perlu memunculkan dialog
				if (BatteryOptimizer.isIgnoringBatteryOptimizations()) {
					return;
				}

				var so:SharedObject = SharedObject.getLocal("aqw_pocket_settings");
				if (!so.data.batteryPrompted) {
					so.data.batteryPrompted = true;
					so.flush();
					var promptTimer:Timer = new Timer(2500, 1);
					promptTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
							requestBatteryOptimization();
						});
					promptTimer.start();
				}
			}
			catch (err:Error) {
			}
		}

		public static function requestBatteryOptimization():void {
			if (!Config.isAndroid)
				return;
			try {
				BatteryOptimizer.requestUnrestricted();
			}
			catch (e:Error) {
				try {
					BatteryOptimizer.openAppDetails();
				}
				catch (errFallback:Error) {
				}
			}
		}

		private function startMemoryCleanupTimer():void {
			if (gcTimer == null) {
				// Periodic memory cleanup every 90 seconds
				gcTimer = new Timer(90000);
				gcTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
						cleanupMemory();
					});
				gcTimer.start();
			}
		}

		public static function cleanupMemory():void {
			try {
				System.pauseForGCIfCollectionImminent(0.25);
				System.gc();
			}
			catch (err:Error) {
			}
		}

		private function onWindowActivateOnce(e:Event):void {
			if (stage != null && "nativeWindow" in stage && stage.nativeWindow != null) {
				stage.nativeWindow.removeEventListener(Event.ACTIVATE, onWindowActivateOnce);
			}
			centerWindow();
		}

		private function centerWindow():void {
			try {
				if (stage != null && "nativeWindow" in stage && stage.nativeWindow != null) {
					var win:NativeWindow = stage.nativeWindow;
					var screen:Screen = Screen.mainScreen;
					if (screen != null) {
						var bounds:Rectangle = screen.visibleBounds;
						var w:Number = win.width > 0 ? win.width : (stage.stageWidth > 0 ? stage.stageWidth : 960);
						var h:Number = win.height > 0 ? win.height : (stage.stageHeight > 0 ? stage.stageHeight : 550);
						win.x = int(bounds.x + Math.max(0, (bounds.width - w) / 2));
						win.y = int(bounds.y + Math.max(0, (bounds.height - h) / 2));
						windowCentered = true;
					}
				}
			}
			catch (err:Error) {
				// Ignore on platforms without NativeWindow support (e.g. mobile)
			}
		}

		private function log(msg:String):void {
			trace("[AQW] " + msg);
			var timestamp:String = new Date().toTimeString().substr(0, 8);
			logField.appendText("[" + timestamp + "] " + msg + "\n");
			logField.scrollV = logField.maxScrollV;
			AppLogUI.log(msg);
			trace(msg);
		}

		private function showError(msg:String):void {
			loading.text = "Error — see log below";
			logField.visible = true;
			if (container.parent != null) {
				container.parent.setChildIndex(container, container.parent.numChildren - 1);
			}
			else if (stage != null) {
				stage.addChild(container);
			}
			log("ERROR: " + msg);
		}

		public function loadMapViaBytes(url:String, context:LoaderContext, onComplete:Function, onProgress:Function = null, onError:Function = null):void {
			prepareContext(context);
			log("[Map] Loading: " + url);

			loadBinary(url,
					function(bytes:ByteArray):void {
						log("[Map] Downloaded " + bytes.length + " bytes for: " + url);
						const ldr:Loader = new Loader();

						if (gameMovieClip != null && gameMovieClip.world != null) {
							gameMovieClip.world.ldr_map = ldr;
						}

						ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
								log("[Map] Complete: " + url);
								cleanupMemory();
								if (onComplete != null) {
									onComplete(e);
								}
							});
						ldr.loadBytes(bytes, context);
					},
					onProgress,
					function(e:IOErrorEvent):void {
						log("[Map] ERROR: " + url + " - " + e.text);
						if (onError != null) {
							onError(e);
						}
					}
				);
		}

		public function queueLoadViaBytes(ldr:Loader, url:String, context:LoaderContext):void {
			if (context == null) {
				context = new LoaderContext(false, ApplicationDomain.currentDomain);
			}
			prepareContext(context);
			log("[Asset] Queueing: " + url);

			loadBinary(url,
					function(bytes:ByteArray):void {
						log("[Asset] Downloaded " + bytes.length + " bytes for: " + url);
						try {
							ldr.loadBytes(bytes, context);
						}
						catch (err:Error) {
							log("[Asset] loadBytes ERROR: " + err.message + " for " + url);
						}
					},
					function(e:ProgressEvent):void {
						try {
							ldr.contentLoaderInfo.dispatchEvent(e);
						}
						catch (err:Error) {
						}
					},
					function(e:IOErrorEvent):void {
						log("[Asset] ERROR: " + url + " - " + e.text);
						try {
							ldr.contentLoaderInfo.dispatchEvent(e);
						}
						catch (err:Error) {
						}
					}
				);
		}

		public function load(ldr:Loader, url:String, context:LoaderContext, onComplete:Function = null):void {
			if (context == null) {
				context = new LoaderContext(false, ApplicationDomain.currentDomain);
			}
			prepareContext(context);
			log("[Mobile] Loading: " + url);

			loadBinary(url,
					function(bytes:ByteArray):void {
						log("[Mobile] Downloaded " + bytes.length + " bytes for: " + url);
						try {
							if (onComplete != null) {
								ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
										onComplete(e);
									});
							}
							ldr.loadBytes(bytes, context);
						}
						catch (err:Error) {
							log("[Mobile] loadBytes ERROR: " + err.message + " for " + url);
						}
					},
					function(e:ProgressEvent):void {
						try {
							ldr.contentLoaderInfo.dispatchEvent(e);
						}
						catch (err:Error) {
						}
					},
					function(e:IOErrorEvent):void {
						log("[Mobile] ERROR: " + url + " - " + e.text);
						try {
							ldr.contentLoaderInfo.dispatchEvent(e);
						}
						catch (err:Error) {
						}
					}
				);
		}

		private function advance():void {
			switch (loadState) {
				case STATE_BACKGROUND:
					loadBackground();
					break;
				case STATE_GAME:
					loadGame();
					break;
				case STATE_READY:
					attachGame();
					break;
			}
		}

		private function loadBackground():void {
			log("Loading background: " + backgroundFile);

			loading.text = "Loading Background...";

			loadSwf(
					Config.GAME_BASE_URL + "gamefiles/title/" + backgroundFile,
					backgroundContext,
					onBackgroundComplete,
					onBackgroundProgress,
					function(e:IOErrorEvent):void {
						log("Background load failed, skipping: " + e.text);
						loading.text = "Loading Game...";
						loadState = STATE_GAME;
						advance();
					}
				);
		}

		private function loadGame():void {
			log("Loading game client: " + Config.GAME_SWF_PATH);

			loading.text = "Loading Game...";

			loadSwf(
					Config.GAME_SWF_PATH,
					clientContext,
					onGameComplete,
					onGameProgress,
					function(e:IOErrorEvent):void {
						showError("Failed to load game client: " + e.text);
					}
				);
		}

		private function attachGame():void {
			log("Attaching game...");

			try {
				if (contains(container)) {
					removeChild(container);
				}

				const params:Object = gameMovieClip.params;

				if (params != null) {
					params.sTitle = titleFile;
					params.isWeb = false;
					params.sURL = Config.GAME_BASE_URL;
					params.sBG = backgroundFile;
					params.isEU = false;
					params.doSignup = false;
					params.loginURL = Config.API_LOGIN_URL;
					params.test = false;

					const rootParams:Object = root.loaderInfo.parameters;

					for (var key:String in rootParams) {
						params[key] = rootParams[key];
					}
				}
				else {
					log("WARNING: gameMovieClip.params is null");
				}

				gameMovieClip.failedServers = {mobile: this};
				try {
					gameMovieClip.pocket = this;
				}
				catch (err:Error) {
					log("WARNING: Could not set pocket on gameMovieClip: " + err.message);
				}

				stage.addChild(gameMovieClip);
				stage.setChildIndex(gameMovieClip, 0);

				try {
					stage.quality = StageQuality.LOW;
					stage.scaleMode = StageScaleMode.SHOW_ALL;
					stage.align = "";
					if (Config.isAndroid) {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					}
				}
				catch (errStage:Error) {
				}

				if (stage.contains(DisplayObject(this))) {
					stage.removeChild(DisplayObject(this));
				}

				gameMovieClip.addChild(container);
				gameMovieClip.addChild(new MainMenuUI(gameMovieClip));
				gameMovieClip.addChild(new ChatPreviewUI(gameMovieClip));

				accountManagerUI.setGame(gameMovieClip);
				accountManagerUI.updateStatus(false);

				var isSfcHooked:Boolean = false;
				var hookSFC:Function = function():void {
					if (!isSfcHooked && gameMovieClip != null && "sfc" in gameMovieClip && gameMovieClip.sfc != null) {
						isSfcHooked = true;
						gameMovieClip.sfc.addEventListener(SFSEvent.onDebugMessage, onPacketReceived);
						gameMovieClip.sfc.addEventListener(SFSEvent.onConnectionLost, onConnectionLost);
						log("SmartFoxServer debug hook attached.");
					}
				};

				hookSFC();

				var sfcTimer:Timer = new Timer(500, 30);
				sfcTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
						if (gameMovieClip != null && "sfc" in gameMovieClip && gameMovieClip.sfc != null) {
							sfcTimer.stop();
							hookSFC();
						}
					});
				sfcTimer.start();

				log("Game attached successfully!");
			}
			catch (err:Error) {
				showError("Failed attaching game: " + err.name + " (" + err.errorID + "): " + err.message + "\n" + err.getStackTrace());
			}
		}

		private function onVersionComplete(e:Event):void {
			try {
				const data:Object = JSON.parse(URLLoader(e.target).data);
				titleFile = data.sTitle;
				backgroundFile = data.sBG;
				log("Version fetched — title: " + titleFile + ", bg: " + backgroundFile);
				advance();
			}
			catch (err:Error) {
				showError("Failed to parse version response: " + err.message);
			}
		}

		private function onBackgroundComplete(e:Event):void {
			log("Background loaded");

			try {
				var domain:ApplicationDomain = backgroundDomain;
				if (e.target != null && "applicationDomain" in e.target && e.target.applicationDomain != null) {
					domain = e.target.applicationDomain;
				}
				if (domain != null && domain.hasDefinition("TitleScreen")) {
					const TitleScreenClass:Class = domain.getDefinition("TitleScreen") as Class;
					const titleScreen:DisplayObject = new TitleScreenClass();

					titleScreen.x = 0;
					titleScreen.y = 0;

					addChildAt(titleScreen, 0);
				}
				else {
					log("TitleScreen class not in background SWF, skipping");
				}
			}
			catch (err:Error) {
				log("TitleScreen class load failed, skipping: " + err.message);
			}

			loadState = STATE_GAME;
			advance();
		}

		private function onBackgroundProgress(e:ProgressEvent):void {
			loading.text = "Loading Background " + progressPercent(e) + "%";
		}

		private function onGameComplete(e:Event):void {
			log("Game client loaded");

			try {
				gameMovieClip = MovieClip(Loader(e.target.loader).content);
				loadState = STATE_READY;
				advance();
			}
			catch (err:Error) {
				showError("Game client content error: " + err.name + " (" + err.errorID + "): " + err.message + "\n" + err.getStackTrace());
			}
		}

		private function onGameProgress(e:ProgressEvent):void {
			loading.text = "Loading Game " + progressPercent(e) + "%";
		}

		private static function createLoaderContext(domain:ApplicationDomain = null):LoaderContext {
			const ctx:LoaderContext = new LoaderContext(false, domain != null ? domain : new ApplicationDomain());
			ctx.allowCodeImport = true;
			return ctx;
		}

		private static function prepareContext(ctx:LoaderContext):void {
			if (ctx == null)
				return;
			ctx.checkPolicyFile = false;
			ctx.allowCodeImport = true;
		}

		private static function progressPercent(e:ProgressEvent):int {
			return int((e.currentTarget.bytesLoaded / e.currentTarget.bytesTotal) * 100);
		}

		private static function trimUrl(str:String):String {
			if (str == null || str.length == 0) {
				return str;
			}

			var end:int = str.length - 1;

			// Fast-path: no trailing space in the vast majority of URLs
			if (str.charCodeAt(end) > 32) {
				return str;
			}

			// Walk back any whitespace (covers edge cases with multiple spaces)
			while (end >= 0 && str.charCodeAt(end) <= 32) {
				end--;
			}

			return str.substring(0, end + 1);
		}

		private static function loadBinary(url:String, onBytes:Function, onProgress:Function = null, onError:Function = null):void {
			const ul:URLLoader = new URLLoader();
			ul.dataFormat = URLLoaderDataFormat.BINARY;

			var cleanup:Function = function():void {
				ul.removeEventListener(Event.COMPLETE, onComplete);
				if (onProgress != null) {
					ul.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				}
				if (onError != null) {
					ul.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
					ul.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				}
			};

			var onComplete:Function = function(e:Event):void {
				const data:ByteArray = URLLoader(e.target).data as ByteArray;
				cleanup();
				if (onBytes != null) {
					onBytes(data);
				}
			};

			var onIOError:Function = function(e:IOErrorEvent):void {
				cleanup();
				if (onError != null) {
					onError(e);
				}
			};

			var onSecurityError:Function = function(e:SecurityErrorEvent):void {
				cleanup();
				if (onError != null) {
					onError(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "SecurityError: " + e.text));
				}
			};

			ul.addEventListener(Event.COMPLETE, onComplete);

			if (onProgress != null) {
				ul.addEventListener(ProgressEvent.PROGRESS, onProgress);
			}

			ul.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			ul.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);

			try {
				ul.load(new URLRequest(trimUrl(url)));
			}
			catch (e:Error) {
				cleanup();
				if (onError != null) {
					onError(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, e.message));
				}
			}
		}

		private function loadSwf(url:String, context:LoaderContext, onComplete:Function, onProgress:Function = null, onError:Function = null):void {
			loadBinary(url,
					function(bytes:ByteArray):void {
						const ldr:Loader = new Loader();
						ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);

						if (onError != null) {
							ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
						}

						ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
								showError("Security Error loading SWF: " + e.text);
							});

						ldr.contentLoaderInfo.addEventListener(AsyncErrorEvent.ASYNC_ERROR, function(e:AsyncErrorEvent):void {
								showError("Async Error loading SWF: " + e.text);
							});

						if ("uncaughtErrorEvents" in ldr && ldr.uncaughtErrorEvents != null) {
							ldr.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(e:UncaughtErrorEvent):void {
									var errStr:String = "";
									if (e.error is Error) {
										var err:Error = e.error as Error;
										errStr = err.name + " (" + err.errorID + "): " + err.message + "\n" + err.getStackTrace();
										if (err.errorID == 3207) {
											errStr += "\n\n[Hint]: SecurityError 3207 occurs when Game.swf calls Security.allowDomain(), which Adobe AIR does not permit in the Application Sandbox. Use the patched Game.swf.";
										}
									}
									else if (e.error is ErrorEvent) {
										errStr = ErrorEvent(e.error).text;
									}
									else {
										errStr = String(e.error);
									}
									showError("SWF Runtime/Verify Error:\n" + errStr);
								});
						}

						try {
							ldr.loadBytes(bytes, context);
						}
						catch (e:Error) {
							showError("Exception in loadBytes: " + e.name + " (" + e.errorID + "): " + e.message + "\n" + e.getStackTrace());
						}
					},
					onProgress,
					onError
				);
		}

		private static function fetchJSON(url:String, onComplete:Function):void {
			const ul:URLLoader = new URLLoader();
			ul.addEventListener(Event.COMPLETE, onComplete);
			ul.load(new URLRequest(url));
		}

		private function onPacketReceived(packet:*):void {
			if (packet.params.message.indexOf("%xt%zm%") > -1) {
				// from client
				var clientMsg:String = Utils.normalizePacket(packet.params.message);
				if (PacketLoggerUI.instance != null) {
					PacketLoggerUI.instance.logPacket(clientMsg, true);
				}
			}
			else {
				// from server
				var serverMsg:String = Utils.normalizePacket(packet.params.message);
				if (PacketLoggerUI.instance != null) {
					PacketLoggerUI.instance.logPacket(serverMsg, false);
				}
				if (packetHandler != null) {
					packetHandler.handleServerResponse(serverMsg);
				}

				if (serverMsg.indexOf("initUserData") > -1) {
					versionDisplay.visible = false;
					accountManagerUI.updateStatus(true);
				}
				else if (serverMsg.indexOf("logout") > -1 || serverMsg.indexOf("Connection lost") > -1) {
					versionDisplay.visible = true;
					accountManagerUI.updateStatus(false);
					if (Config.isAndroid) {
						try {
							BatteryOptimizer.sendNotification("YouMadBro - Disconnected", "Connection to server lost!", 999);
							BatteryOptimizer.stopKeepAlive();
						}
						catch (eDcMsg:Error) {
						}
					}
				}
			}
		}

		private function onConnectionLost(e:SFSEvent):void {
			log("SmartFoxServer connection lost!");
			versionDisplay.visible = true;
			accountManagerUI.updateStatus(false);
			if (Config.isAndroid) {
				try {
					BatteryOptimizer.sendNotification("YouMadBro - Disconnected", "Connection to game server lost!", 999);
					BatteryOptimizer.stopKeepAlive();
				}
				catch (eDcEvt:Error) {
				}
			}
		}
	}
}
