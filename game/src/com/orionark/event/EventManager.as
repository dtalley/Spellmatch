package com.orionark.event 
{
  import flash.utils.Dictionary;
	/**
   * ...
   * @author David Talley
   */
  public class EventManager 
  {
    private var _listeners:Dictionary = new Dictionary();
    
    public function EventManager() 
    {
      
    }
    
    public function on(type:String, callback:Function, context:Object = null, persistent:Boolean = true):void
    {
      if ( _listeners[type] === undefined )
      {
        _listeners[type] = new Vector.<EventDelegate>();
      }
      _listeners[type].push(new EventDelegate(callback, context, persistent));
    }
    
    public function off(type:String, callback:Function):void
    {
      if ( _listeners[type] !== null )
      {
        var current:uint = 0;
        for each ( var delegate:EventDelegate in _listeners[type] )
        {
          if ( delegate.callback == callback )
          {
            _listeners[type].splice(current, 1);
          }
          current++;
        }
      }
    }
    
    public function trigger(type:String, ... args):void
    {
      if ( _listeners[type] !== null )
      {
        var current:uint = 0;
        for each ( var delegate:EventDelegate in _listeners[type] )
        {
          delegate.callback.apply(delegate.context, args);
          if ( !delegate.persistent )
          {
            _listeners[type].splice(current, 1);
          }
          current++;
        }
      }
    }
  }
}

class EventDelegate
{
  private var _callback:Function = null;
  private var _context:Object = null;
  private var _persistent:Boolean = false;
  
  public function EventDelegate(callback:Function, context:Object, persistent:Boolean):void
  {
    _callback = callback;
    _context = context;
    _persistent = persistent;
  }
  
  public function get callback():Function
  {
    return _callback;
  }
  
  public function get context():Object
  {
    return _context;
  }
  
  public function get persistent():Boolean
  {
    return _persistent;
  }
}