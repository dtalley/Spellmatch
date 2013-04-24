package com.orionark.graphics 
{
  import com.orionark.resource.ResourceManager;
  import com.orionark.util.List;
  import flash.display.BitmapData;
  import flash.geom.Matrix;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class Material 
  {
    private var _passes:List = new List();
    
    public function Material() 
    {
      
    }
    
    public function parse(json:Object):void
    {
      for each ( var data:Object in json.passes )
      {
        var pass:Pass = new Pass();
        
        if ( data.dimensions )
        {
          pass.width = data.dimensions.width;
          pass.height = data.dimensions.height;
        }   
        
        if ( data.position )
        {
          pass.u = data.position.x;
          pass.v = data.position.y;
        }   
        
        if ( data.offset )
        {
          pass.x = data.offset.x;
          pass.y = data.offset.y;
        }
        
        if ( data.atlased )
        {
          pass.atlased = true;
          pass.rows = data.rows;
          pass.columns = data.columns;
        }
        
        if ( data.sections )
        {
          for each ( var section:Object in data.sections )
          {
            pass.addSection(section.name, section.row, section.column);
          }
        }
        
        if ( data.texture )
        {
          pass.texture = ResourceManager.get(data.texture).data as Texture;
        }
        
        _passes.push(pass);
      }
    }
    
    public function draw(layer:uint, matr:Matrix = null, section:String = "", offset:uint = 0):void
    {
      _passes.reset();
      var pass:Pass = _passes.next as Pass;
      while ( pass !== null )
      {
        pass.draw(layer, matr, section, offset);
        pass = _passes.next as Pass;
      }
    }
  }
}