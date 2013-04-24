package com.orionark.util 
{
  
	/**
   * ...
   * @author David Talley
   */
  
  public class List 
  {
    private var _first:ListNode = null;
    private var _last:ListNode = null;
    private var _size:uint = 0;
    
    private var _current:ListNode = null;
    
    public function List(... args) 
    {
      for ( var i:int = 0; i < args.length; i++ )
      {
        push(args[i]);
      }
    }
    
    public function reset():void
    {
      _current = _first;
    }
    
    public function get first():*
    {
      if ( _first !== null )
      {
        return _first.data;
      }
      return null;
    }
    
    public function get last():*
    {
      if ( _last !== null )
      {
        return _last.data;
      }
      return null;
    }
    
    public function get next():*
    {
      if ( _current !== null )
      {
        var ret:* = _current.data;
        _current = _current.next;
        return ret;
      }
      return null;
    }
    
    public function remove():void
    {
      if ( _current !== null && _current.previous !== null )
      {
        if ( _current.previous == _first )
        {
          _first = _current;
        }
        _current.previous = _current.previous.previous;
        _size--;
      }
      else if ( _current === null && _last !== null )
      {
        if ( _last === _first )
        {
          _first = null;
        }
        _last = _last.previous;
        if ( _last !== null )
        {
          _last.next = null;
        }
        _size--;
      }
    }
    
    public function get size():uint
    {
      return _size;
    }
    
    public function push(data:*):*
    {
      if ( _last !== null )
      {
        _last.next = new ListNode(data);
        _last = _last.next;
      }
      else
      {
        _first = _last = new ListNode(data);
      }
      _size++;
      return data;
    }
    
    public function pop():*
    {
      var ret:* = null;
      if ( _last != null )
      {
        ret = _last.data;
        if ( _first == _last )
        {
          _first = _last = null;
        }
        else
        {
          _last = _last.previous;
        }
        _size--;
      }
      return ret;
    }
    
    public function unshift(data:*):*
    {
      if ( _first !== null )
      {
        _first.previous = new ListNode(data);
        _first = _first.previous;
      }
      else
      {
        _first = _last = new ListNode(data);
      }
      _size++;
      return data;
    }
    
    public function shift():*
    {
      var ret:* = null;
      if ( _first != null )
      {
        ret = _first.data;
        if ( _last == _first )
        {
          _last = _first = null;
        }
        else
        {
          _first = _first.next;
        }
        _size--;
      }
      return ret;
    }
  }
}

class ListNode
{
  private var _data:* = null;
  
  private var _next:ListNode = null;
  private var _previous:ListNode = null;
  
  public function ListNode(data:*)
  {
    _data = data;
  }
  
  public function get data():*
  {
    return _data;
  }
  
  public function set data(data:*):void
  {
    _data = data;
  }
  
  public function get next():ListNode
  {
    return _next;
  }
  
  public function set next(next:ListNode):void
  {
    _next = next;
    if ( next !== null && next.previous != this )
    {
      next.previous = this;
    }
  }
  
  public function get previous():ListNode
  {
    return _previous;
  }
  
  public function set previous(previous:ListNode):void
  {
    _previous = previous;
    if ( previous !== null && previous.next != this )
    {
      previous.next = this;
    }
  }
}