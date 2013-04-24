package com.orionark.entity 
{
  import com.orionark.event.EventManager;
  import flash.utils.Dictionary;
	/**
   * ...
   * @author David Talley
   */
  public class Entity extends EventManager
  {
    private var _id:uint;
    private var _properties:Dictionary = new Dictionary();
    
    public function Entity() 
    {
      
    }
    
    public function clear():void
    {
      _properties = new Dictionary();
    }
    
    public function extend(other:Entity, exclude:Array = null):void
    {
      for ( var key:String in _properties )
      {        
        other.set(key, _properties[key]);
      }
    }
    
    public function get id():uint
    {
      return _id;
    }
    
    public function set id(id:uint):void
    {
      _id = id;
    }
    
    public function get(id:String):*
    {
      return _properties[id];
    }
    
    public function set(id:String, value:*):void
    {
      _properties[id] = value;
    }
  }

}