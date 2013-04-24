package com.orionark.resource 
{
  import com.orionark.graphics.Texture;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLRequest;
  import flash.system.ApplicationDomain;
  import flash.system.LoaderContext;
  import flash.system.SecurityDomain;
	/**
   * ...
   * @author David Talley
   */
  public class SWFResourceHandler extends ResourceHandler
  {
    public function SWFResourceHandler() 
    {
      
    }
    
    override public function recognize(extension:String):Boolean
    {
      if ( ["swf"].indexOf(extension) >= 0 )
      {
        return true;
      }
      return false;
    }
    
    override protected function load():void
    {
      var request:URLRequest = new URLRequest("assets/" + _path);
      var loader:Loader = new Loader();
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, swfLoaded);
      loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, swfError);
      var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain);
      loader.load(request, context);
    }
    
    private function swfLoaded(e:Event):void
    {
      e.target.removeEventListener(Event.COMPLETE, swfLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, swfError);
      
      loaded();
    }
    
    private function swfError(e:IOErrorEvent):void
    {
      e.target.removeEventListener(Event.COMPLETE, swfLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, swfError);
      
      trace("SWF error on '" + _path + "'");
      
      loaded();
    }
  }

}