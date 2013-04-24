package com.spellmatch 
{
  import com.orionark.core.GameClient;
  import com.orionark.stage.StageManager;
  import com.orionark.state.StateManager;
  import com.spellmatch.state.GameState;
	import flash.display.Stage;
	
	/**
	 * ...
	 * @author David Talley
	 */
	
	public class DerivedClient extends GameClient
	{		
		public function DerivedClient(stage:Stage) 
		{
			super(stage);
		}
    
    override public function begin():void
    {
      StateManager.dock(GameState);
      StateManager.load(null);
    }
	}
}