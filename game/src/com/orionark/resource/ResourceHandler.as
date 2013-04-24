package com.orionark.resource 
{
	/**
   * ...
   * @author David Talley
   */
  public class ResourceHandler 
  {
    protected var _path:String = "";
    
    private var _callback:Function = null;
    
    public function ResourceHandler() 
    {
      
    }
    
    public function recognize(extension:String):Boolean 
    {
      return false;
    }
    
    public function handle(path:String, callback:Function):void
    {
      _path = path;
      _callback = callback;
      
      load();
    }
    
    protected function load():void
    {
      
    }
    
    protected function loaded():void
    {
      if ( _callback !== null )
      {
        var callback:Function = _callback;
        _callback = null;
        callback.apply();
      }
    }
  }

}