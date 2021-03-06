﻿package classes.DataManager 
{
	import classes.DataManager.Errors.VersionUpgraderError;
	import flash.net.SharedObject;
	/**
	 * ...
	 * @author Fenoxo
	 */
	public class SaveVersionUpgrader4 implements ISaveVersionUpgrader 
	{
		private const _newVersionValue = 5;
		
		public function SaveVersionUpgrader4() 
		{}
		
		/**
		 * Do the needful with the incoming data to transition from V1 -> V2
		 * @param	data
		 * @return
		 */
		public function upgrade(data:Object):Boolean
		{
			// We have go iterate over every character...
			for (var k in data.characters)
			{
				trace("Upgrading to V4 " + k + "...");
				
				this.upgradeChar(data.characters[k]);
				
				trace("Upgraded!");
			}
			data.minVersion = 5;
			data.version = this._newVersionValue;
			
			return this.verify(data); // Do sfa with the bool, we're gonna catch the throw exception in DataManager
		}
		
		private function upgradeChar(char:Object):void
		{	
			//Switch over! Assume standard ratio due to lazy.
			for(var x:int; x < char.cocks.length; x++) {
				char.cocks[x].cThicknessRatio = 1;
				delete char.cocks[x].cThickness;
			}
			
		}
		/**
		 * Provide a verification method to ensure the data in the input object is as-expected
		 * @param	data
		 * @return
		 */
		public function verify(data:Object):Boolean
		{
			if (data.version != this._newVersionValue)
			{
				throw new VersionUpgraderError("Upgrader Version 4 recieved data version " + data.version + " during a verification call. Wakka wakka.");
				return false;
			}
			
			if (data.minVersion == undefined)
			{
				trace("wat");
			}
			
			if (data.minVersion == undefined || data.minVersion != this._newVersionValue)
			{
				throw new VersionUpgraderError("MinVersion invalid!");
				return false;
			}
			
			return true;
		}
		
	}

}