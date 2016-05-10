
package com.panosalado.controller{
	
	import com.panosalado.controller.ICamera;
	import com.panosalado.events.CameraEvent;
	import com.panosalado.model.CameraKeyBindings;
	import com.panosalado.model.Characteristics;
	import com.panosalado.model.KeyboardCameraData;
	import com.panosalado.model.ViewData;
	import com.panosalado.utils.Inertion;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	
	public class KeyboardCamera extends EventDispatcher implements ICamera {
		
		protected var _canvas:Sprite;
		protected var _stage:Stage;
		protected var _viewData:ViewData;
		protected var _cameraData:KeyboardCameraData;
		
		private var __lastTimeStamp:Number;
		
		private var deltaPan:Number;
		private var deltaTilt:Number;
		private var deltaFieldOfView:Number;
		
		private var keyIsDown:Boolean;
		
		private var go_up:Boolean;
		private var go_down:Boolean;
		private var go_left:Boolean;
		private var go_right:Boolean;
		private var go_in:Boolean;
		private var go_out:Boolean;
		
		private var inertialPan:Inertion;
		private var inertialTilt:Inertion;
		private var inertialFieldOfView:Inertion;
		
		public function KeyboardCamera(){
			deltaPan = 0;
			deltaTilt = 0;
			deltaFieldOfView = 0;
			
			keyIsDown = false;
			go_up = false;
			go_down = false;
			go_left = false;
			go_right = false;
			go_in = false;
			go_out = false;
		}
		
		public function processDependency(reference:Object,characteristics:*):void {
			if (characteristics == Characteristics.VIEW_DATA) viewData = reference as ViewData;
			else if (characteristics == Characteristics.KEYBOARD_CAMERA_DATA) cameraData = reference as KeyboardCameraData;
		}
	
	protected function keyDownEvent( event:KeyboardEvent ):void{
			
			switch( event.keyCode )
			{
			case CameraKeyBindings.UP:
				go_up = true;
			break;
			case CameraKeyBindings.DOWN:
				go_down = true;
			break;
			case CameraKeyBindings.LEFT:
				go_left = true;
			break;
			case CameraKeyBindings.RIGHT:
				go_right = true;
			break;
			case CameraKeyBindings.IN:
				go_in = true;
			break;
			case CameraKeyBindings.OUT:
				go_out = true;
			break;
			default:
				break;
			}
			
			if (!keyIsDown) {
				dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
				_stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
			keyIsDown = true;
		}
		
		protected function keyUpEvent(event:KeyboardEvent):void{
		
			switch(event.keyCode){
				case CameraKeyBindings.UP:
				go_up = false;
				break;
				case CameraKeyBindings.DOWN:
					go_down = false;
				break;
				case CameraKeyBindings.LEFT:
					go_left = false;
				break;
				case CameraKeyBindings.RIGHT:
					go_right = false;
				break;
				case CameraKeyBindings.IN:
					go_in = false;
				break;
				case CameraKeyBindings.OUT:
					go_out = false;
				break;
				}
			if (!go_up && !go_down && !go_left && !go_right && !go_in && !go_out) {
				keyIsDown = false;
			}
		}
		
		private function stageOutOfFocus(event:Event):void {
			keyIsDown = false;
		}
		
		private function enterFrameHandler(event:Event):void {

			_viewData.pan -= deltaPan * _viewData._fieldOfView / 90;
			
			if (_viewData.tilt + deltaTilt < -90 ) {_viewData.tilt = -90} else
			if (_viewData.tilt + deltaTilt > 90 ) {_viewData.tilt = 90} else
			
			_viewData.tilt += deltaTilt * _viewData._fieldOfView / 90;
			
			viewData.fieldOfView += deltaFieldOfView;
			
			if (keyIsDown){
				if (go_right) { deltaPan  = inertialPan.decrement(); } else
				if (go_left) { deltaPan  = inertialPan.increment(); } else
				deltaPan  = inertialPan.aimZero();
				
				if (go_up) { deltaTilt = inertialTilt.increment(); } else
				if (go_down) { deltaTilt = inertialTilt.decrement(); } else
				deltaTilt = inertialTilt.aimZero();
				
				if (go_in) { deltaFieldOfView = inertialFieldOfView.decrement(); } else
				if (go_out) { deltaFieldOfView = inertialFieldOfView.increment(); } else
				deltaFieldOfView = inertialFieldOfView.aimZero();
			
			}else {
				if (deltaPan != 0 || deltaTilt != 0 || deltaFieldOfView !=0) {
					if (deltaPan != 0) deltaPan = inertialPan.aimZero();
					if (deltaTilt != 0) deltaTilt = inertialTilt.aimZero();
					if (deltaFieldOfView != 0) deltaFieldOfView = inertialFieldOfView.aimZero();
				}else {
					_stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
				}
			}
		}
		
		protected function enabledChangeHandler(e:Event):void {
			if (_stage == null) return;
			if(_cameraData.enabled) {
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent, false, 0, true );
				_stage.addEventListener(KeyboardEvent.KEY_UP, keyUpEvent, false, 0, true);
				_stage.addEventListener(Event.DEACTIVATE, stageOutOfFocus, false, 0, true);
			}else{
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
				_stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpEvent);
				_stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				_stage.removeEventListener(Event.DEACTIVATE, stageOutOfFocus);
			}
		}
		
		public function get cameraData():KeyboardCameraData { return _cameraData; }
		public function set cameraData(value:KeyboardCameraData):void{
			if (value === _cameraData) return;
			if (value != null) {
				value.addEventListener(CameraEvent.ENABLED_CHANGE, enabledChangeHandler, false, 0, true);
				inertialPan = new Inertion(value.directionSpeed, value.sensitivity, value.friction);
				inertialTilt = new Inertion(value.directionSpeed, value.sensitivity, value.friction);
				inertialFieldOfView = new Inertion(value.zoomSpeed, value.sensitivity, value.friction);
			}else if (value == null && _cameraData != null) {
				_cameraData.removeEventListener(CameraEvent.ENABLED_CHANGE, enabledChangeHandler);
			}
			_cameraData = value;
		}
		
		public function get stageReference():Stage { return _stage; }
		public function set stageReference(value:Stage):void{
			if ( _stage === value ) return;
			if ( value != null && _cameraData!= null && _cameraData.enabled){ // TODO: what if cameraData is not loaded?
				value.addEventListener( KeyboardEvent.KEY_DOWN, keyDownEvent, false, 0, true );
				value.addEventListener( KeyboardEvent.KEY_UP, keyUpEvent, false, 0, true);
				value.addEventListener( Event.DEACTIVATE, stageOutOfFocus, false, 0, true);
			}
			else if(value == null && _stage != null ){
				_stage.removeEventListener( KeyboardEvent.KEY_DOWN, keyDownEvent );
				_stage.removeEventListener( KeyboardEvent.KEY_UP, keyUpEvent );
				_stage.removeEventListener( Event.ENTER_FRAME, enterFrameHandler );
				_stage.removeEventListener( Event.DEACTIVATE, stageOutOfFocus);
			}
			_stage = value;
		}
		
		public function get viewData():ViewData { return _viewData; }
		public function set viewData(value:ViewData):void{
			_viewData = value;
		}
	}
}