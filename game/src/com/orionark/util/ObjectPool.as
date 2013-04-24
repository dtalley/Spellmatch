package com.orionark.util 
{
	/**
   * ...
   * @author David Talley
   */
  public class ObjectPool 
  {
    private var _type:Class;
    private var _queue:List = new List();
    
    public function ObjectPool(type:Class) 
    {
      _type = type;
    }
    
    public function create():Object
    {
      if ( _queue.size > 0 )
      {
        return _queue.shift();
      }
      else
      {
        return new _type();
      }
    }
    
    public function release(obj:Object):void
    {
      if ( obj is _type )
      {
        _queue.push(obj);
      }
    }
  }

}