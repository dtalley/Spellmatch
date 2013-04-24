package com.orionark.resource 
{
  import com.orionark.util.List;
  import flash.utils.Dictionary;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class ResourceManager 
  {
    private static var _handlers:List = new List();
    
    private static var _resources:Dictionary = new Dictionary();
    
    public static function enable(type:Class):void
    {
      _handlers.push(new type());
    }
    
    public static function load(path:String, extension:String, callback:Function):void
    {
      _handlers.reset();
      var handler:ResourceHandler = _handlers.next as ResourceHandler;
      while ( handler !== null )
      {
        if ( handler.recognize(extension) )
        {
          handler.handle(path, callback);
          return;
        }
        handler = _handlers.next as ResourceHandler;
      }
    }
    
    public static function register(path:String, resource:Resource):void
    {
      var split:Array = path.split("/");
      var current:Dictionary = _resources;
      while ( split.length > 0 )
      {
        var branch:String = split.shift();
        if ( split.length == 0 )
        {
          current[branch] = resource;
        }
        else
        {
          if ( !current[branch] )
          {
            current[branch] = new Dictionary();
          }
          current = current[branch];
        }
      }
    }
    
    public static function unregister(path:String):void
    {
      var split:Array = path.split("/");
      var current:Dictionary = _resources;
      while ( split.length > 0 )
      {
        var branch:String = split.shift();
        if ( split.length == 0 )
        {
          delete current[branch];
        }
        else
        {
          if ( !current[branch] )
          {
            current[branch] = new Dictionary();
          }
          current = current[branch];
        }
      }
    }
    
    public static function get(path:String):Resource
    {
      var split:Array = path.split("/");
      var current:Dictionary = _resources;
      while ( split.length > 0 )
      {
        var branch:String = split.shift();
        if ( split.length == 0 )
        {
          return current[branch];
        }
        else
        {
          if ( !current[branch] )
          {
            return null;
          }
          current = current[branch];
        }
      }
      return null;
    }
  }

}