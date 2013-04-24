package com.orionark.util 
{
	/**
   * ...
   * @author David Talley
   */
  public class Tree 
  {
    private var _current:TreeNode = null;
    private var _root:TreeNode = new TreeNode(null);
    
    public function Tree() 
    {
      reset();
    }
    
    public function reset():void
    {
      _current = _root;
    }
    
    public function add(data:*):void
    {
      if ( _current === null )
      {
        _root = _current = new TreeNode(data);
      }
      else
      {
        _current = _current.add(data);
      }
    }
    
    public function set(data:*):void
    {
      if ( _current !== null )
      {
        _current.leaf = data;
      }
    }
    
    public function move(data:*):Boolean
    {
      var retrieve:TreeNode = _current.get(data);
      if ( retrieve !== null )
      {
        _current = retrieve;
        return true;
      }
      return false;
    }
    
    public function get leaf():*
    {
      if ( _current !== null )
      {
        return _current.leaf;
      }
      return null;
    }
  }

}

import com.orionark.util.List;

class TreeNode
{
  private var _data:*;
  private var _leaf:* = null;
  private var _children:List = new List();
  
  public function TreeNode(data:*):void
  {
    _data = data;
  }
  
  public function get data():*
  {
    return _data;
  }
  
  public function add(data:*):TreeNode
  {
    _children.reset();
    var current:TreeNode = _children.next;
    while ( current !== null )
    {
      if ( current.data == data )
      {
        return current;
      }
      current = _children.next;
    }
    return _children.push(new TreeNode(data));
  }
  
  public function get leaf():*
  {
    return _leaf;
  }
  public function set leaf(val:*):void
  {
    _leaf = val;
  }
  
  public function get(data:*):TreeNode
  {
    _children.reset();
    var current:TreeNode = _children.next;
    while ( current !== null )
    {
      if ( current.data == data )
      {
        return current;
      }
      current = _children.next;
    }
    return null;
  }
}