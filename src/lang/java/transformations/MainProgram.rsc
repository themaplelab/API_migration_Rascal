module lang::java::transformations::MainProgram

import IO; 
import List; 
import ParseTree; 
import String; 
import Map;
import Set;

import util::IOUtil;
import util::Benchmark;
import lang::java::\syntax::Java18;
import lang::java::transformations::Loomizer;

data Transformation = transformation(str name, CompilationUnit (CompilationUnit) function);
loc file;
public void main(str path = "") {
  int startedTime = realTime();
  println("startedTime: <startedTime>");
    loc base = |file:///| + path; 

    if( (path == "") || (! exists(base)) || (! isDirectory(base)) ) {
       println("Invalid path <path>"); 
       return; 
    }
	list[loc] allFiles = findAllJavaFiles(base, "java"); 

	int errors = 0; 

  list[Transformation] transformations = [
    transformation("Loomizer", loomTransform)
  ];

  try{
      CompilationUnit transformedUnit;
      for(loc f <- allFiles) {
        try {
          str content = readFile(f);  
          file = f;
          <transformedUnit> = applyTransformations(content, transformations);
          if (unparse(transformedUnit) != "") {
            writeFile(f, transformedUnit);
          }
        }
        catch: {
          continue;
        }
      }
  } catch:{
    errors = errors + 1;
  }
	println("Files with error: <errors>");	
  int endTime = realTime();
  println("endTime: <endTime>");
}

public tuple[CompilationUnit] applyTransformations(str code, list[Transformation] transformations) {
  println("applyTransformations_started");  
  CompilationUnit unit;
  try{
    unit = parse(#CompilationUnit, code);
  }
  catch: {
    unit = parse(#CompilationUnit, "");
    println("caughtException: <unit>");
    return <unit>;
  }
  for(Transformation transformation <- transformations) {
    CompilationUnit transformedUnit = transformation.function(unit);
    if(unit != transformedUnit) {
      println("Transformed! <transformation.name>");
    }
    unit = transformedUnit;
  }
  return <unit>;
}

private CompilationUnit loomTransform(CompilationUnit c) {
  println("fileFound: <file>");
  c = executeLoomTransformation(c, file);
  return c;
}
