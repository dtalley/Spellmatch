package com.spellmatch.system 
{
  import com.orionark.entity.Entity;
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
  import com.orionark.graphics.Material;
  import com.orionark.resource.ResourceManager;
  import com.orionark.stage.StageManager;
  import com.orionark.system.System;
  import com.orionark.util.List;
  import com.orionark.util.Random;
  import com.orionark.util.Tree;
  import flash.events.MouseEvent;
  import flash.geom.Matrix;
  import flash.geom.Point;
	/**
   * ...
   * @author David Talley
   */
  public class SpellSystem extends System
  {    
    //Properties filled in by the config JSON
    private var _gridSpaceSize:Point;
    private var _gridDrawSize:Point;    
    private var _gridPosition:Point;
    
    //Other properties
    private var _gridReference:Vector.<Vector.<Entity>> = new Vector.<Vector.<Entity>>();
    private var _spaces:Vector.<Entity> = new Vector.<Entity>();
    private var _selected:List = new List();
    
    private var _activeSpells:List = new List();
    
    private var _spells:Tree = new Tree();
    private var _spell:Entity = null;
    
    private var _matrix:Matrix = new Matrix();
    
    public function SpellSystem(eventManager:EventManager, entityManager:EntityManager) 
    {
      super(eventManager, entityManager);
      
      var config:Object = ResourceManager.get("json/game_config.json").data as Object;
      var map:Object = ResourceManager.get("maps/simple_map.map").data as Object;
      
      _gridSpaceSize = new Point(config.grid.space.width, config.grid.space.height);
      _gridDrawSize = new Point(config.grid.draw.width, config.grid.draw.height);
      _gridPosition = new Point(map.position.x, map.position.y);
      
      var spells:Array = ResourceManager.get("json/game_spells.json").data as Array;
      
      for each( var spellData:Object in spells )
      {
        for each ( var space:String in spellData.spaces )
        {
          _spells.add(space);
        }
        
        var spell:Entity = _entityManager.create();
        spell.clear();
        spell.set("type", "spellType");
        spell.set("name", spellData.name);
        spell.set("material", ResourceManager.get(spellData.material).data as Material);
        spell.set("frames", spellData.frames);
        spell.set("effectFrame", spellData.effect_frame);
        spell.set("section", spellData.section);
        spell.set("step", 1.0 / spellData.fps);
        spell.set("growth", spellData.growth);
        spell.set("damage", spellData.damage);
        spell.set("stun", spellData.stun);
        spell.set("stunDuration", spellData.stun_duration);
        spell.set("push", spellData.push);
        spell.set("pushDuration", spellData.push_duration);
        spell.set("heal", spellData.heal);
        spell.set("chain", spellData.chain);
        spell.set("poison", spellData.poison);
        spell.set("poisonDuration", spellData.poison_duration);
        spell.set("protect", spellData.protect);
        spell.set("protectDuration", spellData.protect_duration);
        _spells.set(spell);
        _spells.reset();
      }
      
      _eventManager.on("gridSpaceCreated", gridSpaceCreated);
      _eventManager.on("mouseReleased", mouseReleased);
      _eventManager.on("mouseCanceled", mouseCanceled);
    }
    
    private function gridSpaceCreated(space:Entity):void
    {
      _spaces.push(space);
      space.on("trySelect", trySelect);
      
      var point:Point = space.get("gridPosition");
      if ( _gridReference.length < point.x + 1 )
      {
        _gridReference.length = point.x + 1;
        _gridReference[point.x] = new Vector.<Entity>();
      }
      _gridReference[point.x][point.y] = space;
    }
    
    private function mouseCanceled():void
    {
      if ( !_spell )
      {
        return;
      }
      _spell = null;
      
      while ( _selected.size > 0 )
      {
        var charged:Entity = _selected.shift() as Entity;
        charged.set("charged", false);
      }
    }
    
    private function trySelect(space:Entity):void
    {
      if ( _spell !== null )
      {
        var deselect:Boolean = false;
        if (space.get("active") === true)
        {
          //deselect = true;
          return;
        }
        if (!deselect)
        {
          configureSpace(_spell, space, 0);
          
          if ( _spell.get("growth") > 0 )
          {
            growSpell(_spell, space, _spell.get("growth"), 0.2);
          }
          if ( _spell.get("chain") > 0 )
          {
            var chainChecksum:int = Random.nextInt();
            chainSpell(_spell, space, _spell.get("chain"), chainChecksum, 0.1);
          }
          
          _activeSpells.push(_spell);
        }
        _spell = null;
        
        while ( _selected.size > 0 )
        {
          var charged:Entity = _selected.shift() as Entity;
          if ( !deselect )
          {
            charged.trigger("changeElement", charged);
          }
          charged.set("charged", false);
        }
      }
      else
      {
        var element:String = space.get("elementName");
        if ( _spells.move(element) )
        {
          space.set("selected", true);
          space.set("charged", true);
          _selected.push(space);
          return;
        }
      }
    }
    
    private function configureSpace(spell:Entity, space:Entity, delay:Number):void
    {
      space.set("spellAccumulator", 0.0);
      space.set("spellFrame", 0);
      space.set("spellDelay", delay);
      space.set("active", true);
      
      spell.get("spaces").push(space);
    }
    
    private function growSpell(spell:Entity, space:Entity, growth:int, delay:Number):void
    {
      if ( growth == 0 )
      {
        return;
      }
      var added:List = new List();
      var neighbors:List = getSpaceNeighbors(space);
      while ( neighbors.size > 0 )
      {
        var neighbor:Entity = neighbors.shift() as Entity;
        configureSpace(spell, neighbor, delay);
        added.push(neighbor);
      }
      while ( added.size > 0 )
      {
        growSpell(spell, added.shift(), growth - 1, delay + 0.2);
      }
    }
    
    private function chainSpell(spell:Entity, space:Entity, chance:Number, checksum:int, delay:Number):void
    {
      if ( space.get("chainChecksum") === checksum )
      {
        return;
      }
      space.set("chainChecksum", checksum);
      if ( space.get("active") !== true )
      {
        configureSpace(spell, space, delay);
      }
      var neighbors:List = getSpaceNeighbors(space);
      while ( neighbors.size > 0 )
      {
        var neighbor:Entity = neighbors.shift() as Entity;
        var check:Number = Random.nextNumber();
        if ( check < chance )
        {          
          chainSpell(spell, neighbor, chance*.8, checksum, delay+0.1);
        }
      }
    }
    
    private function getSpaceNeighbors(space:Entity):List
    {
      var x:int = space.get("gridPosition").x;
      var y:int = space.get("gridPosition").y;
      var neighbors:List = new List();
      
      addNeighbor(x + 1, y, neighbors);
      addNeighbor(x - 1, y, neighbors);
      addNeighbor(x, y + 1, neighbors);
      addNeighbor(x, y - 1, neighbors);
      if ( ( x - 1 ) % 2 == 0 )
      {
        addNeighbor(x - 1, y + 1, neighbors);
        addNeighbor(x + 1, y + 1, neighbors);
      }
      else
      {
        addNeighbor(x - 1, y - 1, neighbors);
        addNeighbor(x + 1, y - 1, neighbors);
      }
      return neighbors;
    }
    
    private function addNeighbor(x:int, y:int, neighbors:List):void
    {
      if ( x >= 0 && _gridReference.length > x )
      {
        if ( y >= 0 && _gridReference[x].length > y )
        {
          if ( _gridReference[x][y].get("active") !== true && _gridReference[x][y].get("spawner") === null )
          {
            neighbors.push(_gridReference[x][y]);
          }
        }
      }
    }
    
    private function mouseReleased():void
    {
      if ( _spells.leaf is Entity )
      {
        var spell:Entity = _spells.leaf as Entity;
        prepareSpell(spell);
      }
      _spells.reset();
    }
    
    private function prepareSpell(spell:Entity):void
    {
      var instance:Entity = _entityManager.create();
      instance.clear();
      spell.extend(instance);
      //_activeSpells.push(instance);
      instance.set("type", "spell");
      instance.set("spaces", new List());
      instance.set("owner", 1);
      
      _spell = instance;
    }
    
    override public function update(tickLength:Number, render:Boolean):void
    {
      _activeSpells.reset();
      var current:Entity = _activeSpells.next;
      while (current !== null)
      {
        current.get("spaces").reset();
        var space:Entity = current.get("spaces").next;
        while ( space !== null )
        {
          var delay:Number = space.get("spellDelay");
          if ( delay > 0 )
          {
            delay -= tickLength;
            space.set("spellDelay", delay);
          }
          else
          {
            var spellAccumulator:Number = space.get("spellAccumulator");
            var step:Number = current.get("step");
            spellAccumulator += tickLength;
            var remove:Boolean = false;
            while ( spellAccumulator >= step )
            {
              var frame:uint = space.get("spellFrame");
              if ( frame == current.get("effectFrame") )
              {
                activateSpell(current, space);
              }
              frame++;
              space.set("spellFrame", frame);
              if ( frame == current.get("frames") )
              {
                space.set("active", false);
                current.get("spaces").remove();
              }
              spellAccumulator -= step;
            }
            space.set("spellAccumulator", spellAccumulator);
          }
          space = current.get("spaces").next;
        }
        if ( current.get("spaces").size == 0 )
        {
          _activeSpells.remove();
          _entityManager.release(current);
        }
        current = _activeSpells.next;
      }
      
      if ( render )
      {
        this.render();
      }
    }
    
    private function activateSpell(spell:Entity, space:Entity):void
    {
      if ( spell.get("damage") > 0 )
      {
        space.trigger("damageUnits", space, spell.get("owner"), spell.get("damage"));
      }
      if ( spell.get("heal") > 0 )
      {
        space.trigger("healUnits", space, spell.get("owner"), spell.get("heal"));
      }
      if ( spell.get("push") > 0 )
      {
        space.trigger("pushUnits", space, spell.get("owner"), spell.get("push"), spell.get("pushDuration"));
      }
      if ( spell.get("poison") > 0 )
      {
        space.trigger("poisonUnits", space, spell.get("owner"), spell.get("poison"), spell.get("poisonDuration"));
      }
      if ( spell.get("stun") > 0 )
      {
        space.trigger("stunUnits", space, spell.get("owner"), spell.get("stun"), spell.get("stunDuration"));
      }
      if ( spell.get("protect") > 0 )
      {
        space.trigger("protectUnits", space, spell.get("owner"), spell.get("protect"), spell.get("protectDuration"));
      }
    }
    
    private function render():void
    {
      _activeSpells.reset();
      var current:Entity = _activeSpells.next;
      while (current !== null)
      {
        var spaces:List = current.get("spaces");
        spaces.reset();
        var space:Entity = spaces.next;
        while ( space !== null )
        {
          if ( space.get("spellDelay") <= 0 )
          {
            var x:int = space.get("gridPosition").x;
            var y:int = space.get("gridPosition").y;
            _matrix.identity();
            if ( (x - 1) % 2 == 0 )
            {
              _matrix.translate(0, _gridSpaceSize.y / 2);
            }
            _matrix.translate(_gridPosition.x + ( _gridSpaceSize.x * x), _gridPosition.y + ( _gridSpaceSize.y * y));
            current.get("material").draw(4, _matrix, current.get("section"), space.get("spellFrame"));
          }
          
          space = spaces.next;
        }
        
        current = _activeSpells.next;
      }
    }
  }

}