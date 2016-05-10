/*
 OuWei Flash3DHDView 
*/
package com.panozona.modules.linkopener.data{
	
	
	import com.panozona.modules.linkopener.data.structure.Link;
	import com.panozona.modules.linkopener.data.structure.Links;
	
	import com.panozona.player.module.data.DataNode;
	import com.panozona.player.module.data.ModuleData;
	import com.panozona.player.module.utils.DataNodeTranslator;
	
	public class LinkOpenerData {
		
		public const links:Links = new Links();
		
		public function LinkOpenerData(moduleData:ModuleData, qjPlayer:Object) {
			
			var translator:DataNodeTranslator = new DataNodeTranslator(qjPlayer.managerData.debugMode);
			
			for each(var dataNode:DataNode in moduleData.nodes) {
				if (dataNode.name == "links") {
					translator.dataNodeToObject(dataNode, links);
				}else {
					throw new Error("Invalid node name: " + dataNode.name);
				}
			}
			
			if (qjPlayer.managerData.debugMode) {
				var linkIds:Object = new Object();
				for each (var link:Link in links.getChildrenOfGivenClass(Link)) {
					if (link.id == null) throw new Error("link id not specified.");
					if (link.content == null) throw new Error("link content not specified.");
					if (linkIds[link.id] != undefined) {
						throw new Error("Repeating link id: " + link.id);
					}else {
						linkIds[link.id] = ""; // something
					}
				}
			}
		}
	}
}