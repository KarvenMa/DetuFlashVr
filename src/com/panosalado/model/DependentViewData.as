
package com.panosalado.model{
	
	final public class DependentViewData extends ViewData {
		
		public static const MINIMUM_FOV:Number = 0.01;
		public static const MAXIMUM_FOV:Number = 179.99;
		
		public var independent:ViewData;
		
		protected var _panOffset:Number;
		protected var _tiltOffset:Number;
		protected var _fieldOfViewOffset:Number;
		protected var _tierThresholdOffset:Number;
		
		public function DependentViewData(independent:ViewData){
			this.independent = independent;
			
			// initialize all vars with "default" values 
			_panOffset = 0;
			_tiltOffset = 0;
			_fieldOfViewOffset = 0;
			_tierThresholdOffset = 0;
			
			super(false);
		}
		
		override public function get pan():Number { return independent._pan + _panOffset; }
		override public function set pan(value:Number):void{
			if (_panOffset == value) return;
			_panOffset = value;
			invalidTransform = invalid = true;
			if (independent.stage) 
			{ independent.stage.invalidate(); }
		}
		
		override public function get tilt():Number { return independent._tilt + _tiltOffset; }
		override public function set tilt(value:Number):void{ 
			if (_tiltOffset == value) return;
			_tiltOffset = value;
			invalidTransform = invalid = true;
			if (independent.stage) independent.stage.invalidate();
		}
		
		override public function get fieldOfView():Number { return independent._fieldOfView + _fieldOfViewOffset; }
		override public function set fieldOfView(value:Number):void{
			if (_fieldOfViewOffset == value) return;
			_fieldOfViewOffset = value;
			invalidPerspective = invalid = true;
			if (independent.stage) independent.stage.invalidate();
		}
	}
}
//override public function get tierThreshold():Number { return independent._tierThreshold + _tierThresholdOffset; }
//override public function set tierThreshold(value:Number):void{
//if (_tierThresholdOffset == value) return;
//_tierThresholdOffset = value;
//invalidPerspective = invalid = true;
//}