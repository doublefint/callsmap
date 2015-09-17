/// вызовы ..{METHODNAME}( ... )
Class calls.parserInner Extends %RegisteredObject
{

Property matcher As %Regex.Matcher [ Private, ReadOnly ];

Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	s re = "\.\." ;две точки
			_"(%?\p{L}+\p{N}*)" ;возможно %, обязательно буква, возможно цифры
			_"\(" ;открывающая скобка
	
	s i%matcher = ##class(%Regex.Matcher).%New( re ) 
	Quit $$$OK
}

Method parse(text, ByRef data) As %Status
{
	s ..matcher.Text = text
	if ..matcher.Locate() { 
		s data = ..matcher.Group(1)
		Q 1
	}
	Q 0
}

ClassMethod Test()
{
	s p =..%New()
	s test = "s map = ..%New()", method =""
	w p.parse(test, .method), !, method
	s test = "s nsp = ..namespace, class = ..class", method =""
	w p.parse(test, .method), !, method
}

}

