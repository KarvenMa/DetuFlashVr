/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.imagegallery.view{
	
	import com.panozona.modules.imagegallery.model.ButtonData;
	import com.panozona.modules.imagegallery.model.ImageGalleryData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class ButtonView extends Sprite{
		
		public const bitmap:Bitmap = new Bitmap();
		
		private var _buttonData:ButtonData;
		private var _imageGalleryData:ImageGalleryData;
		
		private var _bitmapDataPlain:BitmapData;
		private var _bitmapDataActive:BitmapData;
		
		public function ButtonView(buttonData:ButtonData, imageGalleryData:ImageGalleryData){
			_buttonData = buttonData;
			_imageGalleryData = imageGalleryData;
			
			buttonMode = true;
			
			addChild(bitmap);
			
			addEventListener(MouseEvent.MOUSE_DOWN, onMousePress, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, onMouseRelease, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onMouseRelease, false, 0, true);
		}
		
		public function get buttonData():ButtonData {
			return _buttonData;
		}
		
		public function get imageGalleryData():ImageGalleryData {
			return _imageGalleryData;
		}
		
		public function set bitmapDataPlain(value:BitmapData):void {
			_bitmapDataPlain = value;
			if(!_buttonData.isActive){
				setPlain();
			}
		}
		
		public function set bitmapDataActive(value:BitmapData):void {
			_bitmapDataActive = value;
			if (_buttonData.isActive) {
				setActive();
			}
		}
		
		public function setPlain():void {
			if(_bitmapDataPlain != null){
				bitmap.bitmapData = _bitmapDataPlain;
			}
		}
		
		public function setActive():void {
			if(_bitmapDataActive != null){
				bitmap.bitmapData = _bitmapDataActive;
			}
		}
		
		private function onMousePress(e:MouseEvent):void {
			_buttonData.mousePress = true;
		}
		
		private function onMouseRelease(e:MouseEvent):void {
			_buttonData.mousePress = false;
		}
	}
}