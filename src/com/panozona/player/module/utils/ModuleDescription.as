﻿/*
 OuWei Flash3DHDView 
*/
package com.panozona.player.module.utils{
	
	public class ModuleDescription {
		
		/**
		 * Object where keys are function names values are Vectors of Classes 
		 * (Boolean, Number, String or Function) that describe functions parameters.
		 */
		public const functionsDescription:Object = new Object();
		
		private var _name:String;
		private var _version:String;
		private var _homeUrl:String;
		
		/**
		 * Setting basic data for module description. name is used to indentify loaded module 
		 * name version and homeUrl are displayed in trace window.
		 * 
		 * @param	name mandatory module name
		 * @param	version mandatory module version
		 * @param	homeUrl url address containing module description
		 */
		public function ModuleDescription(name:String, version:String, homeUrl:String) {
			_name = name;
			_version = version;
			_homeUrl = homeUrl;
		}
		
		public final function get name():String {
			return _name;
		}
		
		public final function get version():String{
			return _version;
		}
		
		public final function get homeUrl():String{
			return _homeUrl;
		}
		
		/**
		 * Used for adding descriptions of module functions that are recognized by QjPlayer.
		 * Usage of this function is supposed to be hard-coded into module constructor.
		 * For instance function foo(arg1:Boolean, arg2:Number, arg3:String, arg4:Function) 
		 * should be added as folows: addFunctionDescription("foo", Boolean, Number, String, Function);
		 * 
		 * @param	functionName name of added function
		 * @param	... args classes, supposedly only allowed classes are Boolean, Number, String and Function
		 */
		public function addFunctionDescription(functionName:String, ... args):void {
			functionsDescription[functionName] = new Vector.<Class>;
			for(var i:int = 0; i < args.length; i++){
				(functionsDescription[functionName])[i] = args[i];
			}
		}
	}
}