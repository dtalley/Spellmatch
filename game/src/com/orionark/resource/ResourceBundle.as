package com.orionark.resource 
{
  import com.orionark.graphics.Material;
  import com.orionark.graphics.Texture;
  import com.orionark.util.List;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
	/**
   * ...
   * @author David Talley
   */
  public class ResourceBundle 
  {
    private var _callback:Function = null;
    private var _paths:List = new List();
    private var _loaded:List = new List();
    
    private var _currentPath:String = null;
    private var _currentExtension:String = null;
    
    public function ResourceBundle() 
    {
      
    }
    
    public function add(path:String):void
    {
      _paths.push(path);
    }
    
    public function load(callback:Function):void 
    {
      _callback = callback;
      
      loadNext();
    }
    
    private function loadNext():void
    {
      if ( _currentPath )
      {
        trace("'" + _currentPath + "' loaded");
        _loaded.push(_currentPath);
      }
      
      if ( _paths.size > 0 )
      {
        loadResource(_paths.shift());
      }
      else
      {
        _callback.apply();
      }
    }
    
    private function loadResource(path:String):void
    {
      _currentPath = path;
      _currentExtension = path.substr(path.lastIndexOf(".") + 1);
      
      ResourceManager.load(_currentPath, _currentExtension, loadNext);
    }
    
    public function remaining():uint
    {
      return _paths.size;
    }
    
    public function unload():void
    {
      while ( _loaded.size > 0 )
      {
        ResourceManager.unregister(_loaded.shift());
      }
    }
  }

}