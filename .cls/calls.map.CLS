Class calls.map Extends (%Persistent, %CSP.Page)
{

Parameter CONTENTTYPE = "application/json";

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET;

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage(ByRef data) As %Status [ ServerOnly = 1 ]
{
	if $d(%request){
		m data = %request.Data	
	}
	
	if $d(data("namespaces")) Q ..namespaces()
	if $d(data("namespace")){
		s namespace = $g(data("namespace",1))
		d ..Init(namespace)	
	}
	
	s jp = ##class(%ZEN.Auxiliary.altJSONSQLProvider).%New()
	
	s jp.sql = "Select * From calls.point"
	s jp.arrayName = "nodes"
	
	if $d(data("links")) {
		s jp.sql = "Select * From calls.link"
		s jp.arrayName = "links"
	}
	
	s jp.%Format = "twu"
	s jp.maxRows = 10000
	
	s sc = jp.%DrawJSON()
	Quit $$$OK
}

ClassMethod namespaces() As %Status
{
	s rs =##class(%SYS.Namespace).ListFunc()
	w "[" s first = 1
	while rs.%Next(){
		w:'first "," s:first first=0	
		w """",$zcvt(rs.Nsp,"O","JSON"),""""
	}
	w "]"
	Q 1
}

Property class [ SqlColumnNumber = 3 ];

Property method [ SqlColumnNumber = 4 ];

Property nameFrom(COLLATION = "EXACT") [ SqlComputeCode = { s {*} = {class}_":"_{method} }, SqlComputed, SqlComputeOnChange = (%%INSERT, class, method) ];

Index nameFrom On nameFrom;

Property line [ SqlColumnNumber = 5 ];

Property classcall [ SqlColumnNumber = 6 ];

Property methodcall [ SqlColumnNumber = 7 ];

Property nameTo(COLLATION = "EXACT") [ SqlComputeCode = { s {*} = {classcall}_":"_{methodcall} }, SqlComputed, SqlComputeOnChange = (%%INSERT, classcall, methodcall) ];

Index nameTo On nameTo;

Property namespace [ SqlColumnNumber = 2 ];

/// Для разбора полных внешних вызовов
Property parserOuter As parserOuter [ Transient ];

/// Для разбора сокращенных внутренних вызовов
Property parserInner As parserOuter [ Transient ];

ClassMethod distance(classFrom, classTo) As %Numeric [ CodeMode = expression, SqlProc ]
{
$S(classFrom=classTo:.1,1:1)
}

Query Point() As %SQLQuery [ SqlView ]
{
Select Distinct name From
(Select Distinct nameFrom as name From calls.map
Union All %Parallel
Select Distinct nameTo as name From calls.map)
}

/// , calls.map_distance(class,classcall)
Query Link() As %SQLQuery [ SqlView ]
{
Select nameFrom, nameTo, Count(1) as width, calls.map_distance(class,classcall) as distance
From calls.map 
Group By nameTo, nameFrom
}

ClassMethod Init(namespace = {$namespace})
{
	s map = ..%New()
	d map.classes(namespace)
}

/// Список классов
Method classes(nsp = {$namespace}, clsStart = "&", clsEnd = "")
{
	d ..%KillExtent()
	
	s ..namespace = nsp, data=""
	s:'$IsObject(..parserInner) ..parserInner = ##class(parserInner).%New()
	s:'$IsObject(..parserOuter) ..parserOuter = ##class(parserOuter).%New()
	/// Системный индекс с классами
	#define CLSIDX(%cls) ^|nsp|rINDEXCLASS(%cls)
	
	#; не указан с какого класса или нет данных по указанному
	#; обращаем внимание на data - там окажется системная информация о классе
	if clsStart="" || ( '$d( $$$CLSIDX(clsStart), data ) ) {
		s clsStart=$o( $$$CLSIDX(clsStart), 1, data ) ;берем ближайший следующий
	}
	
	s class = clsStart, lend = $l(clsEnd)
	while class '= "", ( $e(class, 1, lend ) '] clsEnd )  { ;пока не прошли все или имя класса не содержит искомое
		
		s ..class = $list( data, 2 ) 
		
		d ..methods()
		
		s class = $o( $$$CLSIDX(class), 1, data ) ;переходим к следующему
		
	}
}

/// for each methods in class
Method methods()
{
	s nsp = ..namespace, class = ..class
	
	#; NOTE: try use ^oddCOM
	/// System storage for class definition
	#define META ^[nsp]oddDEF
	
	if '$d($$$META(class)) Q 0 ;нет определения класса
	
	#define METHODS(%class, %meth) $$$META(%class,$$$cCLASSmethod,%meth)
		
	s method="" for { s method=$o($$$METHODS(class, method)) Quit:method="" 
	  	#;w !, class,":",method
	  	s ..method = method
	  	d ..codes()
	
	}
	Quit 1
}

Method codes()
{
	s nsp = ..namespace, class = ..class, method =..method
	#define META ^[nsp]oddDEF
	#define CODES(%class,%method,%line) $$$META(%class,$$$cCLASSmethod,%method,$$$cMETHimplementation,%line)
	
	s line="", code = "" 
	for { s line = $o( $$$CODES(class, method, line ), 1, code ) Q:line=""		
		s ..line = line 
		d ..parse( code )
 	}
}

/// вызовы $zobjclassmethod({CLASSNAME},{METHODNAME}, args...)
/// вызовы $classmethod({CLASSNAME},{METHODNAME},)
Method parse(code)
{
	k data,class,method
	if ..parserInner.parse(code,.method){
		d ..toArray(.data)
		s data("classcall") = ..class
		s data("methodcall") = method 
		s sc = ..Save(.data)
		Q 1
	}
	
	k data,class,method
	if ..parserOuter.parse(code,.class,.method){
		d ..toArray(.data)
		s data("classcall") = class
		s data("methodcall") = method
		s sc = ..Save(.data)
		Q 1
	}
	Q 1
}

Method toArray(ByRef data) [ ProcedureBlock = 0 ]
{
	s data("namespace")=..namespace
	s data("class")=..class
	s data("method")=..method
	s data("line")=..line
}

ClassMethod Save(data)
{
	&sql(Insert Into calls.map (namespace, class, method, line, classcall, methodcall)
		Values( 
			:data("namespace"),
			:data("class"), 
			:data("method"), 
			:data("line"), 
			:data("classcall"),
			:data("methodcall")
		)
	)
	Q 1
}

Storage Default
{
<Data name="mapDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>class</Value>
</Value>
<Value name="3">
<Value>method</Value>
</Value>
<Value name="4">
<Value>line</Value>
</Value>
<Value name="5">
<Value>classcall</Value>
</Value>
<Value name="6">
<Value>methodcall</Value>
</Value>
<Value name="7">
<Value>namespace</Value>
</Value>
<Value name="8">
<Value>pointFrom</Value>
</Value>
<Value name="9">
<Value>pointTo</Value>
</Value>
<Value name="10">
<Value>nameFrom</Value>
</Value>
<Value name="11">
<Value>nameTo</Value>
</Value>
</Data>
<DataLocation>^calls.mapD</DataLocation>
<DefaultData>mapDefaultData</DefaultData>
<IdLocation>^calls.mapD</IdLocation>
<IndexLocation>^calls.mapI</IndexLocation>
<StreamLocation>^calls.mapS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

