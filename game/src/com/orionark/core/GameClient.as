package com.orionark.core 
{
  import com.orionark.stage.StageManager;
  import flash.display.Stage;
  
	/**
   * ...
   * @author David Talley
   */
  
  public class GameClient 
  {    
    public function GameClient(stage:Stage) 
    {
      StageManager.initialize(stage);
    }
    
    public function begin():void
    {
      
    }
  }
}