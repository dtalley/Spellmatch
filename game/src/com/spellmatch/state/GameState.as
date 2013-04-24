package com.spellmatch.state 
{
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
  import com.orionark.resource.JSONResourceHandler;
  import com.orionark.resource.MaterialResourceHandler;
  import com.orionark.resource.ResourceBundle;
  import com.orionark.resource.ResourceManager;
  import com.orionark.resource.TextureResourceHandler;
  import com.orionark.stage.StageManager;
	import com.orionark.state.State;
  import com.orionark.system.SystemManager;
  import com.orionark.util.Random;
  import com.spellmatch.resource.MapResourceHandler;
  import com.spellmatch.system.MapSystem;
  import com.spellmatch.system.SpellSystem;
  import com.spellmatch.system.UnitSystem;
  import flash.events.Event;
  import flash.utils.getTimer;
	
	/**
   * ...
   * @author David Talley
   */
  public class GameState extends State 
  {
    private var _step:Number = 1.0 / 60.0;
    
    private var _previousTick:int;
    private var _accumulator:Number = 0.0;
    private var _systemManager:SystemManager;
    
    private var _pathBundle:ResourceBundle;
    private var _assetBundle:ResourceBundle;
    
    public function GameState() 
    {
      
    }
    
    override public function dock():void
    {
      _systemManager = new SystemManager();
    }
    
    override protected function load():void
    {
      ResourceManager.enable(TextureResourceHandler);
      ResourceManager.enable(JSONResourceHandler);
      ResourceManager.enable(MaterialResourceHandler);
      ResourceManager.enable(MapResourceHandler);
      
      _pathBundle = new ResourceBundle();
      _pathBundle.add("json/game_assets.json");
      _pathBundle.load(pathsLoaded);
    }
    
    private function pathsLoaded():void
    {
      var paths:Array = ResourceManager.get("json/game_assets.json").data as Array;
      
      _assetBundle = new ResourceBundle();
      for each ( var path:String in paths )
      {
        _assetBundle.add(path);
      }
      _assetBundle.load(ready);
    }
    
    private function ready():void
    {
      _previousTick = getTimer();
      Random.seed = _previousTick;
      
      _systemManager.add(UnitSystem);
      _systemManager.add(SpellSystem);
      _systemManager.add(MapSystem);
      
      StageManager.stage.addEventListener(Event.ENTER_FRAME, frameEntered);
    }
    
    private function frameEntered(e:Event):void
    {
      var currentTick:int = getTimer();
      var tickLength:int = currentTick - _previousTick;
      _previousTick = currentTick;
      _accumulator += tickLength / 1000.0;
      
      var step:Boolean = _accumulator >= _step;
      
      if ( step )
      {
        StageManager.lock();
        StageManager.clear();
      }
      
      while ( _accumulator >= _step )
      {
        _accumulator -= _step;
        _systemManager.update(_step, _accumulator < _step);
      }
      
      if ( step )
      {
        StageManager.unlock();
      }
    }
    
    override public function destroy():void
    {
      StageManager.stage.removeEventListener(Event.ENTER_FRAME, frameEntered);
    }
  }

}