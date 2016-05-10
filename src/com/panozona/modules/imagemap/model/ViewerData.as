﻿/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.imagemap.model {
	
	import com.panozona.modules.imagemap.events.ViewerEvent;
	import com.panozona.modules.imagemap.model.structure.Viewer;
	import com.panozona.modules.imagemap.model.structure.Zoom;
	import com.panozona.player.module.data.property.Size;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	public class ViewerData extends EventDispatcher{
		
		public const viewer:Viewer = new Viewer();
		
		private var _size:Size;
		private var _currentZoom:Zoom;
		private var _focusPoint:Point;
		
		private var _moveLeft:Boolean;
		private var _moveRight:Boolean;
		private var _moveUp:Boolean;
		private var _moveDown:Boolean;
		
		private var _zoomIn:Boolean;
		private var _zoomOut:Boolean;
		
		private var _mouseOver:Boolean;
		private var _mouseDrag:Boolean;
		
		public function ViewerData() {
			_size = new Size(NaN, NaN);
			_currentZoom = new Zoom();
			_focusPoint = new Point(NaN, NaN);
		}
		
		public function get size():Size {return _size;}
		public function set size(value:Size):void {
			_size.width = value.width;
			_size.height = value.height;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_SIZE));
		}
		
		public function get currentZoom():Zoom {return _currentZoom;}
		public function set currentZoom(value:Zoom):void {
			_currentZoom.init = value.init * 0.01;
			_currentZoom.max = value.max * 0.01;
			_currentZoom.min = value.min * 0.01;
		}
		
		public function get focusPoint():Point {return _focusPoint;}
		public function set focusPoint(value:Point):void {
			_focusPoint.x = value.x;
			_focusPoint.y = value.y;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_FOCUS_POINT));
		}
		
		public function get moveLeft():Boolean {return _moveLeft;}
		public function set moveLeft(value:Boolean):void {
			if (_moveLeft == value) return;
			_moveLeft = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOVE));
		}
		
		public function get moveRight():Boolean {return _moveRight;}
		public function set moveRight(value:Boolean):void {
			if (_moveRight == value) return;
			_moveRight = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOVE));
		}
		
		public function get moveUp():Boolean {return _moveUp;}
		public function set moveUp(value:Boolean):void {
			if (_moveUp == value) return;
			_moveUp = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOVE));
		}
		
		public function get moveDown():Boolean {return _moveDown;}
		public function set moveDown(value:Boolean):void {
			if (_moveDown == value) return;
			_moveDown = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOVE));
		}
		
		public function get zoomIn():Boolean {return _zoomIn;}
		public function set zoomIn(value:Boolean):void {
			if (_zoomIn == value) return;
			_zoomIn = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_ZOOM));
		}
		
		public function get zoomOut():Boolean {return _zoomOut;}
		public function set zoomOut(value:Boolean):void {
			if (_zoomOut == value) return;
			_zoomOut = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_ZOOM));
		}
		
		public function get mouseOver():Boolean {return _mouseOver;}
		public function set mouseOver(value:Boolean):void {
			if (value == _mouseOver) return;
			_mouseOver = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOUSE_OVER));
		}
		
		public function get mouseDrag():Boolean {return _mouseDrag;}
		public function set mouseDrag(value:Boolean):void {
			if (value == _mouseDrag) return;
			if (value && !_mouseOver) return;
			_mouseDrag = value;
			dispatchEvent(new ViewerEvent(ViewerEvent.CHANGED_MOUSE_DRAG));
		}
	}
}