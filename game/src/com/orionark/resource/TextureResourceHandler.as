package com.orionark.resource 
{
  import com.orionark.graphics.Texture;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLRequest;
	/**
   * ...
   * @author David Talley
   */
  public class TextureResourceHandler extends ResourceHandler
  {
    public function TextureResourceHandler() 
    {
      
    }
    
    override public function recognize(extension:String):Boolean
    {
      if ( ["jpg", "jpeg", "png", "gif"].indexOf(extension) >= 0 )
      {
        return true;
      }
      return false;
    }
    
    override protected function load():void
    {
      var request:URLRequest = new URLRequest("assets/" + _path);
      var loader:Loader = new Loader();
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
      loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
      loader.load(request);
    }
    
    private function imageLoaded(e:Event):void
    {
      e.target.removeEventListener(Event.COMPLETE, imageLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, imageError);
      
      var texture:Texture = new Texture(e.target.content.bitmapData);
      ResourceManager.register(_path, new Resource(texture));
      
      loaded();
    }
    
    private function imageError(e:IOErrorEvent):void
    {
      e.target.removeEventListener(Event.COMPLETE, imageLoaded);
      e.target.removeEventListener(IOErrorEvent.IO_ERROR, imageError);
      
      trace("Image error on '" + _path + "'");
      
      loaded();
    }
  }

}