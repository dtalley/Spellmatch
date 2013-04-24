package com.orionark.core 
{
  import flash.display.Bitmap;
  import flash.utils.getDefinitionByName;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class Instantiator 
  {    
    public static function exists(id:String):Boolean
    {
      try
      {
        getDefinitionByName(id);
        return true;
      }
      catch ( e:ReferenceError )
      {
        return false;
      }
      return false;
    }
    public static function create(id:String, type:Class, argCount:uint = 0, ... args):Object
    {
      try
      {
        var temp:Class = getDefinitionByName(id) as Class;
        switch( argCount )
        {
          case 4:
            return new temp(args[0], args[1], args[2], args[3]);
            break;
          case 3:
            return new temp(args[0], args[1], args[2]);
            break;
          case 2:
            return new temp(args[0], args[1]);
            break;
          case 1:
            return new temp(args[0]);
            break;
          default:
            return new temp();
            break;
        }
      }
      catch ( e:ReferenceError )
      {
        return null;
      }
      return null;
    }
  }

}