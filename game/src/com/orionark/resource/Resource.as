package com.orionark.resource 
{  
	/**
   * ...
   * @author David Talley
   */
  
  public class Resource 
  {
    private var _data:*;
    
    public function Resource(data:*) 
    {
      _data = data;
    }
    
    public function get data():*
    {
      return _data;
    }
  }
}