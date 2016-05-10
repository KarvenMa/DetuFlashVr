
package com.panosalado.core{
	
	import com.panosalado.controller.DependencyRelay;
	import com.panosalado.controller.ICamera;
	import com.panosalado.controller.StageReference;
	import com.panosalado.events.CameraEvent;
	import com.panosalado.events.PanoSaladoEvent;
	import com.panosalado.events.ReadyEvent;
	import com.panosalado.events.ViewEvent;
	import com.panosalado.model.Characteristics;
	import com.panosalado.model.Params;
	import com.panosalado.model.TilePyramid;
	import com.panosalado.model.ViewData;
	import com.panosalado.utils.Animation;
	import com.panosalado.view.IManagedChild;
	import com.panosalado.view.ManagedChild;
	import com.robertpenner.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getQualifiedClassName;
	
	/**
	* Dispatched when a new panorama has loaded.
	*
	* @eventType flash.events.Event.COMPLETE
	*/
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	* Dispatched after PanoSalado finishes changing view properties as a result of API calls: loadPanorama,
	* renderAt, swingTo, swingToChild, startInertialSwing/stopInertialSwing.
	* With 
	*
	* @eventType com.panosalado.events.CameraEvent.INACTIVE
	*/
	[Event(name="inactive", type="com.panosalado.events.CameraEvent")]
	
	/**
	* Dispatched before PanoSalado begins to change view properties as a result of API calls: loadPanorama,
	* renderAt, swingTo, swingToChild, startInertialSwing/stopInertialSwing.
	*
	* @eventType com.panosalado.events.CameraEvent.ACTIVE
	*/
	[Event(name="active", type="com.panosalado.events.CameraEvent")]
	
	/**
	* Dispatched after a swingTo is complete
	* 
	* @eventType com.panosalado.events.PanoSaladoEvent.SWING_TO_COMPLETE
	*/
	[Event(name="swingToComplete", type="com.panosalado.events.PanoSaladoEvent")]
	
	/**
	* Dispatched after a swingToChild is complete
	* 
	* @eventType com.panosalado.events.PanoSaladoEvent.SWING_TO_CHILD_COMPLETE
	*/
	[Event(name="swingToChildComplete", type="com.panosalado.events.PanoSaladoEvent")]
	
	/**
	* Displays panoramic images.  Implements the Model, View, Controller paradigm.
	* The Model is the ViewData superclass, which extends Sprite. (This is done so that view data properties are
	* directly gettable / settable on an instance of PanoSalado. 
	* The View is this class, along with a helper class like Panorama, which renders the panorama.
	* In the case of Panorama, the panorama is rendered as a vector to a Graphics object.
	* However, other renders could be implemented.
	* The Controllers are all optional and are passed in an array into the initialize() function.
	* Finally, this class contains a variety of public methods for modifying the ViewData model class to aid
	* in implementing "usual suspect" type functionality: loadPanorama(), renderAt(), swingTo(),
	* swingToChild(), startInertialSwing(), stopInertialSwing(), etc.  The functionalities of all of these convenience
	* methods can also be had through direct manipulation of the ViewData properties.
	*/
	public class PanoSalado extends ViewData implements ICamera{
		
		protected var _dependencyRelay         :DependencyRelay;
		protected var _stageReference          :StageReference;
		protected var _params                  :Object;
		protected var _background              :Sprite;
		protected var _canvas                  :Sprite;
		protected var _canvasInternal          :Sprite;
		protected var _children                :Sprite;
		protected var _managedChildren         :Sprite;
		protected var _renderFunction          :Function;
		
		public function PanoSalado() {
			
			trace(" --- PanoSalado start"+new Date()); 
		
			_dependencyRelay = new DependencyRelay(false);
			_stageReference = new StageReference(true);
			_params = {};
			
			_background = new Sprite();
			_canvas = new Sprite();
			_canvasInternal = new Sprite();
			_children = new Sprite();
			_managedChildren = new Sprite();
					
			//_canvas.blendMode = BlendMode.LAYER; COREMOD: shows overlapping tiles when loading panorama but makes viewing much more fluent
			//_managedChildren.visible = false;
			
			$addChild(_background); //this one first so it is underneath
			$addChild(_canvas);
			_canvas.addChild(_canvasInternal);
			_canvasInternal.addChild(_managedChildren);
			$addChild(_children); // this one on top. for unmanaged children. buttons, etc. 
			
			_dependencyRelay.addDependency(this, Characteristics.VIEW_DATA);
			//_dependencyRelay.addCallback(processDependency);
			_dependencyRelay.addCallback(_stageReference.processDependency);
			_dependencyRelay.addCallback(TilePyramid.processDependency);
			
			addEventListener(ViewEvent.NULL_PATH, clearGraphics, false, 0, true);
		}
		
		/**
		* @param reference Object
		* @param characteristics *
		*/
		public function processDependency(reference:Object, characteristics:*):void{} // to satisfy ICamera
		
		/**
		* PanoSalado accepts an Array of Objects as dependencies for itself and for the other dependencies in the list.
		* This offers a means for any instance of a class passed in to the array to store a reference to any other
		* instance of a class passed in to the array.  PanoSalado uses flash.utils.getQualifiedClassName()
		* on each dependency to create the characteristics object which provides an auxiliary means for the dependency
		* to identify itself to other dependencies looking for it. (This is in addition to the actual reference to the
		* dependency).  Each dependency will be checked for a "processDependency" function, and if found the function will
		* be invoked with each dependency in  the order of the dependencies Array.
		* @param dependencies Array of Objects
		* @see processDependency
		*/
		public function initialize(dependencies:Array):void {
			for each (var dependency:* in dependencies) {
				if (dependency.hasOwnProperty("processDependency")) _dependencyRelay.addCallback(dependency.processDependency);
				_dependencyRelay.addDependency(dependency, flash.utils.getQualifiedClassName(dependency));
				if (dependency.hasOwnProperty("stageReference")) _stageReference.addNotification(dependency);
			}
		}
		
		public function get renderFunction():Function { return _renderFunction; }
		public function set renderFunction(value:Function):void {
			if (_renderFunction === value) return;
			_renderFunction = value;
			if (value != null)
				addEventListener(Event.RENDER, render, false, 0, true);
			else 
				removeEventListener(Event.RENDER, render, false);
		}
		/**
		* Lowest Sprite
		*/
		public function get background():Sprite { return _background; }
		
		
		/**
		* The Sprite whose x,y values can be used to move the primary panorama. Also the Sprite on which the BlendMode is set to LAYER.
		*/
		public function get canvas():Sprite { return _canvas; }
		
		/**
		* The Sprite whose graphics object is used to draw the primary panorama. It's x,y is always at half the panorama's width, height.
		*/
		public function get canvasInternal():Sprite { return _canvasInternal; }
		
		/**
		* The Sprite which is the container for all ManagedChild extending children of the primary panorama (hotspots usually).
		* When a child is added to PanoSalado, its class is checked for ManagedChild and if true, it will be added to this 
		* Sprite and managed as part of the current panorama.
		*/
		public function get managedChildren():Sprite { return _managedChildren; }
		
		/**
		* The Sprite which is the container for all children which do NOT extend ManagedChild.
		*/
		public function get children():Sprite { return _children; };
		
		/**
		* function that draws the panorama.  Normally it is not necessary to call this function at all; normally the function
		* is called to handle a RENDER event caused by setting a property on the ViewData instance with invalidates the stage.
		* However, this function can be called WITHOUT an event arg, and WITH a viewData arg in order to predict and start loading
		* images for the values in the viewData arg.  Calling it with a null Event will not cause any drawing.
		* @param event Event non-null value will result in drawing using the superclass ViewData's properties
		* @param viewData ViewData non-null value will result in using this ViewData's properties
		*/
		final public function render(event:Event = null, viewData:ViewData = null):void {
			if (viewData == null) viewData = this; //if other viewData was passed in, use it instead. useful for predicting future needed bitmaps.
			if (!viewData._tile ) return;
			if (viewData._tile && viewData.invalid) {
				_renderFunction(viewData, event ? _canvasInternal.graphics : null,_canvasInternal);
				if (viewData.invalidPerspective) { 
					_managedChildren.transform.perspectiveProjection = viewData.perspectiveProjection;
					_canvasInternal.x = viewData._boundsWidth * 0.5;
					_canvasInternal.y = viewData._boundsHeight * 0.5;
				}
				viewData.invalid = viewData.invalidTransform = viewData.invalidPerspective = false;
				viewData.dispatchEvent(new ViewEvent(ViewEvent.RENDERED, event?_canvas:null));
			}
			updateChildren(viewData);
		}
		
		/**
		* Clears the graphics objects if path or secondaryPath are null.
		*/
		protected function clearGraphics(e:Event):void {
			if (_path == null) _canvasInternal.graphics.clear();
		}
		
		/**
		* Updates the position of all managedChildren of PanoSalado
		* @see managedChildren
		*/
		//final protected function updateChildren(viewData:ViewData):void {
		protected function updateChildren(viewData:ViewData):void {
			for (var i:int = 0; i < _managedChildren.numChildren; i++) {
				var child:ManagedChild = _managedChildren.getChildAt(i) as ManagedChild;
				
				var matrix3D:Matrix3D = child._matrix3D;
				if (child.invalid) {
					matrix3D.recompose(child._decomposition);
					child.invalid = false;
				}
				
				matrix3D = matrix3D.clone();
				matrix3D.append(viewData.transformMatrix3D);
				matrix3D.appendTranslation(0, 0, -viewData.perspectiveProjection.focalLength);
				
				if (!child.flat) {
					child.transform.matrix3D = matrix3D;
				}else {
					var pos:Vector3D = matrix3D.decompose()[0];
					var t:Number = viewData.perspectiveProjection.focalLength / (viewData.perspectiveProjection.focalLength + pos.z);
					if (t > 0) {
						child.flatX = pos.x * t; 
						child.flatY = pos.y * t;
					}else {
						child.flatX = 9999;
						child.flatY = 9999;
					}
				}
			}
		}
		
		/**
		* Loads a new panorama.  This operation is asynchronous.  The new panorama does not exist until PanoSalado
		* dispatches a COMPLETE event, at which time, all the properties of the Params arg will be copied the the 
		* superclass ViewData.  Any properties not specified in the Params object will be untouched.  If you wish a panorama
		* to open with pan, tilt, fieldOfView of 0,0,120 create a Params object with those values, and all other values
		* will be inherited as they are. The only property of Params that must be set is the path.
		* @param Params 
		*/
		public function loadPanorama(params:Params):void {
			//if value is null then use the current value. i.e. new panorama inherits last panorama's values
			if (params == null || params.path == null) throw new Error("PanoSalado.loadPanorama() requires a non-null Params argument");
			var p:String = params.path;
			this.previewpath = params.previewpath;
			this.path = p;
			_params[p] = params;
		}
		
		//TODO: loadPanorama(params:Params,children:Vector.<DisplayObject>) and add children in commitPath AFTER PATH event.
		/**
		* Copies all the properties in the Params object received in loadPanorama to the current panorama.
		* @see loadPanorama
		*/
		override protected function commitPath(e:ReadyEvent, updateFOV:Boolean = true):void {
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
			var path:String = e.tilePyramid.path;
			var params:Params = _params[path];
			
			if (params == null) { //path was set directly, so go to super's behavior directly
				super.commitPath(e, true);
				return;
			}
			
			if (canvas != null && canvas.width > 0 && canvas.height > 0) { // COREMOD, entire section
				try{
					var bd:BitmapData = new BitmapData(canvas.width, canvas.height);
					bd.draw(canvas);
					var bmp:Bitmap = new Bitmap(bd);
					bmp.alpha = canvas.alpha;
					_background.addChild(bmp);
				}catch(e:Error){}
			}
			updateFOV = (params.minFov) ? true : false ;
			_params[path] = null;
			params.path = null;
			params.copyInto(this as ViewData);
			super.commitPath(e, updateFOV);
			dispatchEvent( new CameraEvent(CameraEvent.INACTIVE));
		}
		
		/**
		* Renders the panorama at the specified pan,tilt,fieldOfView. This is a convenience method for directly setting
		* pan,tilt,fieldOfView.  Any of the values will be untouched if NaN is passed. It also dispatches CameraEvent.ACTIVE and CameraEvent.INACTIVE before and after the changes
		* to stop autorotation for the benefit of any listening objects (AutorotationCamera).
		* @param pan Number (optional) pass NaN to use the current value
		* @param tilt Number (optional) pass NaN to use the current value
		* @param fieldOfView Number (optional) pass NaN to use the current value
		*/
		public function renderAt(pan:Number = NaN, tilt:Number = NaN, fieldOfView:Number = NaN):void {
			if (isNaN(pan) && isNaN(tilt) && isNaN(fieldOfView)) return;
			//if value is null use the current value
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
			if (!isNaN(pan)) this.pan = pan;
			if (!isNaN(tilt)) this.tilt = tilt;
			if (!isNaN(fieldOfView)) this.fieldOfView = fieldOfView;
			dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
		}
		
		/**
		* Swings the camera to the specified pan,tilt,fieldOfView with the specified speed, using the specified tween
		* function (with a standard Robert Penner tween function signature).  NaN passed for pan, tilt, or fieldOfView will 
		* not changed the current value. It also dispatches CameraEvent.ACTIVE and CameraEvent.INACTIVE before and after the changes
		* to stop autorotation for the benefit of any listening objects (AutorotationCamera).
		* @param pan Number (optional) pass NaN to use the current value
		* @param tilt Number (optional) pass NaN to use the current value
		* @param fieldOfView Number (optional) pass NaN to use the current value
		* @param speed Number (optional) defaults to 20 
		* @param tween Function (optional) defaults to Linear.easeNone. Function must have signature: function name (t:Number, b:Number, c:Number, d:Number):Number
		*/
		public function swingTo(pan:Number = NaN, tilt:Number = NaN, fieldOfView:Number = NaN, speed:Number = 30, tween:Function = null):void {
			if (isNaN(pan) && isNaN(tilt) && isNaN(fieldOfView)) return;
			
			var span:Number,stilt:Number
			span = pan;
			stilt = tilt;
			
			//if value is null then use current value
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
			var animation:Animation;
			if (tween == null) tween = Linear.easeNone;
			var properties:Vector.<String> = new Vector.<String>();
			var values:Vector.<Number> = new Vector.<Number>();
			if (!isNaN(pan)) {
				if (_pan - pan > 180) pan += 360;
				else if (_pan - pan < -180) pan -= 360;
				properties.push("pan");
				values.push(pan);
			}else {
				pan = _pan;
			}
			if (!isNaN(tilt)) {
				properties.push("tilt");
				values.push(tilt);
			}else {
				tilt = _tilt;
			}
			if (!isNaN(fieldOfView)) {
				properties.push("fieldOfView");
				values.push(fieldOfView);
			}
			
			var time:Number = (Math.acos((Math.sin(_tilt * Math.PI / 180) * Math.sin(tilt * Math.PI / 180))
			+ (Math.cos(_tilt*Math.PI/180) * Math.cos(tilt*Math.PI/180) * Math.cos((Math.abs(_pan - pan))*Math.PI/180)))*(180/Math.PI)) / speed;
			
			if(isNaN(span) && isNaN(stilt)){
				time = 0.5;
			}
			
			animation = new Animation(this,properties,values,time,tween);
			animation.addEventListener(Event.COMPLETE, swingToComplete, false, 0, true);
		}
		
		/**
		* @private
		*/
		protected function swingToComplete(e:Event):void {
			dispatchEvent(new PanoSaladoEvent(PanoSaladoEvent.SWING_TO_COMPLETE));
			dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
		}
		
		/**
		* Swings the camera to the specified ManagedChild, fieldOfView, with the specified speed, using the 
		* specified tween function (standard Robert Penner style signature).  This function dispatches 
		* CameraEvent.ACTIVE and CameraEvent.INACTIVE before the motion starts and after it ceases, respectively.
		* @param child ManagedChild 
		* @param fieldOfView Number (optional) pass NaN to use the current value
		* @param speed Number (optional) defaults to 20
		* @param tween Function (optional) defaults to Linear.easeNone. Function must have signature: function name (t:Number, b:Number, c:Number, d:Number):Number
		*/
		public function swingToChild(child:ManagedChild, fieldOfView:Number = NaN, speed:Number = 30, tween:Function = null):void {
			if (child == null) return;
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
			if (tween == null) tween = Linear.easeNone;
			var childPan:Number = Math.atan2(child.x, child.z) * 180 / Math.PI;
			var childTilt:Number = -Math.atan2(child.y, Math.sqrt(child.x * child.x + child.z * child.z)) * 180 / Math.PI;
			if (_pan - childPan > 180) childPan += 360;
			else if (_pan - childPan < -180) childPan -= 360;
			
			var properties:Vector.<String> = new Vector.<String>();
			var values:Vector.<Number> = new Vector.<Number>();
			properties.push("pan","tilt");
			values.push(childPan, childTilt);
			if (!isNaN(fieldOfView)) {
				properties.push("fieldOfView");
				values.push(fieldOfView);
			}
			var time:Number = (Math.acos((Math.sin(_tilt * Math.PI / 180) * Math.sin(childTilt * Math.PI / 180)) 
			+ (Math.cos(_tilt*Math.PI/180) * Math.cos(childTilt*Math.PI/180) * Math.cos((Math.abs(_pan - childPan))*Math.PI/180)))*(180/Math.PI)) / speed;
			
			swingToChildAnimation = new Animation(this, properties, values, time, tween);
			swingToChildAnimation.addEventListener(Event.COMPLETE, swingToChildComplete, false, 0, true);
		}
		protected function swingToChildComplete(e:Event):void {
			dispatchEvent(new PanoSaladoEvent(PanoSaladoEvent.SWING_TO_CHILD_COMPLETE));
			dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
			swingToChildAnimation = null;
		}
		private var swingToChildAnimation:Animation;
		public function stopSwingToChild():void{
			if(swingToChildAnimation){
				swingToChildAnimation.stop();
				swingToChildComplete(null);
			}
		}
		
		protected var _now:int;
		protected var _deltaPan:Number;
		protected var _deltaTilt:Number;
		protected var _panSpeed:Number;
		protected var _tiltSpeed:Number;
		protected var _sensitivity:Number;
		protected var _friction:Number;
		protected var _threshold:Number;
		
		/**
		* Starts inertial motion (like the InertialMouseCamera) with the specified panSpeed, tiltSpeed using
		* the specified sensitivity, friction, and threshold.  For a panning motion (horizontal) pass a positive or negative non-zero
		* (positive = right) panSpeed value.  For tilt, pass a non-zero tiltSpeed value (positive = up). Calling stopInertialSwing() 
		* will zero out panSpeed and tiltSpeed, and slow the motion to a stop once the delta motion is under the threshold value.
		* Subsequent calls to this function, but prior to calling stopInertialSwing() will modified the values but continue the motion.
		* Calling stopInertialSwing() is identical in function to calling startInertialSwing(0,0).  This function dispatches 
		* CameraEvent.ACTIVE and CameraEvent.INACTIVE before the motion starts and after it ceases, respectively.
		* @param panSpeed Number (< 0 = left; > 0 right) the larger the absolute value, the faster the motion
		* @param tiltSpeed Number (< 0 = down; > 0 up) the larger the absolute value, the faster the motion
		* @param sensitivity Number (optional) defaults to 0.0003
		* @param friction Number (optional) defaults to 0.3
		* @param threshold Number (optional) defaults to 0.0001
		*/
		public function startInertialSwing(panSpeed:Number,tiltSpeed:Number,sensitivity:Number = 0.0003,friction:Number = 0.3,threshold:Number = 0.0001):void {
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
			_now = (isNaN(_now) || _now == 0) ? flash.utils.getTimer() : _now;
			_deltaPan = isNaN(_deltaPan) ? 0 : _deltaPan;
			_deltaTilt = isNaN(_deltaTilt) ? 0 : _deltaTilt;
			_panSpeed = panSpeed;
			_tiltSpeed = tiltSpeed;
			_sensitivity = sensitivity;
			_friction = friction;
			_threshold = threshold;
			addEventListener(Event.ENTER_FRAME, inertialSwingEnterFrameHandler, false, 0, true);
			dispatchEvent(new CameraEvent(CameraEvent.ACTIVE));
		}
		/**
		* @private
		*/
		protected function inertialSwingEnterFrameHandler(e:Event):void {
			var now:int = flash.utils.getTimer();
			var elapsedTime:int = now - _now;
			_now = now;
			_deltaPan -= _panSpeed * elapsedTime * _sensitivity;
			_deltaTilt -= _tiltSpeed * elapsedTime * _sensitivity;
			if ((_deltaPan * _deltaPan + _deltaTilt * _deltaTilt) > _threshold){
				// always apply friction so that motion slows
				var inverseFriction:Number = 1 - _friction;
				_deltaPan *=  inverseFriction;
				_deltaTilt *= inverseFriction;
				pan += _deltaPan;
				tilt -= _deltaTilt;
				
				if (_tilt < - 90) tilt -= (_tilt + 90) * _friction * 2;
				else if ( _tilt > 90 ) tilt -= (_tilt - 90) * _friction * 2;
			}else { // motion is under threshold
				_now = NaN;
				_deltaPan = NaN;
				_deltaTilt = NaN;
				_panSpeed = NaN;
				_tiltSpeed = NaN;
				_sensitivity = NaN;
				_friction = NaN;
				_threshold = NaN;
				removeEventListener(Event.ENTER_FRAME, inertialSwingEnterFrameHandler);
				dispatchEvent(new CameraEvent(CameraEvent.INACTIVE));
			}
		}
		
		/**
		* Stops the inertial motion caused by a call to startInertialSwing().  This is identical to calling 
		* startInertialSwing(0,0).  Motion does not cease immediately; it slows until it is under the threshold
		* specified in startInertialSwing().
		*/
		public function stopInertialSwing():void {
			_panSpeed = 0;
			_tiltSpeed = 0;
		}
		
		override public function addChild(child:DisplayObject):DisplayObject {
			if (child is IManagedChild) managedChildren.addChild(child)
			else children.addChild(child);
			return child;
		}
		/**
		* @private
		*/
		public function $addChild(child:DisplayObject):DisplayObject { //not recommended to use this publicly
			return super.addChild(child);
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
			if (child is IManagedChild) managedChildren.addChildAt(child, index)
			else children.addChildAt(child, index);
			return child;
		}
		/**
		* @private
		*/
		public function $addChildAt(child:DisplayObject, index:int):DisplayObject { //not recommended to use this publicly
			return super.addChildAt(child, index);
		}
		
		override public function contains(child:DisplayObject):Boolean {
			var ret:Boolean;
			if (child is IManagedChild) ret = managedChildren.contains(child)
			else ret = children.contains(child);
			return ret;
		}
		/**
		* Allows access to getChildAt() to get a managed or normal child depending on the managed switch
		* @param index int
		* @param managed Boolean
		*/
		public function _getChildAt(index:int, managed:Boolean):DisplayObject {
			var ret:DisplayObject;
			if (managed) ret = managedChildren.getChildAt(index)
			else ret = children.getChildAt(index);
			return ret;
		}
		/**
		* Allows access to getChildByName() to get a managed or normal child depending on the managed switch
		* @param name String
		* @param managed Boolean
		*/
		public function _getChildByName(name:String, managed:Boolean):DisplayObject {
			var ret:DisplayObject;
			if (managed) ret = managedChildren.getChildByName(name)
			else ret = children.getChildByName(name);
			return ret;
		}
		
		override public function getChildIndex(child:DisplayObject):int {
			var ret:int;
			if (child is IManagedChild) ret = managedChildren.getChildIndex(child)
			else ret = children.getChildIndex(child);
			return ret;
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject {
			if (child is IManagedChild) managedChildren.removeChild(child)
			else children.removeChild(child);
			return child;
		}
		/**
		* Allows access to removeChildAt() for a managed or normal child depending on the managed switch
		* @param index int
		* @param managed Boolean
		*/
		public function _removeChildAt(index:int, managed:Boolean):DisplayObject {
			var ret:DisplayObject;
			if (managed) ret = managedChildren.removeChildAt(index)
			else ret = children.removeChildAt(index);
			return ret;
		}
		
		override public function setChildIndex(child:DisplayObject, index:int):void {
			if (child is IManagedChild) managedChildren.setChildIndex(child, index)
			else children.setChildIndex(child, index);
		}
		
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void {
			if (child1 is IManagedChild && child2 is IManagedChild) managedChildren.swapChildren(child1, child2)
			else children.swapChildren(child1, child2);
		}
		/**
		* Allows access to swapChildrenAt() for managed or normal children depending on the managed switch
		* @param index1 int
		* @param index2 int
		* @param managed Boolean
		*/
		public function _swapChildrenAt(index1:int, index2:int, managed:Boolean):void {
			if (managed) managedChildren.swapChildrenAt(index1, index2)
			else children.swapChildrenAt(index1, index2);
		}
		
		override public function get numChildren():int {
			return managedChildren.numChildren + children.numChildren;
		}
	}
}