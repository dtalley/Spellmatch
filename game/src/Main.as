package 
{
  import com.spellmatch.DerivedClient;
  import com.orionark.core.GameClient;
  import com.orionark.core.Instantiator;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author David Talley
	 */
  
	public class Main extends Sprite 
	{
		private var _client:GameClient;
    
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			new DerivedClient(stage).begin();
		}
	}
	
}