package com.orionark.state 
{
	/**
   * ...
   * @author David Talley
   */
  public class StateManager 
  {
    private static var _callback:Function = null;
    
    private static var _loaded:State = null;
    private static var _docked:State = null;
    
    public static function get docked():State
    {
      return _docked;
    }
    
    public static function get loaded():State
    {
      return _loaded;
    }
    
    public static function dock(state:Class):void
    {
      if ( _docked )
      {
        _docked.destroy();
      }
      _docked = new state() as State;
      _docked.dock();
    }
    
    public static function load(loadedCallback:Function):void
    {
      if ( !_docked )
      {
        throw new Error("No state is currently docked.");  
      }
      
      _callback = loadedCallback;
      
      _docked.prepare(stateLoaded);
    }
    
    private static function stateLoaded(state:State):void
    {
      _loaded.destroy();
      _loaded = state;
      if ( _callback !== null )
      {
        _callback.apply(null, state);
        _callback = null;
      }
    }
  }

}