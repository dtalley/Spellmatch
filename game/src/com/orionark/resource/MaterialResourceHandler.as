package com.orionark.resource 
{
  import com.orionark.graphics.Material;
  import com.orionark.graphics.Texture;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
	/**
   * ...
   * @author David Talley
   */
  public class MaterialResourceHandler extends ResourceHandler
  {
    public function MaterialResourceHandler() 
    {
      
    }
    
    override public function recognize(extension:String):Boolean
    {
      if ( ["material"].indexOf(extension) >= 0 )
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
      var material:Material = new Material();
      material.parse(json);
      ResourceManager.register(_path, new Resource(material));
      
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