package com.orionark.graphics 
{
  import flash.display.BitmapData;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class Texture 
  {
    private var _data:BitmapData;
    
    public function Texture(data:BitmapData) 
    {
      _data = data;
    }
    
    public function get data():BitmapData
    {
      return _data;
    }
  }

}