/// [s]ource [c]ontrol plugin for Cache v.2014.1 or greater 
/// ( use %Compiler.UDL.TextServices API )
/// export or import classes and routines as [plain] text
/// Installation:
/// <ol>
/// <li>Create in Studio empty class sc.plain and copy-past this code. Compile class </li>
/// <li>Set working directory for current namespace - d ##class(sc.plain).directory("c:\mysource\") </li>
/// <li>Backup your sources  </li>
/// <li>Export all sources - d ##class(sc.plain).exportAll</li>
/// <li>Setup class sc.plain as source control class in System Managment Portal </li>
/// <li>Reopen Studio</li>
/// </ol>
/// You can import all previously exported sources from your working directory- d ##class(sc.plain).importAll()
Class sc.plain Extends %Studio.SourceControl.Base
{

/// known extensions
Parameter EXTENSIONS = "CLS,MAC,INT,INC";

/// set or get working directory
/// by default - current namespace database directory
ClassMethod directory(directory)
{
	#define gl ^sc
	if $d( directory ) {
		s $$$gl = directory Q directory
	}
	s directory = $g( $$$gl ) Q:directory="" $zu(12,"")
	Q directory
}

/// Will be silent 
/// Used to control which dialogs appear in Studio, if the position is '1'
/// then this dialog will appears and if it is '0' then the dialog will not
/// appear and it will assume that the answer to the dialog was to either accept it
/// or say yes, depending on the dialog. The dialog are:<ul>
/// <li>1 : Present dialog on check in</li>
/// <li>2 : Present dialog on check out</li>
/// <li>3 : Ask to add new item to source control</li>
/// <li>4 : Ask to remove deleted item from source control</li></ul>
Parameter Flags As STRING = 0000;

/// Import the file from the external format into Cache.
/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(code As %String) As %Status
{
    Q ..on( , code )
}

/// Called when Studio save something
Method OnAfterSave(code As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    Q ..on( , code )
}

/// Called when Studio compile code
/// and some parts of code may be changed
/// Storage for class, for example
Method OnAfterCompile(code As %String) As %Status
{
    Q ..on( , code )
}

/// Called when Studio delete code
Method OnAfterDelete(code As %String) As %Status
{
 	Q ..on( "delete", code )
}

ClassMethod on(event = "change", code) As %Status
{
	
	d ..parse( code, .name, .ext )
	
	s allowed = $lfs(..#EXTENSIONS) Q:'$lf( allowed, ext ) 1
	
	s file = ..filename( code )
	if event = "delete" Q ..delete( code, file )
	
	s fileTS = ..fileTS( file )
	s codeTS = ..codeTS( code )
	
	Q:codeTS=fileTS 1 ; timestamps equal
	if codeTS ] fileTS Q ..export( code, file ) ; code newer - export from database
	if fileTS ] codeTS Q ..import( file, code ) ; file newer - import from file
}

/// convert code name to file name
ClassMethod filename(code) [ CodeMode = expression ]
{
..directory() _ code
}

/// get file changed timestamp 
ClassMethod fileTS(file) [ ProcedureBlock = 0 ]
{
	Q:'##class(%File).Exists( file ) ""
    Q $zdt( ##class(%File).GetFileDateModified( file ), 3 )
}

/// get code changed timestamp
ClassMethod codeTS(code) [ CodeMode = expression ]
{
##class(%RoutineMgr).TS( code )
}

/// split code name <var>code</var> , for example - "sc.plain.CLS", 
/// into code name <var>name</var> - "sc.plain" and extension <var>ext</var> cls
ClassMethod parse(code, Output name, Output ext) As %Status
{
	s list = $LFS( code, "." ), length = $ll( list )
	s name = $li( list, 1, length - 1 ), name = $lts( name, "." )
	s ext = $lg( list , length ), ext = $zcvt( ext, "U" )
	Q 1
}

/// export code to file
ClassMethod export(code, filename = "") As %Status
{
	
	s:filename="" filename = ..filename( code ) ;full pathname with workdir and extension
 	
 	d ..w( code_" -> " _ filename )
	
	s directory = ##class(%File).GetDirectory( filename)
	s sc = ##class(%File).CreateDirectoryChain( directory )
	s file = ##class(%File).%New( filename )
	s sc = file.Open( "WNUK\UTF8\" ) Q:'sc sc
	
	d ..parse( code, .name, .ext )
	
	if ext = "CLS" {
		s sc = ##class(%Compiler.UDL.TextServices).GetTextAsStream( , name, .file ) 
	} else {
		s sc = file.CopyFrom( ##class(%Routine).%OpenId( code ) ) 
	}
	
	Q file.%Save()
}

/// import code from file
ClassMethod import(filename, code = "") As %Status
{
	s:code="" code=##class(%File).GetFilename( filename )
	
	d ..w( filename _ " -> " _ code  )
	
	s file = ##class(%File).%New( filename )
	s sc = file.Open("RUK\UTF8\") Q:'sc sc 
	d ..parse( code, .name, .ext )
	
	if ext = "CLS" {
		s sc = ##class(%Compiler.UDL.TextServices).SetTextFromStream( , name, file )
	
	} else {
		
		if ##class(%Routine).Exists( code ) {
            s routine = ##class(%Routine).%OpenId( code )
        } else {
            s routine = ##class(%Routine).%New( code )
        }
        d routine.Clear() 
        d routine.CopyFrom( file )
        s sc = routine.%Save() Q:'sc sc
		
	}
	
	Q sc
}

ClassMethod delete(code, file) As %Status
{
	s sc = ##class(%File).Delete(file)
	d ..w( " DELETE " _ file _" -> "_+sc )
	Q 1
}

/// Initial export classes and routines
ClassMethod exportAll()
{

	#; SummaryFunc - method generated by Caché for query "Summary"
    s rs=##class(%Dictionary.ClassDefinition).SummaryFunc()
    while rs.%Next() { 
      if $e( rs.Name ) = "%"  continue
      if rs.System && rs.Hidden  continue
      s sc = ..export( rs.Name_".CLS" )
    }

	#; RoutineListFunc - method generated by Cache for class query RoutineList
	s rs = ##class(%Routine).RoutineListFunc() 
	while rs.%Next(){
		s sc = ..export( rs.name)
	}
}

ClassMethod importAll()
{
	s masks = $lfs( ..#EXTENSIONS )
	s masks = "*." _ $lts( masks, ";*." )
	s rs = ##class(%File).FileSetFunc(..directory(), masks )
	while rs.%Next(){
		s file = rs.Name		
		s sc = ..import( file ) d:'sc ..w($system.Status.GetOneErrorText(sc))
	}
}

ClassMethod w(msg)
{
 s io=$io u 0 w !, msg u io
}

}

