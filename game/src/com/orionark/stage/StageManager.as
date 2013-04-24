package com.orionark.stage 
{
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.DisplayObject;
  import flash.display.Stage;
  import flash.geom.Matrix;
  import flash.geom.Point;
  import flash.geom.Rectangle;
	/**
   * ...
   * @author David Talley
   */
  public class StageManager 
  {
    private static var _stage:Stage;
    
    private static var _layers:Vector.<StageLayer> = new Vector.<StageLayer>();
    private static var _canvases:Vector.<Bitmap> = new Vector.<Bitmap>();
    
    private static var _identityMatrix:Matrix = new Matrix();
    
    public static function initialize(stage:Stage):void
    {
      _stage = stage;
    }
    
    public static function get stage():Stage
    {
      return _stage;
    }
    
    public static function lock():void
    {
      for each ( var data:Bitmap in _canvases )
      {
        data.bitmapData.lock();
      }
    }
    
    public static function unlock():void
    {
      for each ( var data:Bitmap in _canvases )
      {
        data.bitmapData.unlock();
      }
    }
    
    public static function draw(data:BitmapData, layer:uint = 0, matr:Matrix = null, rect:Rectangle = null):void
    {
      if ( matr == null )
      {
        matr = _identityMatrix;
      }
      while ( _canvases.length <= layer )
      {
        _canvases.push(new Bitmap(new BitmapData(_stage.stageWidth, _stage.stageHeight, true, 0)));
        addChild(_canvases[_canvases.length - 1], 0);
      }
      if ( containsDistortion(matr) )
      {
        _canvases[layer].bitmapData.draw(data, matr, null, null, rect?rect:null, true);
      }
      else
      {
        _canvases[layer].bitmapData.copyPixels(data, rect?rect:data.rect, new Point(matr.tx, matr.ty), null, null, true);
      }
    }
    
    public static function clear():void
    {
      for each ( var data:Bitmap in _canvases )
      {
        data.bitmapData.fillRect(data.bitmapData.rect, 0);
      }
    }
    
    private static function containsDistortion(matr:Matrix):Boolean
    {
      if ( matr.a != 1 || matr.b != 0 || matr.c != 0 || matr.d != 1 )
      {
        return true;
      }
      return false;
    }
    
    public static function addChild(child:DisplayObject, layer:uint = 0):DisplayObject
    {
      while ( _layers.length <= layer )
      {
        _layers.push(new StageLayer());
        stage.addChild(_layers[_layers.length - 1]);
      }
      
      return _layers[layer].addChild(child);
    }
    
    public static function removeChild(child:DisplayObject):DisplayObject
    {
      if ( child.parent )
      {
        return child.parent.removeChild(child);
      }
      return child;
    }
  }
}