package com.orionark.system 
{
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
	/**
   * ...
   * @author David Talley
   */
  public class SystemManager 
  {
    private var _systems:Dictionary = new Dictionary();
    private var _eventManager:EventManager;
    private var _entityManager:EntityManager;
    
    public function SystemManager() 
    {
      _eventManager = new EventManager();
      _entityManager = new EntityManager();
    }
    
    public function get eventManager():EventManager
    {
      return _eventManager;
    }
    
    public function get entityManager():EntityManager
    {
      return _entityManager;
    }
    
    public function add(type:Class):void
    {
      var name:String = getQualifiedClassName(type);
      name = name.substr(name.lastIndexOf("::") + 2);
      if ( _systems[name] )
      {
        _systems[name].destroy();
      }
      var system:System = new type(_eventManager, _entityManager);
      _systems[name] = system;
    }
    
    public function get(id:String):System
    {
      return _systems[id];
    }
    
    public function update(tickLength:Number, render:Boolean):void
    {
      for each ( var system:System in _systems )
      {
        system.update(tickLength, render);
      }
    }
    
    public function destroy():void
    {
      for each ( var system:System in _systems )
      {
        system.destroy();
      }
    }
  }

}