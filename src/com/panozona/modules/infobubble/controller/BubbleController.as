/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.infobubble.controller {
	
	import caurina.transitions.Tweener;
	import com.panozona.modules.infobubble.events.BubbleEvent;
	import com.panozona.modules.infobubble.model.structure.Bubble;
	import com.panozona.modules.infobubble.model.structure.Image;
	import com.panozona.modules.infobubble.model.structure.Style;
	import com.panozona.modules.infobubble.model.structure.Text;
	import com.panozona.modules.infobubble.view.BubbleView;
	import com.panozona.player.module.Module;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	public class BubbleController {
		
		private var _bubbleView:BubbleView;
		private var _module:Module;
		
		private var imageLoader:Loader;
		
		private var ellipseAxisX:Number;
		private var ellipseAxisY:Number;
		
		private var angle:Number;
		private var currentBubbleAngle:Number;
		private var currentDefaultAngle:Number;
		
		public function BubbleController(bubbleView:BubbleView, module:Module){
			_bubbleView = bubbleView;
			_module = module;
			
			imageLoader = new Loader();
			imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageLost, false, 0, true);
			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded, false, 0, true);
			
			_bubbleView.infoBubbleData.bubbleData.addEventListener(BubbleEvent.CHANGED_ENABLED, handleEnabledChange);
			_bubbleView.infoBubbleData.bubbleData.addEventListener(BubbleEvent.CHANGED_CURRENT_ID, handleCurrentIdChange);
			_bubbleView.infoBubbleData.bubbleData.addEventListener(BubbleEvent.CHANGED_IS_SHOWING, handleIsShowingChange);
		}
		
		private function handleEnabledChange(e:Event):void {
			if (_bubbleView.infoBubbleData.bubbleData.enabled) {
				if (_bubbleView.infoBubbleData.bubbleData.isShowing) { // should have been showing but was disabled
					handleIsShowingChange();
				}
				_module.qjPlayer.manager.runAction(_bubbleView.infoBubbleData.settings.onEnable);
			}else if (_bubbleView.numChildren > 0) {
				Tweener.addTween(_bubbleView.getChildAt(0),{
					alpha:0,
					time:_bubbleView.infoBubbleData.bubbles.hideTween.time,
					transition:_bubbleView.infoBubbleData.bubbles.hideTween.transition,
					onComplete:cleanUp});
				_module.qjPlayer.manager.runAction(_bubbleView.infoBubbleData.settings.onDisable);
			}
		}
		
		private function handleCurrentIdChange(e:Event):void {
			while (_bubbleView.numChildren) _bubbleView.removeChildAt(0);
			try{
				imageLoader.unload();
				imageLoader.close();
			}catch(e:Error){}
			for each (var bubble:Bubble in _bubbleView.infoBubbleData.bubbles.getChildrenOfGivenClass(Bubble)){
				if (bubble.id == _bubbleView.infoBubbleData.bubbleData.currentId) {
					currentBubbleAngle = bubble.angle;
					if (bubble is Image) {
						imageLoader.load(new URLRequest((bubble as Image).path),new flash.system.LoaderContext(true));
						return;
					}else if (bubble is Text) {
						buildText(bubble as Text);
						return;
					}
				}
			}
			_module.printWarning("Could not find bubble: " + _bubbleView.infoBubbleData.bubbleData.currentId);
		}
		
		private function imageLost(error:IOErrorEvent):void {
			_module.printError(error.text);
		}
		
		private function imageLoaded(e:Event):void {
			addDisplayObject(imageLoader.content);
		}
		
		private function buildText(text:Text):void {
			if(text.style != null){
				for each(var style:Style in _bubbleView.infoBubbleData.styles.getChildrenOfGivenClass(Style)){
					if (style.id == text.style) {
						_bubbleView.setText(text.text, style.content);
						addDisplayObject(_bubbleView.textSprite);
						return;
					}
				}
			}
			_bubbleView.setText(text.text, null);
			addDisplayObject(_bubbleView.textSprite);
		}
		
		private function addDisplayObject(displayObject:DisplayObject):void {
			while (_bubbleView.numChildren) _bubbleView.removeChildAt(0);
			
			_bubbleView.graphics.clear();
			_bubbleView.graphics.beginFill(0x000000, 0);
			_bubbleView.graphics.drawRect(0, 0, displayObject.width +
				2 * _bubbleView.infoBubbleData.settings.margin, displayObject.height +
				2 * _bubbleView.infoBubbleData.settings.margin);
			_bubbleView.graphics.endFill();
			
			displayObject.x = displayObject.y = _bubbleView.infoBubbleData.settings.margin;
			_bubbleView.addChild(displayObject);
			_bubbleView.getChildAt(0).alpha = 0;
			
			ellipseAxisX = _bubbleView.width / 2 * Math.SQRT2;
			ellipseAxisY = _bubbleView.height / 2 * Math.SQRT2;
			
			handleIsShowingChange();
		}
		
		private function handleIsShowingChange(e:Event = null):void {
			if (_bubbleView.numChildren == 0) return; // nothing loaded yet
			if (!_bubbleView.infoBubbleData.bubbleData.enabled && _bubbleView.infoBubbleData.bubbleData.isShowing) return; // do not show when disabled
			_bubbleView.visible = true;
			if (_bubbleView.infoBubbleData.bubbleData.isShowing) {
				calcCurrentDefaultAngle();
				angle = -currentDefaultAngle;
				rotationRegistry = 0;
				_module.stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame, false, 0, true);
				Tweener.addTween(_bubbleView.getChildAt(0),{
					alpha:1,
					time:_bubbleView.infoBubbleData.bubbles.showTween.time,
					transition:_bubbleView.infoBubbleData.bubbles.showTween.transition});
			}else {
				rotationRegistry = 360;
				Tweener.addTween(_bubbleView.getChildAt(0),{
					alpha:0,
					time:_bubbleView.infoBubbleData.bubbles.hideTween.time,
					transition:_bubbleView.infoBubbleData.bubbles.hideTween.transition,
					onComplete:cleanUp});
			}
		}
		
		private function calcCurrentDefaultAngle():void {
			if (isNaN(currentBubbleAngle)) {
				var hbw:Number = _module.qjPlayer.manager.boundsWidth / 2;
				var hbh:Number = _module.qjPlayer.manager.boundsHeight / 2;
				var z:Number = Math.pow((getMouseX() - hbw) / hbw, 2) + Math.pow((getMouseY() - hbh) / hbh, 2);
				if (z < 0.1) {
					currentDefaultAngle = 90;
				}else {
					var initDegree:Number = validate(Math.atan2(hbh - getMouseY(), hbw - getMouseX()) / Math.PI * 180 + 90);
					currentDefaultAngle = initDegree;
				}
			}else {
				 currentDefaultAngle = -validate(Math.floor(-currentBubbleAngle));
			}
		}
		
		private function cleanUp():void {
			if (!_bubbleView.infoBubbleData.bubbleData.isShowing) {
				_bubbleView.visible = false;
				_module.stage.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			}
		}
		
		private var dir:Number;
		private var rotationRegistry:Number;
		private function handleEnterFrame(e:Event = null):void {
			if (angle == -currentDefaultAngle){
				// 0.5 clockwise, -0.5 counterclockwise
				if (currentDefaultAngle > -45 && currentDefaultAngle <= 45) {
					if (getMouseX() > (_module.qjPlayer.manager.boundsWidth * 0.5)) {
						dir = 0.5;
					}else {
						dir = -0.5;
					}
				}else if (currentDefaultAngle > 45 && currentDefaultAngle <= 135) {
					if (getMouseY() > (_module.qjPlayer.manager.boundsHeight * 0.5)) {
						dir = 0.5;
					}else {
						dir = -0.5;
					}
				}else if (currentDefaultAngle > 135 || currentDefaultAngle <= -135) {
					if (getMouseX() > (_module.qjPlayer.manager.boundsWidth * 0.5)) {
						dir = -0.5;
					}else {
						dir = 0.5;
					}
				}else if (currentDefaultAngle > -135 && currentDefaultAngle <= -45) {
					if (getMouseY() > (_module.qjPlayer.manager.boundsHeight * 0.5)) {
						dir = -0.5;
					}else {
						dir = 0.5;
					}
				}
			}
			
			_bubbleView.x = getMouseX() - Math.sin(angle * __toRadians) * ellipseAxisX - _bubbleView.width * 0.5;
			_bubbleView.y = getMouseY() - Math.cos(angle * __toRadians) * ellipseAxisY - _bubbleView.height * 0.5;
			
			if (Math.abs(rotationRegistry) != 360){
				if (hasConflict()) {
					while (hasConflict()) {
						angle += dir;
						angle = validate(angle);
						_bubbleView.x = getMouseX() - Math.sin(angle * __toRadians) * ellipseAxisX - _bubbleView.width * 0.5;
						_bubbleView.y = getMouseY() - Math.cos(angle * __toRadians) * ellipseAxisY - _bubbleView.height * 0.5;
						
						rotationRegistry += dir;
						if (Math.abs(rotationRegistry) == 360) break;
					}
				}else if (wontBeConflict(angle - dir)){
					while (wontBeConflict(angle - dir) && angle != -currentDefaultAngle) {
						angle -= dir;
						angle = validate(angle);
						_bubbleView.x = getMouseX() - Math.sin(angle * __toRadians) * ellipseAxisX - _bubbleView.width * 0.5;
						_bubbleView.y = getMouseY() - Math.cos(angle * __toRadians) * ellipseAxisY - _bubbleView.height * 0.5;
						
						rotationRegistry -= dir;
						if (Math.abs(rotationRegistry) == 360) break;
					}
				}
			}
		}
		
		private function getMouseX():Number {
			if (_module.mouseX > _module.qjPlayer.manager.boundsWidth) {
				return _module.qjPlayer.manager.boundsWidth;
			}else if (_module.mouseX < 0) {
				return 0;
			}else {
				return _module.mouseX;
			}
		}
		private function getMouseY():Number {
			if (_module.mouseY > _module.qjPlayer.manager.boundsHeight) {
				return _module.qjPlayer.manager.boundsHeight;
			}else if (_module.mouseY < 0) {
				return 0;
			}else {
				return _module.mouseY;
			}
		}
		
		private var bub_x:Number;
		private var bub_y:Number;
		private function wontBeConflict(angle:Number):Boolean {
			bub_x = getMouseX() - Math.sin(angle * __toRadians) * ellipseAxisX - _bubbleView.width * 0.5;
			bub_y = getMouseY() - Math.cos(angle * __toRadians) * ellipseAxisY - _bubbleView.height * 0.5;
			return(bub_x + _bubbleView.width <= _module.qjPlayer.manager.boundsWidth
				&& bub_y + _bubbleView.height <= _module.qjPlayer.manager.boundsHeight
				&& bub_y >= 0
				&& bub_x >= 0);
		}
		
		private function hasConflict():Boolean {
			return(_bubbleView.x + _bubbleView.width > _module.qjPlayer.manager.boundsWidth
				|| _bubbleView.y + _bubbleView.height > _module.qjPlayer.manager.boundsHeight
				|| _bubbleView.y < 0
				|| _bubbleView.x < 0);
		}
		
		private function validate(value:Number):Number {
			if (value <= -180) value = (((value + 180) % 360) + 180);
			if (value > 180) value = (((value + 180) % 360) - 180);
			return value;
		}
		
		private const __toRadians:Number = Math.PI / 180;
	}
}