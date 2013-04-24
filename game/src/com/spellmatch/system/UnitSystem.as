package com.spellmatch.system 
{
  import com.greensock.easing.Linear;
  import com.greensock.TweenLite;
  import com.orionark.entity.Entity;
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
  import com.orionark.graphics.Material;
  import com.orionark.resource.ResourceManager;
  import com.orionark.stage.StageManager;
  import com.orionark.system.System;
  import com.orionark.util.List;
  import com.orionark.util.Random;
  import flash.display.BitmapData;
  import flash.events.MouseEvent;
  import flash.geom.Matrix;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.utils.Dictionary;
  import flash.utils.getTimer;
	/**
   * ...
   * @author David Talley
   */
  public class UnitSystem extends System
  {    
    //Properties filled in by the config JSON
    private var _gridSpaceSize:Point;
    private var _gridDrawSize:Point;    
    private var _gridPosition:Point;
    
    private var _moveRate:Number;
    private var _availableSpaces:int;
    private var _totalSpaces:int;
    
    //Everything else
    private var _soldierFrontMaterial:Material;
    private var _soldierBackMaterial:Material;
    
    private var _spawnerTypeReference:Dictionary = new Dictionary();
    private var _projectileTypeReference:Dictionary = new Dictionary();
    private var _effectTypeReference:Dictionary = new Dictionary();
    private var _weaponTypeReference:Dictionary = new Dictionary();
    private var _unitTypeReference:Dictionary = new Dictionary();
    
    private var _spawnerReference:Dictionary = new Dictionary();
    
    private var _spawners:Vector.<Entity> = new Vector.<Entity>();
    private var _units:Vector.<Entity> = new Vector.<Entity>();
    private var _spaces:Vector.<Entity> = new Vector.<Entity>();
    private var _projectiles:Vector.<Entity> = new Vector.<Entity>();
    
    private var _schedule:List = new List();
    
    private var _deadPool:List = new List(); // Ha...    
    private var _unitPool:List = new List();
    private var _projectilePool:List = new List();
    
    private var _gridReference:Vector.<Vector.<Entity>> = new Vector.<Vector.<Entity>>();
    
    private var _moveAccumulator:Number = 0;
    private var _timeAccumulator:Number = 0;
    
    private var _matrix:Matrix = new Matrix();
    
    public function UnitSystem(eventManager:EventManager, entityManager:EntityManager) 
    {
      super(eventManager, entityManager);
      
      var config:Object = ResourceManager.get("json/game_config.json").data as Object;
      var map:Object = ResourceManager.get("maps/simple_map.map").data as Object;
      
      _moveRate = config.move_rate;
      _availableSpaces = config.available_spaces;
      _totalSpaces = config.total_spaces;
      
      _gridSpaceSize = new Point(config.grid.space.width, config.grid.space.height);
      _gridDrawSize = new Point(config.grid.draw.width, config.grid.draw.height);
      _gridPosition = new Point(map.position.x, map.position.y);
      
      var effects:Array = ResourceManager.get("json/game_effects.json").data as Array;
      for each ( var effectData:Object in effects )
      {
        var effect:Entity = _entityManager.create();
        effect.set("frames", effectData.frames);
        effect.set("step", 1.0 / effectData.fps);
        effect.set("material", ResourceManager.get(effectData.material).data as Material);
        
        _effectTypeReference[effectData.id] = effect;
      }
      
      var projectiles:Array = ResourceManager.get("json/game_projectiles.json").data as Array;
      for each ( var projectileData:Object in projectiles )
      {
        var projectile:Entity = _entityManager.create();
        projectile.set("angles", projectileData.angles);
        projectile.set("frames", projectileData.frames);
        projectile.set("step", 1.0 / projectileData.fps);
        projectile.set("effect", _effectTypeReference[projectileData.effect]);
        projectile.set("material", ResourceManager.get(projectileData.material).data as Material);
        
        _projectileTypeReference[projectileData.id] = projectile;
      }
      
      var weapons:Array = ResourceManager.get("json/game_weapons.json").data as Array;
      for each ( var weaponData:Object in weapons )
      {
        var weapon:Entity = _entityManager.create();
        weapon.set("damage", weaponData.damage);
        weapon.set("rate", weaponData.rate);
        weapon.set("speed", weaponData.speed);
        weapon.set("projectile", _projectileTypeReference[weaponData.projectile]);
        
        _weaponTypeReference[weaponData.id] = weapon;
      }
      
      var units:Array = ResourceManager.get("json/game_units.json").data as Array;      
      for each ( var unitData:Object in units )
      {
        var unit:Entity = _entityManager.create();
        unit.set("type", "unitType");
        unit.set("name", unitData.name);
        unit.set("level", unitData.level);
        unit.set("health", unitData.health);
        unit.set("moveSpeed", unitData.move_speed);
        unit.set("baseMoveSpeed", unitData.move_speed);
        unit.set("attackSpeed", unitData.attack_speed);
        unit.set("baseAttackSpeed", unitData.attack_speed);
        unit.set("maxHealth", unitData.health);
        unit.set("attack", unitData.attack);
        unit.set("baseAttack", unitData.attack);
        unit.set("flying", unitData.flying);
        unit.set("baseFlying", unitData.flying);
        unit.set("size", unitData.size);
        unit.set("baseSize", unitData.size);
        unit.set("material", ResourceManager.get(unitData.material).data as Material);        
        
        if ( unitData.animations !== null )
        {
          var animations:Dictionary = new Dictionary();
          for each ( var animation:Object in unitData.animations )
          {
            animations[animation.name] = { section: animation.name, frames: animation.frames, step: 1.0/animation.fps };
          }
          unit.set("animations", animations);
          changeUnitAnimation(unit, "front_standing", "back_standing");
        }
        
        unit.set("weapon", null);
        if ( _weaponTypeReference[unitData.weapon] !== undefined )
        {
          unit.set("weapon", _weaponTypeReference[unitData.weapon]);
        }
        
        _unitTypeReference[unitData.id] = unit;
      }
      
      var spawners:Array = ResourceManager.get("json/game_spawners.json").data as Array;
      for each ( var spawnerData:Object in spawners )
      {
        var spawner:Entity = _entityManager.create();
        spawner.set("type", "spawnerType");
        spawner.set("rate", spawnerData.rate);
        spawner.set("level", spawnerData.level);
        spawner.set("health", spawnerData.health);
        spawner.set("targets", spawnerData.targets);
        spawner.set("damage", spawnerData.damage);
        spawner.set("material", ResourceManager.get(spawnerData.material).data as Material);
        spawner.set("slots", spawnerData.slots);
        spawner.set("weapon", _weaponTypeReference[spawnerData.weapon]);
        spawner.set("availableUnits", new Vector.<Entity>());
        
        for each ( var unitID:String in spawnerData.units )
        {
          if ( _unitTypeReference[unitID] !== undefined )
          {
            spawner.get("availableUnits").push(_unitTypeReference[unitID]);
          }
        }
        
        _spawnerTypeReference[spawnerData.id] = spawner;
      }
      
      _eventManager.on("gridSpaceCreated", gridSpaceCreated);
      _eventManager.on("mapLoaded", mapLoaded);
      _eventManager.on("spawnerClicked", spawnerClicked);
    }
    
    private function mapLoaded(name:String):void
    {
      var map:Object = ResourceManager.get(name).data as Object;
      var schedule:Array = map.schedule;
      var total:int = schedule.length;
      for ( var i:int = 0; i < total; i++ )
      {
        _schedule.push(schedule[i]);
      }
    }
    
    private function spawnerClicked(spawner:Entity):void
    {
      if ( spawner.get("owner") == 1 )
      {
        createUnit(_unitTypeReference["grunt"], spawner);
      }
    }
    
    private function gridSpaceCreated(space:Entity):void
    {
      if ( space.get("spawner") !== null )
      {
        var spawner:Entity = space.get("spawner");
        if ( _spawnerTypeReference[spawner.get("spawnerType")] !== undefined )
        {
          _spawnerTypeReference[spawner.get("spawnerType")].extend(spawner);
          _spawnerReference[spawner.get("id")] = spawner;
          spawner.set("type", "spawner");
          spawner.set("accumulator", 0.0);      
          spawner.set("attackAccumulator", 0.0);
          spawner.set("target", null);
          spawner.set("position", space.get("gridPosition").clone());
          _spawners.push(spawner);
        }
      }
      
      var point:Point = space.get("gridPosition");
      if ( _gridReference.length < point.x + 1 )
      {
        _gridReference.length = point.x + 1;
        _gridReference[point.x] = new Vector.<Entity>();
      }
      _gridReference[point.x][point.y] = space;
      
      space.set("units", new Vector.<Entity>());
      space.set("unitCounts", Vector.<int>([0, 0]));
      space.set("unitReservations", Vector.<int>([0, 0]));
      space.set("unitPositions", Vector.<int>([0, 0]));
      
      space.on("damageUnits", damageUnits);
      space.on("healUnits", healUnits);
      space.on("pushUnits", pushUnits);
      space.on("stunUnits", stunUnits);
      space.on("poisonUnits", poisonUnits);
      space.on("protectUnits", protectUnits);
    }
    
    private function damageUnits(space:Entity, owner:int, amount:int):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") != owner )
          {
            var health:int = unit.get("health");
            health -= amount;
            unit.set("health", health);
            if ( health <= 0 )
            {
              killUnit(unit);
              i--;
            }
          }
        }
      }
    }
    
    private function healUnits(space:Entity, owner:int, amount:int):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") == owner )
          {
            var health:int = unit.get("health");
            health += amount;
            if ( health >= unit.get("maxHealth") )
            {
              health = unit.get("maxHealth");
            }
            unit.set("health", health);
          }
        }
      }
    }
    
    private function protectUnits(space:Entity, owner:int, chance:Number, duration:Number):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") == owner )
          {
            if ( Random.nextNumber() < chance )
            {
              unit.set("protected", true);
              unit.set("protectCount", duration);
            }
          }
        }
      }
    }
    
    private function stunUnits(space:Entity, owner:int, chance:Number, duration:Number):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") != owner )
          {
            if ( Random.nextNumber() < chance )
            {
              unit.set("stunned", true);
              unit.set("stunCount", duration);
              changeUnitAnimation(unit, "front_stunned", "back_stunned");
            }
            else
            {
              //trace("Stun failed...");
            }
          }
        }
      }
    }
    
    private function pushUnits(space:Entity, owner:int, chance:Number, duration:Number):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") != owner )
          {
            if ( Random.nextNumber() < chance )
            {
              if ( unit.get("pushed") === true )
              {
                continue;
              }
              unit.set("pushed", true);
              changeUnitTarget(unit, -1);
              unit.set("moveSpeed", unit.get("moveSpeed") * 2);
            }
            else
            {
              //trace("Push failed...");
            }
          }
        }
      }
    }
    
    private function poisonUnits(space:Entity, owner:int, chance:Number, duration:Number):void
    {
      var units:Vector.<Entity> = space.get("units");
      if ( units.length > 0 )
      {
        for ( var i:int = 0; i < units.length; i++ )
        {
          var unit:Entity = units[i];
          if ( unit.get("owner") != owner )
          {
            if ( Random.nextNumber() < chance )
            {
              unit.set("poisoned", true);
              unit.set("poisonCount", duration);
              unit.set("poisonHealth", unit.get("health"));
              unit.set("health", 1);
            }
            else
            {
              //trace("Poison failed...");
            }
          }
        }
      }
    }
    
    override public function update(tickLength:Number, render:Boolean):void
    {
      _timeAccumulator += tickLength;
      _moveAccumulator += tickLength;
      var moves:int = Math.floor(_moveAccumulator / _moveRate);
      _moveAccumulator %= _moveRate;
      
      for ( var i:int = 0; i < _units.length; i++ )
      {
        var unit:Entity = _units[i];
        
        if ( unit.get("destroyed") === true )
        {
          _units.splice(i, 1);
          _unitPool.push(unit);
          i--;
          continue;
        }
        
        updateUnit(unit, tickLength);
      }
      
      while( _deadPool.size > 0 )
      {
        unit = _deadPool.shift();
        unit.set("dead", true);
      }
      
      for ( i = 0; i < _projectiles.length; i++ )
      {
        var projectile:Entity = _projectiles[i];
        
        if ( projectile.get("complete") === true )
        {
          _projectiles.splice(i, 1);
          _projectilePool.push(projectile);
          i--;
          continue;
        }
        
        updateProjectile(projectile, tickLength);
      }
      
      for ( i = 0; i < _spawners.length; i++ )
      {
        var spawner:Entity = _spawners[i];
        updateSpawner(spawner, tickLength);
      }
      
      while ( _schedule.size > 0 && _timeAccumulator >= _schedule.first.time )
      {
        processSchedule(_spawnerReference[_schedule.first.spawner], _schedule.shift());
      }
      
      if ( render )
      {
        this.render();
      }
    }
    
    private function updateSpawner(spawner:Entity, tickLength:Number):void
    {
      var space:Entity = spawner.get("space");
      if ( space.get("unitCounts")[spawner.get("opponent")] > 0 )
      {
        performAttack(spawner, tickLength);
      }
      
      /*var accumulator:Number = spawner.get("accumulator");
      var rate:int = spawner.get("rate");
      accumulator += tickLength;    
      if ( accumulator >= rate )
      {
        accumulator -= rate;
        spawnUnit(spawner);
      }
      spawner.set("accumulator", accumulator);*/
    }
    
    private function processSchedule(spawner:Entity, data:Object):void
    {
      var units:Array = data.units;
      var total:int = units.length;
      for ( var i:int = 0; i < total; i++ )
      {
        for ( var j:int = 0; j < units[i].count; j++ )
        {
          spawnUnit(spawner, _unitTypeReference[units[i].type]);
        }
      }
    }
    
    private function spawnUnit(spawner:Entity, unitType:Entity):void
    {
      if ( spawner.get("space").get("unitReservations")[spawner.get("owner")] >= spawner.get("slots") )
      {
        trace("Can't spawn unit, spawner is full");
        return;
      }
      else if ( spawner.get("supply") == 0 )
      {
        trace("Spawner is out of units...");
        //return;
      }
      trace("Spawning unit...");
      createUnit(unitType, spawner);
      
      /*if ( spawner.get("supply") > 0 )
      {
        spawner.set("supply", spawner.get("supply") - 1);
      }
      
      var units:Vector.<Entity> = spawner.get("availableUnits");
      var level:Number = spawner.get("level");
      var random:Number = Random.nextNumber();
      var possible:List = new List();
      var chosen:int = 0;
      for ( var i:uint = 1; i <= level; i++ )
      {
        if ( random <= Math.log(i / level * Math.E) * .8 )
        {
          chosen = i;
        }
      }
      if ( chosen == 0 )
      {
        return;
      }
      for ( i = 0; i < units.length; i++ )
      {
        var unit:Entity = units[i];
        if ( unit.get("level") == chosen )
        {
          possible.push(unit);
        }
      }
      random = Random.nextNumber();
      var current:int = 1;
      possible.reset();
      unit = possible.next as Entity;
      while ( unit !== null )
      {
        if ( random <= Math.log(current / possible.size * Math.E) )
        {
          createUnit(unit, spawner);
          return;
        }
        unit = possible.next as Entity;
      }*/
    }
    
    private function createUnit(unit:Entity, spawner:Entity):void
    {      
      var space:Entity = spawner.get("space");
      var newUnit:Entity = null;
      if ( _unitPool.size > 0 )
      {
        newUnit = _unitPool.shift();
      }
      else
      {
        newUnit = _entityManager.create();
      }
      unit.extend(newUnit);
      newUnit.set("type", "unit");
      newUnit.set("owner", spawner.get("owner"));
      newUnit.set("opponent", spawner.get("opponent"));
      newUnit.set("dying", false);
      newUnit.set("dead", false);
      newUnit.set("destroyed", false);
      newUnit.set("stunned", false);
      newUnit.set("stunCount", 0);
      newUnit.set("poisoned", false);
      newUnit.set("poisonCount", 0);
      newUnit.set("poisonHealth", 0);
      newUnit.set("positionBit", 0);
      newUnit.set("moveAccumulator", 0.0);
      newUnit.set("attackAccumulator", 0.0);
      newUnit.set("target", null);
      newUnit.set("spawner", spawner);
      newUnit.set("spawned", true);      
      newUnit.set("space", null);
      newUnit.set("targetSpace", null);
      
      var position:Point = new Point(space.get("gridPosition").x, space.get("gridPosition").y);
      if ( directUnit(newUnit, new List(position)) )
      {
        newUnit.set("position", position.clone());
        newUnit.set("space", newUnit.get("targetSpace"));
        addUnitToSpace(newUnit, newUnit.get("space"));
        changeUnitAnimation(newUnit, "front_standing", "back_standing"); 
        _units.push(newUnit);
      }
      else
      {
        trace("Can't spawn unit, destroying...");
        _entityManager.release(newUnit);
      }
    }
    
    private function updateProjectile(projectile:Entity, tickLength:Number):void
    {
      if ( projectile.get("target").get("dying") === true )
      {
        projectile.set("complete", true);
        return;
      }
      
      if ( projectile.get("impacted") !== true )
      {
        var vector:Point = projectile.get("target").get("position").subtract(projectile.get("position"));
        if ( vector.length > 0 )
        {
          var distance:Number = projectile.get("speed") * tickLength;
          if ( vector.length < distance )
          {
            //We have impact
            distance = vector.length;
            projectile.set("impacted", true);
            projectile.set("accumulator", 0.0);
            projectile.set("frame", 0);
            projectile.set("frames", projectile.get("effect").get("frames"));
            projectile.set("step", projectile.get("effect").get("step"));
            
            var target:Entity = projectile.get("target");
            var health:int = target.get("health");
            health -= projectile.get("damage");
            target.set("health", health);
            if ( health <= 0 && target.get("dying") !== true )
            {
              killUnit(target);
            }
          }
          var percent:Number = distance / vector.length;
          projectile.get("position").x += vector.x * percent;
          projectile.get("position").y += vector.y * percent;
        }
      }
      
      if ( projectile.get("frames") > 1 )
      {
        var accumulator:Number = projectile.get("accumulator");
        var step:Number = projectile.get("step");
        accumulator += tickLength;
        while ( accumulator >= step )
        {
          var frame:uint = projectile.get("frame");
          var frames:uint = projectile.get("frames");
          frame++;
          if ( projectile.get("impacted") === true && frame == frames )
          {
            projectile.set("complete", true);
          }
          frame %= frames;
          projectile.set("frame", frame);
          accumulator -= step;
        }
        projectile.set("accumulator", accumulator);
      }
    }
    
    private function updateUnit(unit:Entity, tickLength:Number):void
    {       
      if ( unit.get("dead") !== true )
      {        
        if ( unit.get("poisoned") === true )
        {
          unit.set("poisonCount", unit.get("poisonCount") - tickLength);
          if ( unit.get("poisonCount") <= 0 )
          {
            unit.set("poisoned", false);
            unit.set("health", unit.get("poisonHealth"));
          }
        }
        if ( unit.get("protected") === true )
        {
          unit.set("protectCount", unit.get("protectCount") - tickLength);
          if ( unit.get("protectCount") <= 0 )
          {
            unit.set("protected", false);
          }
        }
        if ( unit.get("stunned") === true )
        {
          unit.set("stunCount", unit.get("stunCount") - tickLength);
          if ( unit.get("stunCount") <= 0 )
          {
            unit.set("stunned", false);
            changeUnitAnimation(unit, "front_standing", "back_standing");
          }
        }
        moveUnit(unit, tickLength);
      }
      
      var animationAccumulator:Number = unit.get("animationAccumulator");
      var step:Number = unit.get("animation").step;
      animationAccumulator += tickLength;
      while ( animationAccumulator >= step )
      {
        var animation:Object = unit.get("animation");
        var frame:uint = unit.get("frame");
        if ( unit.get("dead") === true && frame >= animation.frames - 2 )
        {
          unit.set("destroyed", true);
        }
        frame++;
        frame %= animation.frames;
        unit.set("frame", frame);
        animationAccumulator -= step;
      }
      unit.set("animationAccumulator", animationAccumulator);
    }
    
    private function changeUnitAnimation(unit:Entity, animation:String, alternate:String = ""):void
    {
      if ( unit.get("animations")[animation] === undefined )
      {
        return;
      }
      if ( alternate !== "" && unit.get("animations")[alternate] === undefined )
      {
        return;
      }
      
      if ( alternate !== "" && unit.get("owner") == 1 )
      {
        unit.set("animation", unit.get("animations")[alternate]);
      }
      else
      {
        unit.set("animation", unit.get("animations")[animation]);
      }
      unit.set("frame", 0);
      unit.set("animationAccumulator", 0);
    }
    
    private function moveUnit(unit:Entity, tickLength:Number):void
    {
      var oldSpace:Entity = unit.get("space");
      var attackSuccess:Boolean = false;
      
      if ( oldSpace !== null )
      {
        if ( 
          oldSpace.get("unitPositions")[unit.get("opponent")] != 0 ||
          oldSpace.get("unitCounts")[unit.get("opponent")] > 0
        )
        {
          if ( oldSpace.get("unitCounts")[unit.get("opponent")] > 0 )
          {
            attackSuccess = performAttack(unit, tickLength);
          }
          else if ( oldSpace.get("unitPositions")[unit.get("opponent")] != 0 )
          {
            attackSuccess = true;
          }
        }
        else if ( oldSpace.get("spawner") !== null && oldSpace.get("spawner").get("owner") == unit.get("opponent") )
        {
          //Attack the spanwer!!!!
          //killUnit(unit);
          //return;
          attackSuccess = true;
        }
      }
      
      if ( unit.get("dying") === true )
      {
        return;
      }
      
      unit.set("moving", true);
      var vector:Point = unit.get("targetPosition").subtract(unit.get("position"));
      if ( vector.length > 0 && unit.get("targetSpace") !== null )
      {
        var distance:Number = unit.get("moveSpeed") * tickLength;
        if ( vector.length < distance )
        {
          distance = vector.length;
        }
        var percent:Number = distance / vector.length;
        unit.get("position").x += vector.x * percent;
        unit.get("position").y += vector.y * percent;
        
        checkUnitPosition(unit);
      }
      else if( !attackSuccess )
      {
        if ( unit.get("pushed") === true )
        {
          unit.set("pushed", false);
          unit.set("moveSpeed", unit.get("baseMoveSpeed"));
        }
        changeUnitTarget(unit);
      }
      else
      {
        unit.set("moving", false);
      }
    }
    
    private function changeUnitTarget(unit:Entity, modifier:int = 1):void
    {
      var x:Number = unit.get("space").get("gridPosition").x;
      var y:Number = unit.get("space").get("gridPosition").y;
      var possiblePositions:List = new List();
      var affector:int = unit.get("owner") == 0 ? 1 : -1;
      getForwardPositions(x, y, affector * modifier, possiblePositions);
      directUnit(unit, possiblePositions);
    }
    
    private function checkUnitPosition(unit:Entity):void
    {
      var x:Number = unit.get("space").get("gridPosition").x;
      var y:Number = unit.get("space").get("gridPosition").y;
      var newy:int = Math.round(unit.get("position").y);
      var newx:int = Math.round(unit.get("position").x);
      if ( newy != y || newx != x )
      {
        if ( newx >= 0 && _gridReference.length > newx && newy >= 0 && _gridReference[newx].length > newy )
        {
          removeUnitFromSpace(unit, unit.get("space"));
          addUnitToSpace(unit, _gridReference[newx][newy]);
        }
      }
    }
    
    private function getForwardPositions(x:int, y:int, affector:int, list:List):void
    {
      list.push(new Point(x, y + affector));
      //return;
      if ( ( x - 1 ) % 2 == 0 )
      {
        if ( affector > 0 )
        {
          if ( x > 0 && _gridReference[x-1] != null && y < _gridReference[x-1].length-1 && _gridReference[x-1][y+1] !== null )
          {
            list.push(new Point(x - 1, y + 1));
          }
          if ( x < _gridReference.length-1 && _gridReference[x+1] != null && y < _gridReference[x+1].length-1 && _gridReference[x+1][y+1] !== null )
          {
            list.push(new Point(x + 1, y + 1));
          }
        }
        else
        {
          if ( x > 0 && _gridReference[x-1] != null && _gridReference[x-1][y] !== null )
          {
            list.push(new Point(x - 1, y));
          }
          if ( x < _gridReference.length-1 && _gridReference[x+1] != null && _gridReference[x+1][y] !== null )
          {
            list.push(new Point(x + 1, y));
          }
        }
      }
      else
      {
        if ( affector > 0 )
        {
          if ( x > 0 && _gridReference[x-1] != null && _gridReference[x-1][y] !== null )
          {
            list.push(new Point(x - 1, y));
          }
          if ( x < _gridReference.length-1 && _gridReference[x+1] != null && _gridReference[x+1][y] !== null )
          {
            list.push(new Point(x + 1, y));
          }
        }
        else
        {
          if ( x > 0 && _gridReference[x-1] != null && y > 0 && _gridReference[x-1][y-1] !== null )
          {
            list.push(new Point(x - 1, y - 1));
          }
          if ( x < _gridReference.length-1 && _gridReference[x+1] != null && y > 0 && _gridReference[x+1][y-1] !== null )
          {
            list.push(new Point(x + 1, y - 1));
          }
        }
      }
    }
    
    private function directUnit(unit:Entity, possiblePositions:List):Boolean
    {
      while (possiblePositions.size > 0)
      {
        var targetPosition:Point = possiblePositions.shift();
        if ( targetPosition.x < 0 || targetPosition.x >= _gridReference.length )
        {
          continue;
        }
        if ( targetPosition.y < 0 || targetPosition.y >= _gridReference[targetPosition.x].length )
        {
          continue;
        }
        var newSpace:Entity = _gridReference[targetPosition.x][targetPosition.y];      
        if ( newSpace.get("spawner") !== null && newSpace.get("spawner").get("owner") == unit.get("owner") && unit.get("spawned") === false )
        {
          continue;
        }
        unit.set("spawned", false);
        if ( newSpace.get("unitReservations")[unit.get("owner")] < _availableSpaces )
        {
          if ( calculateUnitPosition(unit, targetPosition, newSpace) )
          {
            unit.set("targetPosition", targetPosition);
            unit.set("targetSpace", newSpace);
            changeUnitAnimation(unit, "front_moving", "back_moving");            
            return true;
          }
        }
      }
      return false;
    }
    
    private function killUnit(unit:Entity):void
    {
      unit.set("dying", true);
      _deadPool.push(unit);
      changeUnitAnimation(unit, "front_death", "back_death");
      removeUnitFromSpace(unit, unit.get("space"));
      clearUnitTarget(unit);
    }
    
    private function removeUnitFromSpace(unit:Entity, space:Entity):void
    {
      space.get("unitCounts")[unit.get("owner")]--;
      space.get("units").splice(space.get("units").indexOf(unit), 1);
    }
    
    private function addUnitToSpace(unit:Entity, space:Entity):void
    {
      space.get("unitCounts")[unit.get("owner")]++;
      space.get("units").push(unit);
      unit.set("space", space);
    }
    
    private function clearUnitTarget(unit:Entity):void
    {
      if ( unit.get("targetSpace") !== null )
      {
        unit.get("targetSpace").get("unitPositions")[unit.get("owner")] ^= unit.get("positionBit");
        unit.get("targetSpace").get("unitReservations")[unit.get("owner")]--;
        unit.set("targetSpace", null);
      }
    }
    
    private function acquireAttackerTarget(attacker:Entity):Boolean
    {
      var space:Entity = attacker.get("space");
      attacker.set("target", null);
      for ( var i:int = 0; i < space.get("units").length; i++ )
      {
        var other:Entity = space.get("units")[i];
        if ( other.get("owner") == attacker.get("opponent") && other.get("dying") !== true )
        {
          //If we don't have a target yet, get one
          if ( attacker.get("target") === null )
          {
            attacker.set("target", other);
          }
          //Otherwise, don't target a protected unit
          else if ( attacker.get("target").get("protected") !== true )
          {
            //If our current target is protected, or this new target's health is lower than our current target, acquire new target
            if ( attacker.get("target").get("protected") === true || attacker.get("target").get("health") > other.get("health") )
            {
              attacker.set("target", other);
            }
          }
        }
      }
      return attacker.get("target") !== null;
    }
    
    private function performAttack(attacker:Entity, tickLength:Number):Boolean
    {
      var target:Entity = attacker.get("target");
      if ( target === null || target.get("dying") === true || attacker.get("space") !== target.get("space") || target.get("protected") === true )
      {
        if ( !acquireAttackerTarget(attacker) )
        {
          attacker.set("attackAccumulator", 0.0);
          return false;
        }
        target = attacker.get("target");
      }
      if ( attacker.get("type") == "unit" )
      {
        if ( attacker.get("dying") !== true )
        {
          changeUnitAnimation(attacker, "front_standing", "back_standing");
        }
        if ( attacker.get("moving") === true || attacker.get("stunned") === true )
        {
          return true;
        }
      }
      if ( target.get("protected") === true || target.get("moving") === true )
      {
        return true;
      }
      
      var weapon:Entity = attacker.get("weapon");
      if ( weapon === null )
      {
        return true;
      }
      
      var attackAccumulator:Number = attacker.get("attackAccumulator");
      attackAccumulator += tickLength;
      var speed:Number = weapon.get("rate");
      while ( attackAccumulator >= speed )
      {
        var projectile:Entity = null;
        if ( _projectilePool.size > 0 )
        {
          projectile = _projectilePool.shift();
        }
        else
        {
          projectile = _entityManager.create();
        }
        weapon.get("projectile").extend(projectile);
        projectile.set("type", "projectile");
        projectile.set("target", target);
        projectile.set("position", attacker.get("position").clone());
        projectile.set("damage", weapon.get("damage"));
        projectile.set("speed", weapon.get("speed"));
        projectile.set("impacted", false);
        projectile.set("complete", false);
        projectile.set("accumulator", 0.0);
        _projectiles.push(projectile);
        
        attackAccumulator -= speed;
      }
      attacker.set("attackAccumulator", attackAccumulator);
      return true;
    }
    
    private var _testPositions:Vector.<int> = Vector.<int>([3, 2, 4, 1, 5, 0, 6]);
    private function calculateUnitPosition(unit:Entity, point:Point, space:Entity):Boolean
    {
      var owner:int = unit.get("owner");      
      var positions:int = space.get("unitPositions")[owner];
      var test:int = 0;
      for ( var i:int = 0; i < unit.get("size"); i++ )
      {
        test <<= 1;
        test |= 1;
      }
      var current:int = 0;
      var useCurrent:int = _testPositions[current];
      var begin:int = current;
      var bits:int = unit.get("positionBit");
      if ( ( bits & positions ) != 0 )
      {
        bits = 0;
      }
      if ( bits == 0 )
      {
        bits = 0 | ( test << useCurrent );
      }
      else
      {
        useCurrent = 0;
        var seq:int = bits;
        while ( ( seq & 1 ) == 0 )
        {
          seq >>= 1;
          useCurrent++;
        }
        current = _testPositions.indexOf(useCurrent);
        begin = current;
      }
      
      while (true)
      {
        useCurrent = _testPositions[current];
        if ( ( bits & positions ) == 0 )
        {
          positions |= bits;
          space.get("unitPositions")[owner] = positions;
          space.get("unitReservations")[owner]++;
          clearUnitTarget(unit);
          unit.set("positionBit", bits);
          var affector:int = owner == 1 ? 1 : -1;
          var spread:Number = 0.96;
          var offsetx:Number = ( spread / 2 * affector ) + ( ( spread / ( _totalSpaces - 1 ) ) * useCurrent ) * affector * -1;
          var offsety:Number = 0.15 * affector;
          offsety += ( 1 - Math.abs((useCurrent - Math.floor( _totalSpaces / 2 )) / Math.floor( _totalSpaces / 2 )) ) * 0.25 * affector;
          if ( ( point.x - 1 ) % 2 == 0 )
          {
            point.y += 0.5;
          }
          point.x += offsetx;
          point.y += offsety - ( 0.5 * getExtraHeight(point.x) );
          return true;
        }
        current++;
        current %= _totalSpaces;
        if ( current == begin )
        {
          break;
        }
        useCurrent = _testPositions[current];
        bits = 0 | ( test << useCurrent );
      }
      return false;
    }
    
    private function unitMoveCompleted(unit:Entity):void
    {
      unit.set("moving", false);
    }
    
    private function render():void
    {
      for each ( var unit:Entity in _units )
      {
        _matrix.identity();
        _matrix.translate(_gridDrawSize.x / 2, _gridDrawSize.y / 2);
        _matrix.translate(0, ( _gridSpaceSize.y / 2 ) * getExtraHeight(unit.get("position").x));
        _matrix.translate(_gridPosition.x + ( _gridSpaceSize.x * unit.get("position").x), _gridPosition.y + ( _gridSpaceSize.y * unit.get("position").y));
        unit.get("material").draw(2, _matrix, unit.get("animation").section, unit.get("frame"));
        
        if ( ( unit.get("health") < unit.get("maxHealth") || unit.get("protected") === true || unit.get("stunned") === true ) && unit.get("health") > 0 )
        {
          var map:BitmapData = new BitmapData(11, 5, false, 0x000000);
          if ( unit.get("stunned") === true )
          {
            map.fillRect(new Rectangle(0, 0, 11 * ( unit.get("health") / unit.get("maxHealth") ), 5), 0xFFFF00);
          }
          else if ( unit.get("protected") === true )
          {
            map.fillRect(new Rectangle(0, 0, 11, 5), 0x00FFFF);
          }
          else
          {
            map.fillRect(new Rectangle(0, 0, 11 * ( unit.get("health") / unit.get("maxHealth") ), 5), 0x00FF00);
          }
          StageManager.draw(map, 3, _matrix);
        }
        
        /*_matrix.identity();
        _matrix.translate(_gridDrawSize.x / 2, _gridDrawSize.y / 2);
        _matrix.translate(0, ( _gridSpaceSize.y / 2 ) * getExtraHeight(unit.get("targetPosition").x));
        _matrix.translate(_gridPosition.x + ( _gridSpaceSize.x * unit.get("targetPosition").x), _gridPosition.y + ( _gridSpaceSize.y * unit.get("targetPosition").y));
        _matrix.translate( -1, -1);
        var smap:BitmapData = new BitmapData(3, 3, false, unit.get("owner")==0?0xFFFF00:0xFF00FF);
        StageManager.draw(smap, 2, _matrix);*/
      }
      
      for each ( var projectile:Entity in _projectiles )
      {
        _matrix.identity();
        _matrix.translate(_gridDrawSize.x / 2, _gridDrawSize.y / 2);
        _matrix.translate(0, ( _gridSpaceSize.y / 2 ) * getExtraHeight(projectile.get("position").x));
        _matrix.translate(_gridPosition.x + ( _gridSpaceSize.x * projectile.get("position").x), _gridPosition.y + ( _gridSpaceSize.y * projectile.get("position").y));
        _matrix.translate( -1, -1);
        var pmap:BitmapData = new BitmapData(3, 3, false, 0xFFFFFF);
        StageManager.draw(pmap, 3, _matrix);
      }
      
      for each ( var spawner:Entity in _spawners )
      {
        _matrix.identity();
        var space:Entity = spawner.get("space");
        if ( ( space.get("gridPosition").x - 1 ) % 2 == 0 )
        {
          _matrix.translate(0, _gridSpaceSize.y / 2);
        }
        _matrix.translate(_gridPosition.x + ( _gridSpaceSize.x * space.get("gridPosition").x), _gridPosition.y + ( _gridSpaceSize.y * space.get("gridPosition").y));
        //spawner.get("material").draw(3, _matrix);
      }
    }
    
    private function getExtraHeight(x:Number):Number
    {
      var floor:int = Math.floor(x);
      var ceil:int = Math.ceil(x);
      var floorCheck:Boolean = ( floor - 1 ) % 2 == 0;
      if ( floor == ceil )
      {
        if ( floorCheck )
        {
          return 1;
        }
      }
      else if ( floorCheck )
      {
        return (1 - Math.abs( floor - x ));
      }
      else
      {
        return (1 - Math.abs( ceil - x ));
      }
      return 0;
    }
  }

}