package com.spellmatch.resource 
{
  import com.orionark.graphics.Material;
  import com.orionark.graphics.Texture;
  import com.orionark.resource.Resource;
  import com.orionark.resource.ResourceHandler;
  import com.orionark.resource.ResourceManager;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
	/**
   * ...
   * @author David Talley
   */
  public class MapResourceHandler extends ResourceHandler
  {
    public function MapResourceHandler() 
    {
      
    }
    
    override public function recognize(extension:String):Boolean
    {
      if ( ["map"].indexOf(extension) >= 0 )
      {
        return true;
      }
      return false;
    }
    
    override protected function load():void
    {
      var request:URLRequest = new URLRequest("assets/" + _path);
      var loader:URLLoader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, jsonLoaded);
      loader.addEventListener(IOErrorEvent.IO_ERROR, jsonError);
      loader.load(request);
    }
    
    private function jsonLoaded(e:Event):void
    {
      e.target.removeEventListener(Event.COMPLETE, jsonLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, jsonError);
  
      var json:Object = JSON.parse(e.target.data);
      ResourceManager.register(_path, new Resource(json));
      
      loaded();
    }
    
    private function jsonError(e:IOErrorEvent):void
    {
      e.target.removeEventListener(Event.COMPLETE, jsonLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, jsonError);
      
      trace("JSON error on '" + _path + "'");
      
      loaded();
    }
  }

}