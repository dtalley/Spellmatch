package com.orionark.entity 
{
  import com.orionark.util.ObjectPool;
  import flash.utils.Dictionary;
	/**
   * ...
   * @author David Talley
   */
  public class EntityManager 
  {
    private var _counter:uint = 0;
    private var _entities:Dictionary = new Dictionary(true);
    private var _pool:ObjectPool = new ObjectPool(Entity);
    
    public function EntityManager() 
    {
      
    }
    
    public function create():Entity
    {
      var entity:Entity = _pool.create() as Entity;
      entity.id = _counter;
      _entities[_counter] = entity;
      _counter++;
      return entity;
    }
    
    public function release(entity:Entity):void
    {
      _pool.release(entity);
      delete _entities[entity.id];
    }
    
    public function find(id:uint):Entity
    {
      return _entities[id];
    }
  }

}