package com.orionark.graphics 
{
  import com.orionark.stage.StageManager;
  import flash.geom.Matrix;
  import flash.geom.Rectangle;
  import flash.utils.Dictionary;
  import flash.utils.getTimer;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class Pass 
  {
    private var _texture:Texture;
    private var _blending:String;
    
    private var _x:Number = 0;
    private var _y:Number = 0;
    
    private var _atlased:Boolean = false;
    private var _u:Number = 0;
    private var _v:Number = 0;    
    private var _rows:uint = 0;
    private var _columns:uint = 0;
    
    private var _sections:Dictionary = new Dictionary();
    
    private var _width:Number = 0;
    private var _height:Number = 0;
    
    private var _matrix:Matrix = new Matrix();
    
    public function Pass() 
    {
      
    }
    
    public function set texture(texture:Texture):void
    {
      _texture = texture;
      if ( !_atlased )
      {
        _width = _texture.data.width;
        _height = _texture.data.height;
      }
    }
    
    public function set blending(blending:String):void
    {
      _blending = blending;
    }
    
    public function set x(x:Number):void
    {
      _x = x;
    }
    
    public function set y(y:Number):void
    {
      _y = y;
    }
    
    public function set u(u:Number):void
    {
      _u = u;
    }
    
    public function set v(v:Number):void
    {
      _v = v;
    }
    
    public function set width(width:Number):void
    {
      _width = width;
    }
    
    public function set height(height:Number):void
    {
      _height = height;
    }
    
    public function set atlased(atlased:Boolean):void
    {
      _atlased = atlased;
    }
    
    public function set rows(rows:uint):void
    {
      _rows = rows;
    }
    
    public function set columns(columns:uint):void
    {
      _columns = columns;
    }
    
    public function addSection(name:String, row:uint, column:uint):void
    {
      _sections[name] = new PassSection(row, column);
    }
    
    public function draw(layer:uint, matr:Matrix = null, section:String = "", offset:uint = 0):void
    {
      if ( !matr )
      {
        _matrix.identity();
        matr = _matrix;
      }
      matr.translate(_x, _y);
      var rect:Rectangle = new Rectangle(_u, _v, _width, _height);
      
      if ( section && _sections[section] !== undefined )
      {
        offset += _sections[section].row * _columns;
        offset += _sections[section].column;
        rect.x += ( offset % _columns ) * _width;
        rect.y += Math.floor( offset / _columns ) * _height;
      }
      else if ( offset > 0 )
      {
        rect.x += ( offset % _columns ) * _width;
        rect.y += Math.floor( offset / _columns ) * _height;
      }
      
      StageManager.draw(_texture.data, layer, matr, rect);
    }
  }
}

import flash.geom.Rectangle;

class PassSection
{
  private var _row:uint = 0;
  private var _column:uint = 0;
  
  public function PassSection(row:uint, column:uint)
  {
    _row = row;
    _column = column;
  }
  
  public function get row():uint
  {
    return _row;
  }
  
  public function get column():uint
  {
    return _column;
  }
}