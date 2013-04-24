package com.spellmatch.system 
{
  import com.orionark.entity.Entity;
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
  import com.orionark.graphics.Material;
  import com.orionark.graphics.Pass;
  import com.orionark.graphics.Texture;
  import com.orionark.resource.ResourceManager;
  import com.orionark.stage.StageManager;
  import com.orionark.system.System;
  import com.orionark.util.List;
  import com.orionark.util.Random;
  import flash.events.MouseEvent;
  import flash.geom.Matrix;
  import flash.geom.Point;
	/**
   * ...
   * @author David Talley
   */
  public class MapSystem extends System
  {
    //Properties filled in by the config JSON
    private var _gridSpaceSize:Point;
    private var _gridDrawSize:Point;    
    private var _gridPosition:Point;
    
    private var _gridTypes:Vector.<String> = new Vector.<String>();
    
    private var _lanes:uint;
    private var _length:uint;
    
    //Everything else
    private var _gridReference:Vector.<Vector.<Entity>> = new Vector.<Vector.<Entity>>();
    private var _gridSpaces:Vector.<Entity> = new Vector.<Entity>();
    private var _gridMaterials:Vector.<Material> = new Vector.<Material>();
    private var _elementMaterials:Vector.<Material> = new Vector.<Material>();
    
    private var _mouseDown:Boolean = false;
    
    private var _selected:List = new List();
    
    private var _tileMaterial:Material;
    private var _selectedMaterial:Material;
    private var _hoverMaterial:Material;
    private var _tileMatrix:Matrix = new Matrix();
    
    private var _mousePosition:Point = new Point(0, 0);
    
    public function MapSystem(eventManager:EventManager, entityManager:EntityManager) 
    {
      super(eventManager, entityManager);
      
      var mapName:String = "maps/simple_map.map";
      
      var config:Object = ResourceManager.get("json/game_config.json").data as Object;
      var map:Object = ResourceManager.get(mapName).data as Object;
      
      _lanes = map.lanes;
      _length = map.length;
      
      _gridSpaceSize = new Point(config.grid.space.width, config.grid.space.height);
      _gridDrawSize = new Point(config.grid.draw.width, config.grid.draw.height);
      _gridPosition = new Point(map.position.x, map.position.y);
      
      for each( var type:String in map.types )
      {
        _gridTypes.push(type);
      }
      
      _tileMaterial = ResourceManager.get("materials/spaces/grid_space.material").data as Material;
      _selectedMaterial = ResourceManager.get("materials/spaces/grid_selected.material").data as Material;
      _hoverMaterial = ResourceManager.get("materials/spaces/grid_hover.material").data as Material;
      
      StageManager.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
      StageManager.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
      
      _gridMaterials.length = _gridTypes.length;
      _elementMaterials.length = _gridTypes.length;
      for ( var i:int = 0; i < _gridTypes.length; i++ )
      {
        _gridMaterials[i] = ResourceManager.get("materials/spaces/grid_" + _gridTypes[i] + ".material").data as Material;
        _elementMaterials[i] = ResourceManager.get("materials/spaces/element_" + _gridTypes[i] + ".material").data as Material;
      }
      
      _gridReference.length = _lanes;
      for ( i = 0; i < _lanes; i++ )
      {
        _gridReference[i] = new Vector.<Entity>();
        _gridReference[i].length = _length;
        for ( var j:int = 0; j < _gridReference[i].length; j++ )
        {
          var disabled:Boolean = false;
          for each ( var point:Object in map.disable )
          {
            //trace( point.x + ", " + point.y + " / " + i + ", " + j );
            if ( point.x == i && point.y == j )
            {
              trace("Disabled found...");
              _gridReference[i][j] = null;
              disabled = true;
            }
          }
          
          if ( disabled )
          {
            continue;
          }
          
          var space:Entity = _entityManager.create();
          space.set("type", "space");
          changeElement(space);
          space.set("selected", false);
          space.set("gridPosition", new Point(i, j));
          space.set("screenPosition", new Point(_gridPosition.x + ( _gridSpaceSize.x * i), _gridPosition.y + ( _gridSpaceSize.y * j)));
          space.set("spawner", null);
          space.on("changeElement", changeElement);
          _gridReference[i][j] = space;
          
          for each ( var spawnerData:Object in map.spawners )
          {
            if ( spawnerData.x == i && spawnerData.y == j )
            {
              var spawner:Entity = _entityManager.create();
              spawner.set("id", spawnerData.id);
              spawner.set("supply", spawnerData.supply);
              spawner.set("owner", spawnerData.owner);
              spawner.set("opponent", spawnerData.opponent);
              spawner.set("spawnerType", spawnerData.type);
              spawner.set("space", space);
              space.set("spawner", spawner);
            }
          }
          
          _gridSpaces.push(space);
          _eventManager.trigger("gridSpaceCreated", space);
        }
      }
      
      _eventManager.trigger("mapLoaded", mapName);
    }
    
    private function changeElement(space:Entity):void
    {
      space.set("element", Random.nextMinMax(0, _gridTypes.length));
      space.set("elementName", _gridTypes[space.get("element")]);
    }
    
    private function mouseMove(e:MouseEvent):void
    {
      captureMouse();
      if ( _mouseDown )
      {
        selectPosition(_mousePosition);
      }
    }
    
    private function mouseDown(e:MouseEvent):void
    {
      captureMouse();      
      if ( selectPosition(_mousePosition) )
      {
        _mouseDown = true;
        StageManager.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
      }
      else
      {
        _eventManager.trigger("mouseCanceled");
      }
    }
    
    private function mouseUp(e:MouseEvent):void
    {
      _mouseDown = false;
      StageManager.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
      
      _eventManager.trigger("mouseReleased");
      while (_selected.size > 0)
      {
        var space:Entity = _selected.shift();
        space.set("selected", false);
      }
    }
    
    private function selectPosition(point:Point):Boolean
    {
      if ( point.x < 0 || point.x > _lanes-1 || point.y < 0 || point.y > _length-1 )
      {
        return false;
      }
      if ( ( point.x - 1 ) % 2 == 0 && point.y > _length - 2 )
      {
        return false;
      }
      var space:Entity = _gridReference[point.x][point.y];
      if ( space.get("selected") === true )
      {
        return false;
      }
      if ( space.get("spawner") !== null )
      {
        _eventManager.trigger("spawnerClicked", space.get("spawner"));
        return false;
      }
      _selected.reset();
      var current:Entity = _selected.next;
      var adjacent:Boolean = false;
      if ( _selected.size > 0 )
      {
        while ( current !== null )
        {
          if ( checkAdjacency(current, space) )
          {
            adjacent = true;
            break;
          }
          current = _selected.next;
        }
        if ( !adjacent )
        {
          return false;
        }
      }
      space.trigger("trySelect", space);
      if ( space.get("selected") === true )
      {
        _selected.push(space);
        return true;
      }
      return false;
    }
    
    private function checkAdjacency(first:Entity, second:Entity):Boolean
    {
      var fx:int = first.get("gridPosition").x;
      var fy:int = first.get("gridPosition").y;
      var sx:int = second.get("gridPosition").x;
      var sy:int = second.get("gridPosition").y;
      
      if ( 
        ( sx == fx - 1 && sy == fy ) ||
        ( sx == fx + 1 && sy == fy ) ||
        ( sx == fx && sy == fy - 1 ) ||
        ( sx == fx && sy == fy + 1 )
      )
      {
        return true;
      }
      if ( ( fx - 1 ) % 2 == 0 )
      {
        if ( 
         ( sx == fx - 1 && sy == fy + 1 ) ||
         ( sx == fx + 1 && sy == fy + 1 )
        )
        {
          return true;
        }
      }
      else
      {
        if ( 
         ( sx == fx - 1 && sy == fy - 1 ) ||
         ( sx == fx + 1 && sy == fy - 1 )
        )
        {
          return true;
        }
      }
      return false;
    }
    
    private function captureMouse():void
    {
      var usePosition:Point = new Point(StageManager.stage.mouseX - _gridPosition.x, StageManager.stage.mouseY - _gridPosition.y);
      var matches:List = new List();
      var leftLane:int = Math.floor(usePosition.x / _gridSpaceSize.x);
      var rightLane:int = Math.floor((usePosition.x - ( _gridDrawSize.x - _gridSpaceSize.x )) / _gridSpaceSize.x);
      
      matches.push(new Point(leftLane, calculateMouseY(leftLane, usePosition.y)));
      if ( rightLane != leftLane )
      {
        matches.push(new Point(rightLane, calculateMouseY(rightLane, usePosition.y)));
      }
      
      _mousePosition = matches.shift();
      var distance:Number = calculateDistance(usePosition.x, usePosition.y, _mousePosition.x, _mousePosition.y);
      while ( matches.size > 0 )
      {
        var newPosition:Point = matches.shift();
        var newDistance:Number = calculateDistance(usePosition.x, usePosition.y, newPosition.x, newPosition.y);
        if ( newDistance < distance )
        {
          distance = newDistance;
          _mousePosition = newPosition;
        }
      }
    }
    
    private function calculateMouseY(lane:int, y:Number):int
    {
      if ( ( lane - 1 ) % 2 == 0 )
      {
        y -= _gridSpaceSize.y / 2;
      }
      return Math.floor(y / _gridSpaceSize.y);
    }
    
    private function calculateDistance(x:Number, y:Number, gx:int, gy:int):Number
    {
      var usePosition:Point = new Point(_gridSpaceSize.x * gx + _gridDrawSize.x / 2, _gridSpaceSize.y * gy + _gridDrawSize.y / 2);
      if ( ( gx - 1 ) % 2 == 0 )
      {
        usePosition.y += _gridSpaceSize.y / 2;
      }
      return Math.sqrt(Math.pow(usePosition.x - x, 2) + Math.pow(usePosition.y - y, 2));
    }
    
    override public function update(tickLength:Number, render:Boolean):void
    {
      
      
      if ( render )
      {
        this.render();
      }
    }
    
    private function render():void
    {
      var background:Texture = ResourceManager.get("images/maps/default.png").data as Texture;
      StageManager.draw(background.data, 0);
      
      for each ( var space:Entity in _gridSpaces )
      {
        var x:int = space.get("gridPosition").x;
        var y:int = space.get("gridPosition").y;
        drawTile(x, y, _tileMaterial);
        if ( space.get("spawner") === null )
        {
          drawTile(x, y, _elementMaterials[space.get("element")]);
          if ( _mousePosition.x == x && _mousePosition.y == y )
          {
            drawTile(x, y, _hoverMaterial);
          }
        }
        if ( space.get("selected") === true || space.get("charged") === true )
        {
          drawTile(x, y, _selectedMaterial);
        }
      }
    }
    
    private function drawTile(x:int, y:int, material:Material):void
    {
      _tileMatrix.identity();
      if ( (x - 1) % 2 == 0 )
      {
        _tileMatrix.translate(0, _gridSpaceSize.y / 2);
      }
      _tileMatrix.translate(_gridPosition.x + ( _gridSpaceSize.x * x), _gridPosition.y + ( _gridSpaceSize.y * y));
      material.draw(1, _tileMatrix);
    }
  }

}