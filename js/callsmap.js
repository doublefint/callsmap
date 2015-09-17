
function VG(){
	
	this.graph = null;
	this.idealLength = 90;	//расстояние между узлами
	this.elements = {
		namespaces: document.getElementById("namespaces")
	}	
	this.NAMESPACE = "USER";

	///value - ширина линии
	this.data ={"nodes":[],"links":[]};

	this.colors = [
                        /*"#1f77b4", "#aec7e8",
                        "#ff7f0e", "#ffbb78",*/
    ];
    this.groups = {};
	this.init();
}

VG.prototype.init = function(){
	var vg = this;
 	// смена области
 	vg.elements.namespaces.addEventListener("change", function (e) {
        var el = e.target || e.srcElement,
            ns = el.options[el.selectedIndex].value
        ;
        if (ns !== vg.NAMESPACE) {
            vg.setNamespace(ns);
        }
    });	
    ///создание графа
    vg.createGraph(); 	
	///загрузка областей
	vg.LoadNamespase();
};

VG.prototype.createGraph = function(){
 
  var vg = this;	
  var graph = Viva.Graph.graph();    
  graph.Name = "CallsMap";
    
  vg.graph = graph;
  

	
  var layout = Viva.Graph.Layout.forceDirected(graph, {
        springLength : vg.idealLength,	//длина линии
        springCoeff : 0.00055,	//?
        dragCoeff : 0.09,	//?
        gravity : -1 ,	//?
		/*springTransform: function (link, spring) {
             spring.length = vg.idealLength *link.data.distance;
		}*/
   });

  var svgGraphics = Viva.Graph.View.svgGraphics();
	
	svgGraphics.node(function(node){
        var groupId = node.data.group , color = vg.groups[groupId];
        var circle = Viva.Graph.svg('circle')
            .attr('r', 7)
            .attr('stroke', '#fff')
            .attr('stroke-width', '1px')
            .attr("fill", color);

        circle.append('title').text(node.data.name);

        return circle;

	}).placeNode(function(nodeUI, pos){
        nodeUI.attr( "cx", pos.x).attr("cy", pos.y);
	});

	svgGraphics.link(function(link){
    return Viva.Graph.svg('line')
            .attr('stroke', '#999')
            .attr('stroke-width', Math.sqrt(link.data));
	});

    var renderer = Viva.Graph.View.renderer(graph, {
        container : document.getElementById('graph1'),
        layout : layout,
        graphics : svgGraphics,
        prerender: 20,
        renderLinks : true
    });

    renderer.run(500); 
    vg.renderer = renderer;  

	//vg.Update();
}

VG.prototype.LoadNamespase = function(){
	var vg = this, currentNamespace= vg.NAMESPACE ;
	
	vg.load("calls.map.cls?namespaces", null, function(err , namespaces){
        vg.elements.namespaces.textContent = "";	
			
		for (var i in namespaces || []) {
				var ns = namespaces[i];
		        e = document.createElement("option");
		        
		        e.setAttribute("value", ns);
		        e.textContent = ns;
		        if (ns === currentNamespace) e.setAttribute("selected", "");
		        vg.elements.namespaces.appendChild(e);
    	}
    	
    	vg.setNamespace( vg.elements.namespaces.value );
	});
}
VG.prototype.setNamespace = function (namespace) {

    var vg = this , graph = vg.graph;
    vg.NAMESPACE = namespace;   
    
    ///очистка графа  
    graph.clear();      

    
    ///загрузка новых 
	vg.LoadData();
	
	
};

///загрузка точек
VG.prototype.LoadData = function(){
	var vg = this;
	var namespace = "USER";	//vg.NAMESPACE;
	var url = "calls.map.cls?namespace=" + vg.NAMESPACE;
	vg.load(url,"",function(err,result){vg.onLoadData(result)})
}

///загрузка связей
VG.prototype.LoadLinks = function(){
	var vg = this;
	var url = "calls.map.cls?links"
	vg.load(url,"",function(err,result){vg.onLoadLinks(result)})

}


VG.prototype.onLoadData= function(result){
	var vg = this, nodes = result.nodes;
	
	vg.data.nodes = nodes ;
	var groups = vg.groups;
	var len =  nodes.length;
	while ( len--){
		groups[nodes[len].group] = vg.color();
	};

	vg.LoadLinks(); 
}

VG.prototype.onLoadLinks= function(result){
	
	var vg = this;	
	vg.data.links = result.links;	
	vg.Update(); 
	
}


///обновление графа
VG.prototype.Update = function(){
	
	var vg = this,graph = vg.graph;

    graph.beginUpdate();

	var data = vg.data ;
	
	for (var i = 0; i < data.nodes.length; ++i){
		var nm = data.nodes[i].name;
		graph.addNode( nm , data.nodes[i]);
	};
	
	for (i = 0; i < data.links.length; ++i){
 		var link = data.links[i];
		graph.addLink(link.nameFrom, link.nameTo, link.width);
    }; 
     
    graph.endUpdate();
   
};

///метод загрузки данных
VG.prototype.load = function (url, data, callback) {

    var xhr = new XMLHttpRequest();

    xhr.open(data ? "POST" : "GET", url);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4 && xhr.status === 200) {
            return callback(null, JSON.parse(xhr.responseText) || {});
        } else if (xhr.readyState === 4) {
            callback(xhr.responseText + ", " + xhr.status + ": " + xhr.statusText);
        }
    };

    xhr.send(data ? JSON.stringify(data) : undefined);

};

///генерация цвета
VG.prototype.color = function(){
	
    var r=Math.floor(Math.random() * (256));
    var g=Math.floor(Math.random() * (256));
    var b=Math.floor(Math.random() * (256));
    var color='#' + r.toString(16) + g.toString(16) + b.toString(16);
  	return color
 }
