
package com.panosalado.controller{
	
	import com.panosalado.core.PanoSalado;
	import com.panosalado.events.ViewEvent;
	import com.panosalado.model.Characteristics;
	import com.panosalado.model.ViewData;
	import com.panosalado.view.Panorama;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Nanny {
		
		protected var _panorama:Panorama;
		protected var _viewData:ViewData;
		protected var _managedChildren:Sprite;
		protected var _tempChildren:Vector.<DisplayObject>;
		
		public function Nanny() {
			_tempChildren = new Vector.<DisplayObject>();
		}
		
		public function processDependency(reference:Object,characteristics:*):void {
			if (characteristics == Characteristics.VIEW_DATA) viewData = reference as ViewData;
		}
		
		protected function set viewData(value:ViewData):void {
			if (_viewData === value) return;
			
			if (value != null) {
				_managedChildren = (value as PanoSalado).managedChildren
				value.addEventListener(ViewEvent.PATH, startManagingChildren, false, 0, true);
				value.addEventListener(ViewEvent.PATH, showManagedChildren, false, 0, true);
				value.addEventListener(ViewEvent.NULL_PATH, hideManagedChildren, false, 0, true);
			}else {
				_viewData.removeEventListener(ViewEvent.PATH, startManagingChildren);
				_viewData.removeEventListener(ViewEvent.PATH, moveManagedChildren);
				_viewData.removeEventListener(ViewEvent.PATH, showManagedChildren);
				_viewData.removeEventListener(ViewEvent.NULL_PATH, hideManagedChildren);
				_managedChildren = null
			}
			_viewData = value;
		}
		
		protected function showManagedChildren(e:Event):void {
			if (_managedChildren == null) return;
			_managedChildren.visible = true;
		}
		protected function hideManagedChildren(e:Event):void {
			if (_managedChildren == null) return;
			_managedChildren.visible = false;
		}
		
		protected function startManagingChildren(e:Event):void { // this ignores the first path so that pre added hotspots are nor moved
			_viewData.removeEventListener(ViewEvent.PATH, startManagingChildren);
			_viewData.addEventListener(ViewEvent.PATH, moveManagedChildren, false, 0, true);
		}
		
		protected function moveManagedChildren(e:Event=null):void {
			if (_managedChildren == null) return;
			var len:int = _managedChildren.numChildren;
			var i:int = 0;
			while (0 < len) {
				_tempChildren[i] = _managedChildren.removeChildAt(0);
				len--;
				i++;
			}
		}
	}
}