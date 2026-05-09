package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxPieDial;
import Controls;
import StorageUtil;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

class VideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	public var bitmap(get, never):Dynamic;
	private function get_bitmap() return videoSprite.bitmap;
	public function load(name:String, ?options:Dynamic) {
        #if hxvlc
        var path:String = StorageUtil.getStorageDirectory() + 'assets/videos/' + name + '.mp4';
        videoSprite.load(path, options);
        #end
    }
	public var finishCallback:Dynamic = null;
	public var onSkip:Void->Void = null;
	@:noCompletion public var customOriginCallback:Dynamic = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	private var videoName:String;

	public var waiting:Bool = false;

	public function new(videoName:String = '', isWaiting:Bool = false, canSkip:Bool = false, shouldLoop:Dynamic = false, ...args:Array<Dynamic> {
        super();
		Reflect.setField(this, "originCallback", null);
        this.videoName = videoName;
        scrollFactor.set();
        
        if (FlxG.cameras.list.length > 0)
            cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        waiting = isWaiting;
		if(!waiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		videoSprite = new FlxVideoSprite();
        
        #if (psychEngineVersion >= "0.7.0")
        videoSprite.antialiasing = ClientPrefs.globalAntialiasing;
        #else
        // If this still errors, just set it to true manually
        videoSprite.antialiasing = true; 
        #end
        
        add(videoSprite);
        if(canSkip) this.canSkip = true;

        #if hxvlc
        // FIX: hxvlc uses 'events' or 'mediaPlayer' now
        videoSprite.bitmap.onEndReached.add(finishVideo);

        videoSprite.bitmap.onFormatSetup.add(function()
        {
            videoSprite.setGraphicSize(FlxG.width);
            videoSprite.updateHitbox();
            videoSprite.screenCenter();
        });

        // FIX: Use loadLocation or loadStorage instead of .load
        var path:String = StorageUtil.getStorageDirectory() + 'assets/videos/' + videoName + '.mp4'; // Standard pathing
        videoSprite.load(path, shouldLoop ? ['input-repeat=65545'] : null);
        #end
        
        if(!waiting)
            videoSprite.play();
	}

	var alreadyDestroyed:Bool = false;
	override function destroy()
	{
		if(alreadyDestroyed)
			return;

		if(cover != null)
		{
			remove(cover);
			cover.destroy();
		}
		
		finishCallback = null;
		onSkip = null;

		if(FlxG.state != null)
		{
			if(FlxG.state.members.contains(this))
				FlxG.state.remove(this);
		}
		super.destroy();
		alreadyDestroyed = true;
	}

	function finishVideo()
	{
		if (!alreadyDestroyed)
		{
			if(finishCallback != null)
				finishCallback();
			
			destroy();
		}
	}

	override function update(elapsed:Float)
	{
		if(canSkip)
		{
			// FIX 3: Controls.instance vs PlayerSettings
			var pressedSkip:Bool = false;
			#if mobile
			// On iOS/Mobile, usually any touch or a specific button skips
			pressedSkip = FlxG.touches.list.length > 0 || FlxG.keys.justPressed.ENTER;
			#else
			try {
				pressedSkip = Controls.instance.ACCEPT;
			} catch(e:Dynamic) {
				pressedSkip = FlxG.keys.justPressed.ENTER;
			}
			#end

			if(pressedSkip)
			{
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			}
			else if (holdingTime > 0)
			{
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
			}
			updateSkipAlpha();

			if(holdingTime >= _timeToSkip)
			{
				if(onSkip != null) onSkip();
				finishCallback = null;
				#if hxvlc
				videoSprite.bitmap.onEndReached.dispatch();
				#else
				finishVideo();
				#end
				return;
			}
		}
		super.update(elapsed);
	}

	function set_canSkip(newValue:Bool)
	{
		canSkip = newValue;
		if(canSkip)
		{
			if(skipSprite == null)
			{
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
				skipSprite.x = FlxG.width - (skipSprite.width + 80);
				skipSprite.y = FlxG.height - (skipSprite.height + 72);
				skipSprite.amount = 0;
				add(skipSprite);
			}
		}
		else if(skipSprite != null)
		{
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}
		return canSkip;
	}

	function updateSkipAlpha()
	{
		if(skipSprite == null) return;
		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}

	// Helper methods to ensure compatibility with PlayState calls
	public function play() { if(videoSprite != null) videoSprite.play(); }
	public function resume() { if(videoSprite != null) videoSprite.resume(); }
	public function pause() { if(videoSprite != null) videoSprite.pause(); }
	#end
}
