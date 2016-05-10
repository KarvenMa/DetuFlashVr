/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.zoomslider.view {
	
	import com.panozona.modules.zoomslider.model.SliderData;
	import com.panozona.modules.zoomslider.model.ZoomSliderData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class SliderView extends Sprite{
		
		public const pointer:Sprite = new Sprite();
		public const bar:Sprite = new Sprite();
		
		private var zoomIn:Bitmap;
		private var zoomOut:Bitmap;
		
		private var zoomInPlainBD:BitmapData;
		private var zoomOutPlainBD:BitmapData;
		private var zoomInActiveBD:BitmapData;
		private var zoomOutActiveBD:BitmapData;
		
		private var _zoomSliderData:ZoomSliderData;
		
		public function SliderView(zoomSliderData:ZoomSliderData) {
			_zoomSliderData = zoomSliderData;
		}
		
		public function build(
			zoomInPlainBD:BitmapData, zoomOutPlainBD:BitmapData,
			zoomInActiveBD:BitmapData, zoomOutActiveBD:BitmapData,
			barBD:BitmapData, pointerBD:BitmapData):void {
			
			this.zoomInPlainBD = zoomInPlainBD;
			this.zoomOutPlainBD = zoomOutPlainBD;
			this.zoomInActiveBD = zoomInActiveBD;
			this.zoomOutActiveBD = zoomOutActiveBD;
			
			bar.graphics.beginBitmapFill(barBD, null, true);
			bar.graphics.drawRect(
				0,
				0,
				barBD.width,
				_zoomSliderData.sliderData.slider.length + (zoomInPlainBD.height + zoomOutPlainBD.height) * 0.5);
			bar.graphics.endFill();
			bar.y = zoomInPlainBD.height * 0.5;
			addChild(bar);
			bar.addEventListener(MouseEvent.MOUSE_DOWN, dragStart, false, 0, true);
			bar.addEventListener(MouseEvent.MOUSE_UP, dragStop, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragStop, false, 0, true);
			
			pointer.addChild(new Bitmap(pointerBD));
			pointer.y = bar.y + (bar.height - pointer.height) * 0.5;
			bar.addChild(pointer);
			
			zoomIn = new Bitmap(this.zoomInPlainBD);
			var zoomInButton:Sprite = new Sprite();
			zoomInButton.addChild(zoomIn);
			zoomInButton.buttonMode = true;
			zoomInButton.y = 0;
			addChild(zoomInButton);
			zoomInButton.addEventListener(MouseEvent.MOUSE_DOWN, navZoomIn, false, 0, true);
			zoomInButton.addEventListener(MouseEvent.MOUSE_UP, navZoomStop, false, 0, true);
			zoomInButton.addEventListener(MouseEvent.ROLL_OUT, navZoomStop, false, 0, true);
			
			zoomOut = new Bitmap(this.zoomOutPlainBD);
			var zoomOutButton:Sprite = new Sprite();
			zoomOutButton.addChild(zoomOut);
			zoomOutButton.buttonMode = true;
			zoomOutButton.y = bar.y + bar.height - zoomOutButton.height * 0.5;
			addChild(zoomOutButton);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_DOWN, navZoomOut, false, 0, true);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_UP, navZoomStop, false, 0, true);
			zoomOutButton.addEventListener(MouseEvent.ROLL_OUT, navZoomStop, false, 0, true);
			
			if (!_zoomSliderData.sliderData.slider.slidesVertical) {
				x = height;
				rotation = 90;
				zoomInButton.y += zoomInButton.height;
				zoomInButton.rotation = -90;
				zoomOutButton.y += zoomOutButton.height;
				zoomOutButton.rotation = -90;
			}
		}
		
		public function get zoomSliderData():ZoomSliderData {
			return _zoomSliderData;
		}
		
		public function get sliderData():SliderData {
			return _zoomSliderData.sliderData;
		}
		
		public function showZoomIn():void {
			zoomIn.bitmapData = zoomInActiveBD;
		}
		
		public function showZoomOut():void {
			zoomOut.bitmapData = zoomOutActiveBD;
		}
		
		public function showZoomStop():void {
			zoomOut.bitmapData = zoomOutPlainBD;
			zoomIn.bitmapData = zoomInPlainBD;
		}
		
		private function navZoomIn(e:Event):void {
			_zoomSliderData.sliderData.zoomIn = true;
		}
		
		private function navZoomOut(e:Event):void {
			_zoomSliderData.sliderData.zoomOut = true;
		}
		
		private function navZoomStop(e:Event):void {
			_zoomSliderData.sliderData.zoomIn = false;
			_zoomSliderData.sliderData.zoomOut = false;
		}
		
		private function dragStart(e:Event):void {
			_zoomSliderData.sliderData.mouseDrag = true;
		}
		
		private function dragStop(e:Event):void {
			_zoomSliderData.sliderData.mouseDrag = false;
		}
	}
}