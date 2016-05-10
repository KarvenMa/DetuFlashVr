
package com.panosalado.controller{
	
	import com.panosalado.controller.ICamera;
	import com.panosalado.core.PanoSalado;
	import com.panosalado.events.AutorotationEvent;
	import com.panosalado.events.CameraEvent;
	import com.panosalado.events.ViewEvent;
	import com.panosalado.loading.LoadingStatistics;
	import com.panosalado.model.AutorotationCameraData;
	import com.panosalado.model.Characteristics;
	import com.panosalado.model.ViewData;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class AutorotationCamera extends EventDispatcher implements ICamera{
		protected var _stage:Stage;
		protected var _viewData:ViewData;
		protected var _futureViewData:ViewData;
		
		private var __neutralTilt:Number;
		private var __neutralFieldOfView:Number;
		
		protected var _cameraData:AutorotationCameraData;
		
		private var __lastTimeStamp:Number;
		private var __delayTimer:Timer;
		protected var _running:Boolean;
		
		protected var _loadingStatistics:LoadingStatistics;
		protected var _render:Function;
		
		protected var _renderCount:int;
		
		private var rotationDirection:Number = 1;
		
		private var hasMovedValue:Number=0;
		
		public function AutorotationCamera() {
			_running = false;
			_renderCount = 0;
		}
		
		public function processDependency(reference:Object,characteristics:*):void {
			if (characteristics == Characteristics.VIEW_DATA) viewData = reference as ViewData;
			else if (characteristics == Characteristics.AUTOROTATION_CAMERA_DATA) {
				cameraData = reference as AutorotationCameraData;
			}
			
			// use IF, because we could have found it above as well.
			if (reference is ICamera && reference !== this) {
				(reference as EventDispatcher).addEventListener( CameraEvent.INACTIVE, inactiveHandler, false, 0, true );
				(reference as EventDispatcher).addEventListener( CameraEvent.ACTIVE, activeHandler, false, 0, true );
			}
		}
		
		protected function startDelayTimer():void {
			if (!_cameraData.isAutorotating) {
				__delayTimer.delay = _cameraData.delay * 1000;
				__delayTimer.start();
			}else {
				timesUp();
			}
		}
		
		protected function stopDelayTimer():void {
			__delayTimer.stop();
			__delayTimer.reset();
		}
		
		protected function stopAutorotatorNow():void{
			if (_stage) _stage.removeEventListener( Event.ENTER_FRAME, enterFrameHandler);
			__delayTimer.stop();
			__delayTimer.reset();
			dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
			_running = false;
			if (_cameraData.isAutorotating) _cameraData.isAutorotating = false;
			
			moveTargetFinished = true;
		}
		
		private function timesUp(e:TimerEvent=null):void{
			__delayTimer.stop();
			if (!_stage) return;
			dispatchEvent( new CameraEvent(CameraEvent.ACTIVE));
			__lastTimeStamp = getTimer();
			_running = true;
			_stage.addEventListener( Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			if (!_cameraData.isAutorotating) _cameraData.isAutorotating = true;
		}
		
		private var currentTimeStamp:int;
		private var elapsedTime:int;
		private var delta:Number;
		private var futureDelta:Number;
		private var futureViewData:ViewData;
		private function enterFrameHandler(event:Event):void {
			if(_cameraData.isAutorotating == false || _cameraData.enabled == false)
			{
				return;
			}
			currentTimeStamp = getTimer();
			elapsedTime = currentTimeStamp - __lastTimeStamp;
			
			if (_cameraData.mode == AutorotationCameraData.SPEED)
				delta = (elapsedTime / 1000) * _cameraData.speed;
			else if (_cameraData.mode == AutorotationCameraData.FRAME_INCREMENT)
				delta = _cameraData.frameIncrement;
			
			if ( _viewData._pan >= _viewData._maximumPan) {
				rotationDirection = -1;
			}else if ( _viewData._pan <= _viewData._minimumPan) {
				rotationDirection = 1;
			}
			delta = delta * rotationDirection;
			_viewData.pan += delta;
			
			if(cameraData.autoToNextRotation){
				hasMovedValue += Math.abs(delta);
				if(hasMovedValue > cameraData.autoToNextRotation){
					hasMovedValue = 0;
					stopAutorotatorNow();
					(_viewData as Object).LoadNextPano("default");
					return;
				}
			}
			
			if(!moveTargetFinished){
				curHasMoved += Math.abs(delta);
				if(curHasMoved > moveTarget){
					curHasMoved = 0;
					moveTarget = 0;
					moveTargetFinished = true;
					stopAutorotatorNow();
					(_viewData as Object).runAction(actionId);
					return;
				}
			}
			
			// set tilt;
			if (_viewData._tilt < __neutralTilt) {
				if (delta < 0){ delta = -delta; }
				_viewData.tilt += delta;
				if (_viewData._tilt > __neutralTilt) _viewData._tilt = __neutralTilt;
			}
			else if (_viewData._tilt > __neutralTilt) {
				if (delta < 0){ delta = -delta; }
				_viewData.tilt -= delta;
				if (_viewData._tilt < __neutralTilt) _viewData._tilt = __neutralTilt;
			}
			
			// set fieldOfView
			if (_viewData._fieldOfView > __neutralFieldOfView) {
				_viewData.fieldOfView -= delta;
				if (_viewData._fieldOfView < __neutralFieldOfView) _viewData.fieldOfView = __neutralFieldOfView;
			}else if (_viewData._fieldOfView < __neutralFieldOfView) {
				_viewData.fieldOfView += delta;
				if (_viewData._fieldOfView > __neutralFieldOfView) _viewData.fieldOfView = __neutralFieldOfView;
			}
			
			__lastTimeStamp = currentTimeStamp;
			
			if (_render == null) return;
			
			if (_cameraData.mode == AutorotationCameraData.SPEED)
				futureDelta = (_loadingStatistics.averageLatency / 1000) * _cameraData.speed;
			else if (_cameraData.mode == AutorotationCameraData.FRAME_INCREMENT)
				futureDelta = (_loadingStatistics.averageLatency / elapsedTime) * _cameraData.frameIncrement;
			
			if (futureDelta <= delta) return;
			
			futureViewData = _futureViewData;
			_viewData.clone(futureViewData);
			
			futureViewData.invalidPerspective = futureViewData.invalidTransform = futureViewData.invalid = true;
			
			// set pan
			futureViewData.pan -= futureDelta;
			
			// set tilt;
			if (futureViewData._tilt < __neutralTilt) {
				if (futureDelta < 0){futureDelta = -futureDelta;}
				futureViewData.tilt += futureDelta;
				if (_viewData._tilt > __neutralTilt) _viewData._tilt = __neutralTilt;
			}else if (futureViewData._tilt > __neutralTilt) {
				if (futureDelta < 0){ futureDelta = -futureDelta; }
				futureViewData.tilt -= futureDelta;
				if (futureViewData._tilt < __neutralTilt) futureViewData._tilt = __neutralTilt;
			}
			
			// set fieldOfView
			if (futureViewData._fieldOfView > __neutralFieldOfView) {
				futureViewData.fieldOfView -= futureDelta;
				if (futureViewData._fieldOfView < __neutralFieldOfView) futureViewData.fieldOfView = __neutralFieldOfView;
			}else if (futureViewData._fieldOfView < __neutralFieldOfView) {
				futureViewData.fieldOfView +=  futureDelta;
				if (futureViewData._fieldOfView > __neutralFieldOfView) futureViewData.fieldOfView = __neutralFieldOfView;
			}
			_render(null, futureViewData); //null is the Event that would signify that the render function is being called by Stage.invalidate(), hence it is null.
		}
		
		protected function enabledChangeHandler(e:Event):void {
			if(_cameraData.enabled) {
				startDelayTimer();
			}else{
				stopAutorotatorNow();
			}
		}
		
		public function isAutorotatingChangeHandler(e:Event):void {
			if(cameraData.enabled){
				if (cameraData.isAutorotating) {
					if (!_running) timesUp();
				}else {
					if (_running) {
						stopAutorotatorNow();
						startDelayTimer();
					}
				}
			}
		}
		
		public function get cameraData():AutorotationCameraData { return _cameraData; }
		public function set cameraData(value:AutorotationCameraData):void{
			if (value === _cameraData) return;
			if (value != null) {
				_futureViewData = new ViewData();
				_loadingStatistics = LoadingStatistics.instance;
				__delayTimer = new Timer(value.delay);
				__delayTimer.addEventListener( TimerEvent.TIMER, timesUp, false, 0, true);
				value.addEventListener( CameraEvent.ENABLED_CHANGE, enabledChangeHandler, false, 0, true);
				value.addEventListener( AutorotationEvent.AUTOROTATION_CHANGE, isAutorotatingChangeHandler, false, 0, true)
			}
			else if (value == null && _cameraData != null) {
				_futureViewData = null;
				_loadingStatistics = null;
				_cameraData.removeEventListener( CameraEvent.ENABLED_CHANGE, enabledChangeHandler);
				_cameraData.removeEventListener( AutorotationEvent.AUTOROTATION_CHANGE, isAutorotatingChangeHandler);
				__delayTimer = null;
				__delayTimer.removeEventListener( TimerEvent.TIMER, timesUp);
			}
			_cameraData = value;
			__neutralTilt = _cameraData.tilt;
			__neutralFieldOfView = _cameraData.fov;
			inactiveHandler();
		}
		
		public function get stageReference():Stage { return _stage; }
		public function set stageReference(value:Stage):void{
			if (_stage === value) return;
			if (value == null && _stage != null){
				_stage.removeEventListener( Event.ENTER_FRAME, enterFrameHandler);
			}
			_stage = value;
		}
		
		public function get viewData():ViewData { return _viewData; }
		public function set viewData(value:ViewData):void{
			_viewData = value;
			_render = (_viewData as PanoSalado).render;
			_viewData.addEventListener(Event.COMPLETE, panoramaChangeHandler, false, 0, true);
			inactiveHandler();
		}
		
		final protected function panoramaChangeHandler(e:Event):void {
			rotationDirection = 1;
		}
		
		final protected function activeHandler(e:Event):void {
			if (_running) stopAutorotatorNow();
		}
		
		final protected function inactiveHandler(e:Event = null):void {
			if (_viewData && _cameraData && (_cameraData.enabled)) {
				_renderCount = 0;
//				_viewData.addEventListener( ViewEvent.RENDERED, renderedHandler, false, 0, true);
				startDelayTimer();
			}
		}
		
		final protected function renderedHandler(e:Event):void {
			_renderCount++;
			if (_renderCount < 10) return;
			stopDelayTimer();
			_renderCount = 0;
		}
		
		private var moveTarget:Number = 0;
		private var actionId:String;
		private var moveTargetFinished:Boolean = true;
		private var curHasMoved:Number = 0;
		public function doAutoMoveThenRunAction(moveTarget:Number,actionId:String):void{
			this.moveTarget = moveTarget;
			this.actionId = actionId;
			moveTargetFinished = false;
			cameraData.enabled = true;
			cameraData.isAutorotating = true;
		}
	}
}