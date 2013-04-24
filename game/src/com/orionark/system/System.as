package com.orionark.system 
{
  import com.orionark.entity.EntityManager;
  import com.orionark.event.EventManager;
	/**
   * ...
   * @author David Talley
   */
  public class System 
  {
    protected var _eventManager:EventManager;
    protected var _entityManager:EntityManager;
    
    public function System(eventManager:EventManager, entityManager:EntityManager) 
    {
      _eventManager = eventManager;
      _entityManager = entityManager;
    }
    
    public function update(tickLength:Number, render:Boolean):void
    {
      
    }
    
    public function destroy():void
    {
      
    }
  }

}