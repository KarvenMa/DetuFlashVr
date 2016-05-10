﻿/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.imagemap.controller {
	
	import com.panozona.modules.imagemap.events.MapEvent;
	import com.panozona.modules.imagemap.events.ViewerEvent;
	import com.panozona.modules.imagemap.model.WaypointData;
	import com.panozona.modules.imagemap.model.structure.Map;
	import com.panozona.modules.imagemap.model.structure.Waypoint;
	import com.panozona.modules.imagemap.model.structure.Waypoints;
	import com.panozona.modules.imagemap.view.MapView;
	import com.panozona.modules.imagemap.view.WaypointView;
	import com.panozona.player.manager.events.LoadLoadableEvent;
	import com.panozona.player.manager.utils.loading.ILoadable;
	import com.panozona.player.manager.utils.loading.LoadablesLoader;
	import com.panozona.player.module.Module;
	import com.panozona.player.module.data.property.Size;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class MapController {
		
		private var _mapView:MapView;
		private var _module:Module;
		
		private var waypointControlers:Array;
		private var arrListeners:Array;
		
		private var mapContentLoader:Loader;
		
		private var waypointsLoader:LoadablesLoader;
		
		private var previousMapId:String;
		
		public function MapController(mapView:MapView, module:Module){
			_mapView = mapView;
			_module = module;
			
			waypointControlers = new Array();
			arrListeners = new Array();
			
			mapContentLoader = new Loader();
			mapContentLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, mapContentLost, false, 0, true);
			mapContentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, mapContentLoaded, false, 0, true);
			
			waypointsLoader = new LoadablesLoader();
			waypointsLoader.addEventListener(LoadLoadableEvent.LOST, waypointsLost);
			waypointsLoader.addEventListener(LoadLoadableEvent.LOADED, waypointsLoaded);
			
			_mapView.imageMapData.mapData.addEventListener(MapEvent.CHANGED_CURRENT_MAP_ID, handleCurrentMapIdChange, false, 0, true);
			_mapView.imageMapData.mapData.addEventListener(MapEvent.CHANGED_RADAR_FIRST, handleRadarFirstChange, false, 0, true);
			_mapView.imageMapData.mapData.addEventListener(ViewerEvent.FOCUS_LOST, handleFocusLost, false, 0, true);
			
			var panoramaEventClass:Class = ApplicationDomain.currentDomain.getDefinition("com.panozona.player.manager.events.PanoramaEvent") as Class;
			_module.qjPlayer.manager.addEventListener(panoramaEventClass.PANORAMA_LOADED, onPanoramaLoaded, false, 0, true);
			
			if(_module.qjPlayer.manager.currentPanoramaData != null){
				onPanoramaLoaded(); // in case when map just got changed
			}
			
			//enterframe
			_module.stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame, false, 0, true);
		}
		
		private function onPanoramaLoaded(loadPanoramaEvent:Object=null):void {
			for each(var map:Map in _mapView.imageMapData.mapData.maps.getChildrenOfGivenClass(Map)) {
				for each(var waypoints:Waypoints in map.getChildrenOfGivenClass(Waypoints)) {
					for each(var waypoint:Waypoint in waypoints.getChildrenOfGivenClass(Waypoint)) {
						if (waypoint.target == _module.qjPlayer.manager.currentPanoramaData.id) {
							_mapView.imageMapData.mapData.currentMapId = map.id;
							return;
						}
					}
				}
			}
			if(_mapView.imageMapData.mapData.currentMapId == null){
				_mapView.imageMapData.mapData.currentMapId = (_mapView.imageMapData.mapData.maps.getChildrenOfGivenClass(Map)[0]).id;
			}
		}
		
		private function handleCurrentMapIdChange(e:Event):void {
			mapContentLoader.unload();
			//waypointsLoader.abort();
			destroyWaypoints();
			_mapView.imageMapData.viewerData.focusPoint = new Point(NaN, NaN);
			mapContentLoader.load(new URLRequest(_mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).path),new flash.system.LoaderContext(true));
			if (previousMapId != null) {
				_module.qjPlayer.manager.runAction(_mapView.imageMapData.mapData.getMapById(previousMapId).onUnset);
			}
			previousMapId = _mapView.imageMapData.mapData.currentMapId;
			_module.qjPlayer.manager.runAction(_mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).onSet);
		}
		
		
		private function handleRadarFirstChange(e:Event):void {
			_mapView.placeContainers();
		}
		
		private function handleFocusLost(e:Event):void {
			for each( var waypointController:WaypointController in waypointControlers) {
				waypointController.lostFocus();
			}
		}
		
		private function mapContentLost(e:IOErrorEvent):void {
			_module.printError(e.text);
		}
		
		private function mapContentLoaded(e:Event):void {
			_mapView.imageMapData.viewerData.currentZoom = _mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).zoom;
			_mapView.content = mapContentLoader.content;
			_mapView.imageMapData.viewerData.size = new Size(mapContentLoader.content.width, mapContentLoader.content.height);
			buildWaypoints();
			

			_module.printInfo("_mapView:w"+mapContentLoader.content.width+":h"+ mapContentLoader.content.height);
			
			_mapView.x = _mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).xx;
			_mapView.y = _mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).yy;
		}
		
		private function handleEnterFrame(e:Event):void
		{
			if(_mapView.content != null)
			{
				var m:MovieClip=_mapView.content as MovieClip;
				if(m != null)
				{
					var mestr:String = m.memostr;
					if(mestr != null)
					{
						var s:Sprite = Sprite(Sprite(_module.getChildAt(0)).getChildAt(0)).getChildByName("textcontainer") as Sprite;
						if(s != null)
						{
							if(mestr == "")
							{
								if(s.numChildren > 0){
									
									s.removeChildAt(0);
								}
							}
							else
							{
								if(s.numChildren > 0){
									
									s.removeChildAt(0);
								}
								
								var  textFormat:TextFormat = new TextFormat();
								textFormat.font = "宋体";
								textFormat.size = 12;
								textFormat.color = 0xFFFF00;
								textFormat.bold = true;
						
								
								var textField:TextField=new TextField();
								textField.defaultTextFormat = textFormat;
								textField.multiline = true;
								textField.selectable = false;
								textField.autoSize = TextFieldAutoSize.LEFT;
								textField.blendMode = BlendMode.LAYER;
								textField.background = false;
								textField.antiAliasType = AntiAliasType.ADVANCED;
								textField.text=mestr;
								
								s.blendMode = BlendMode.LAYER;
								s.addChild(textField);
							}
						}
					}
				}
			}
		}
		
		private function buildWaypoints():void {
			var waypointsGroup:Vector.<ILoadable> = new Vector.<ILoadable>();
			for each (var waypoints:Waypoints in _mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId).getChildrenOfGivenClass(Waypoints)) {
				waypointsGroup.push(waypoints);
			}
			waypointsLoader.load(waypointsGroup);
		}
		
		protected function waypointsLost(event:LoadLoadableEvent):void {
			_module.printError("Could not load waypoints: " + event.loadable.path);
		}
		
		protected function waypointsLoaded(event:LoadLoadableEvent):void {
			var bitmapData:BitmapData = new BitmapData(event.content.width, event.content.height, true, 0);
			bitmapData.draw((event.content as Bitmap).bitmapData);
			
			var waypoints:Waypoints = (event.loadable as Waypoints);
			
			var cellHeight:int = 0;
			var bitmapDataPlain:BitmapData = null;
			var bitmapDataHover:BitmapData = null;
			var bitmapDataActive:BitmapData = null;
			
			if(waypoints.type == 1) //单个元素
			{
				cellHeight = bitmapData.height;
				bitmapDataPlain = bitmapDataHover =  bitmapDataActive = bitmapData;
				
			}
			else
			{
				cellHeight = Math.ceil((bitmapData.height - 2) / 3);
				
				bitmapDataPlain = new BitmapData(bitmapData.width, cellHeight, true, 0);
				bitmapDataPlain.copyPixels(bitmapData, new Rectangle(0, 0, bitmapData.width, cellHeight), new Point(0, 0), null, null, true);
				
				bitmapDataHover = new BitmapData(bitmapData.width, cellHeight, true, 0);
				bitmapDataHover.copyPixels(bitmapData, new Rectangle(0, cellHeight + 1, bitmapData.width, cellHeight), new Point(0, 0), null, null, true);
				
				bitmapDataActive = new BitmapData(bitmapData.width, cellHeight, true, 0);
				bitmapDataActive.copyPixels(bitmapData, new Rectangle(0, cellHeight * 2 + 2, bitmapData.width, cellHeight), new Point(0, 0), null, null, true);
			}
			
			var waypointView:WaypointView;
			var waypointController:WaypointController;
			var map:Map = _mapView.imageMapData.mapData.getMapById(_mapView.imageMapData.mapData.currentMapId);
			
			
			if (map.getChildrenOfGivenClass(Waypoints).indexOf(waypoints) < 0) return;
			
			for each(var waypoint:Waypoint in waypoints.getChildrenOfGivenClass(Waypoint)) {
				waypointView = new WaypointView(_mapView.imageMapData, new WaypointData(waypoint, waypoints.radar, map.panShift, waypoints.move,
				bitmapDataPlain, bitmapDataHover, bitmapDataActive), _mapView);
				waypointView.button.scaleX = waypointView.radar.scaleX = 1 / _mapView.parent.scaleX;
				waypointView.button.scaleY = waypointView.radar.scaleY = 1 / _mapView.parent.scaleY;
				var added:Boolean = false;
				for (var i:int = 0; i < _mapView.waypointsContainer.numChildren && !added; i++) {
					if ((_mapView.waypointsContainer.getChildAt(i) as WaypointView).waypointData.waypoint.position.y > waypointView.waypointData.waypoint.position.y) {
						_mapView.waypointsContainer.addChildAt(waypointView, i);
						added = true;
					}
				}
				if (!added) {
					_mapView.waypointsContainer.addChild(waypointView);
				}
				waypointController = new WaypointController(waypointView, _module);
				waypointControlers.push(waypointController);
				if (waypoint.mouse.onOver != null) {
					waypointView.button.addEventListener(MouseEvent.ROLL_OVER, getMouseEventHandler(waypoint.mouse.onOver));
					arrListeners.push({type:MouseEvent.ROLL_OVER, listener:getMouseEventHandler(waypoint.mouse.onOver)});
				}
				if (waypoint.mouse.onOut != null) {
					waypointView.button.addEventListener(MouseEvent.ROLL_OUT, getMouseEventHandler(waypoint.mouse.onOut));
					arrListeners.push({type:MouseEvent.ROLL_OUT, listener:getMouseEventHandler(waypoint.mouse.onOut)});
				}
			}
		}
		
		 
		
		private function getMouseEventHandler(actionId:String):Function{
			return function(e:MouseEvent):void {
				_module.qjPlayer.manager.runAction(actionId);
			}
		}
		
		private function destroyWaypoints():void {
			for (var i:int = 0; i < _mapView.waypointsContainer.numChildren; i++ ) {
				for (var j:Number = 0; j < arrListeners.length; j++) {
					if (_mapView.waypointsContainer.getChildAt(i).hasEventListener(arrListeners[j].type)) {
						_mapView.waypointsContainer.getChildAt(i).removeEventListener(arrListeners[j].type, arrListeners[j].listener);
					}
				}
			}
			while (_mapView.waypointsContainer.numChildren) {
				_mapView.waypointsContainer.removeChildAt(0);
			}
			while (_mapView.radarContainer.numChildren) {
				_mapView.radarContainer.removeChildAt(0);
			}
			while (waypointControlers.length) {
				waypointControlers.pop();
			}
		}
	}
}