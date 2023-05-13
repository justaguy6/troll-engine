package;

import openfl.system.Capabilities;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
using StringTools;
#if CRASH_HANDLER
import haxe.CallStack;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
#end
#if desktop
import Discord.DiscordClient;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = StartupState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;
	public static var bread:Bread;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	public static function setScaleMode(scale:String){
		switch(scale){
			default:
				Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
			case 'EXACT_FIT':
				Lib.current.stage.scaleMode = StageScaleMode.EXACT_FIT;
			case 'NO_BORDER':
				Lib.current.stage.scaleMode = StageScaleMode.NO_BORDER;
			case 'SHOW_ALL':
				Lib.current.stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
	}

	private function setupGame():Void
	{
		//// Readjust the game size for smaller screens
		var screenWidth = Capabilities.screenResolutionX;
		var screenHeight = Capabilities.screenResolutionY;

		if (zoom == -1 && !(screenWidth > gameWidth || screenHeight > gameWidth))
		{
			var ratioX:Float = screenWidth / gameWidth;
			var ratioY:Float = screenHeight / gameHeight;
			
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(screenWidth / zoom);
			gameHeight = Math.ceil(screenHeight / zoom);
		}
	
		////
		ClientPrefs.loadDefaultKeys();

		var troll = false;
		
		#if desktop 
		for (arg in Sys.args()){
			if (arg.contains("troll")){
				troll = true;
				break;
			}else if (arg.contains("debug")){
				PlayState.chartingMode = true;
				initialState = SongSelectState;
			}
		}
		#end

		if (troll){
			initialState = SinnerState;
			skipSplash = true;
		}else if (FlxG.save.bind('funkin', 'ninjamuffin99') && FlxG.save.data.fullscreen != null){
			startFullscreen = FlxG.save.data.fullscreen;
		}
		
		addChild(new FlxGame(gameWidth, gameHeight, initialState, #if(flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen));

		FlxG.sound.muteKeys = StartupState.muteKeys;
		FlxG.sound.volumeDownKeys = StartupState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = StartupState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		
		
		if (!troll){
			fpsVar = new FPS(10, 3, 0xFFFFFF);
			fpsVar.visible = false;
			addChild(fpsVar);
			
			Lib.current.stage.align = "tl";
			Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		}
		
		bread = new Bread();
		bread.visible = false;
		addChild(bread);

		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
	}

	// Original code was made by sqirra-rng, big props to them!!!
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		Sys.println("Call stack starts below");

		var errMsg:String = "";
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += '$file:$line\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;

		Sys.println(" \n" + errMsg);
		
		Application.current.window.alert(errMsg, "Error!");

		Sys.exit(1);
	}
	#end
}
