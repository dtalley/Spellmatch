package com.orionark.state 
{
	/**
   * ...
   * @author David Talley
   */
  public class State 
  {
    private var _callback:Function;
    
    public function State() 
    {
      
    }
    
    public function dock():void
    {
      
    }
    
    public function prepare(loadedCallback:Function):void
    {
      _callback = loadedCallback;
      load();
    }
    
    protected function load():void
    {
      
    }
    
    protected function loaded():void
    {
      if ( _callback !== null )
      {
        _callback.apply(null, [this]);
      }
      _callback = null;
    }
    
    public function destroy():void
    {
      
    }
  }

}