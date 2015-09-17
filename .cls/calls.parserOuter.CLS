/// Парсер для внешних вызовов
Class calls.parserOuter Extends %RegisteredObject
{

Property matcher As %Regex.Matcher [ Private, ReadOnly ];

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	s re = "##class\(" ;ищем группу ##class(, которая повторяется один раз
				_"(" ;открываем группу
					_"[^\)]+" //любые символы кроме закрывающей скобки
				_")"		
			_"\){1}" ;имя класса закрывается скобкой
			_"\.{1}" ; и точкой
			_"(" ;открываем группу для имени метода
				_"[^\(]+" //любые символы кроме открывающей скобки
			_")"
			_"\({1}" //открывающая скобка
	s i%matcher = ##class(%Regex.Matcher).%New( re ) 
	Quit $$$OK
}

Method parse(text, ByRef class, ByRef method) As %Status
{
	s ..matcher.Text = text 
	if ..matcher.Locate() { 
		s class = ..matcher.Group(1)
		s method = ..matcher.Group(2)
		Q 1
	}
	Q 0
}

}

