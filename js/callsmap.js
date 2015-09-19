( function( window ){
'use strict';

function CM(){
	
	this.graph = null;
	this.idealLength = 90;	//расстояние между узлами
	this.elements = {
		namespaces: document.getElementById('namespaces')
	};

	this.NAMESPACE = '';

	this.data ={'nodes':[],'links':[]};

	this.groups = {};
	this.init();

}

CM.prototype.init = function(){

	var cm = this;
 	// смена области
 	cm.elements.namespaces.addEventListener('change', function onChangeNamespace(e) {
        var el = e.target || e.srcElement,
            ns = el.options[el.selectedIndex].value
        ;
        if (ns !== cm.NAMESPACE) {
            cm.setNamespace(ns);
        }
    });	
    ///создание графа
	cm.createGraph();
	///загрузка областей
	cm.loadNamespace();
};

CM.prototype.createGraph = function(){

	var cm = this, graph = Viva.Graph.graph();
	graph.Name = 'CallsMap';
	cm.graph = graph;


	var options = {
		springLength: 80,
        springCoeff: 1e-4,
        dragCoeff: 0.05,
        gravity: -3,
        theta: 0.5
	};

	var layout = Viva.Graph.Layout.forceDirected( graph, options );

	var svgGraphics = Viva.Graph.View.svgGraphics();
	
	svgGraphics
		.node( function( node ){
			
			
			//var groupId = node.data.group;
			//var color = cm.groups[ groupId ];
			var circle = Viva.Graph.svg('circle');
			if (!circle) return;

			circle.attr('r', 10 )
				.attr('stroke', '#fff')
				.attr('stroke-width', '1px')
				.attr('fill', '#ccc')
			;

			circle.append('title').text( node.id );

			return circle;

		})
		.placeNode( function( nodeUI, pos ){
			nodeUI.attr('cx', pos.x).attr('cy', pos.y );
		}
	);

	svgGraphics.link( function( link ){

		return Viva.Graph.svg('line').attr('stroke', '#999')
			//.attr('stroke-width', Math.sqrt(link.data))
		;

	});

    var renderer = Viva.Graph.View.renderer(graph, {
        container : document.getElementById('graph1'),
        layout : layout,
        graphics : svgGraphics,
        prerender: 20,
        renderLinks : true
    });

    renderer.run( 1000 ); 
    cm.renderer = renderer;  

	//cm.update();
};


CM.prototype.loadNamespace = function(){
	var cm = this, currentNamespace= cm.NAMESPACE ;
	cm.load('calls.map.cls?namespaces', null, function onLoadNamespace (err , namespaces ){
		if (err) { console.log(err); return; }
		cm.elements.namespaces.textContent = '';
		namespaces = namespaces || [];
		var i, ns, e, length = namespaces.length ;
		for ( i=0; i < length; i++ ) {
			ns = namespaces[i];
			e = document.createElement('option');
			e.setAttribute('value', ns);
			e.textContent = ns;
			if ( ns === currentNamespace ) e.setAttribute('selected', '');
			cm.elements.namespaces.appendChild(e);
		}
		cm.setNamespace( cm.elements.namespaces.value );
	});
};

CM.prototype.setNamespace = function (namespace) {

	var cm = this , graph = cm.graph;
	cm.NAMESPACE = namespace;
	graph.clear();
	cm.loadData();

};

///загрузка точек
CM.prototype.loadData = function(){

	var cm = this, url = 'calls.map.cls?namespace=' + cm.NAMESPACE;
	var	graph = cm.graph;

	cm.load(url,'', function onLoadData(err,result){ 

		cm.data.links = result.links;

		graph.beginUpdate();

		var link, data = cm.data, len = data.links.length ;

		while (len--) {
			link = data.links[len];
			graph.addLink( link.a, link.b );
		}

		graph.endUpdate();

	});

};

///генерация цвета
CM.prototype.color = function(){

    var r=Math.floor(Math.random() * (256));
    var g=Math.floor(Math.random() * (256));
    var b=Math.floor(Math.random() * (256));
    var color='#' + r.toString(16) + g.toString(16) + b.toString(16);
    return color;

 };

///метод загрузки данных
CM.prototype.load = function (url, data, callback) {

	var xhr = new XMLHttpRequest();

	xhr.open(data ? 'POST' : 'GET', url);

	xhr.onreadystatechange = function () {
		if (xhr.readyState === 4 && xhr.status === 200) {
			return callback(null, JSON.parse(xhr.responseText) || {});
		} else if (xhr.readyState === 4) {
			callback(xhr.responseText + ', ' + xhr.status + ': ' + xhr.statusText);
		}
	};

	xhr.send(data ? JSON.stringify(data) : undefined);

};

	window.onload = function(){ new CM(); };

})( window );
