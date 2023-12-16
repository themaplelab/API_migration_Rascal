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

  map[str, int] transformationCount = initTransformationsCount(transformations);
  int totalTransformationCount = 0;

  try{
      CompilationUnit transformedUnit;
      for(loc f <- allFiles) {
        try {
          str content = readFile(f);  
          file = f;
          <transformedUnit, totalTransformationCount, transformationCount> = applyTransformations(
              content, 
              totalTransformationCount, 
              transformationCount,
              transformations
            );
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

	for(str transformationName <- transformationCount) {
    println("<transformationName> rule: <transformationCount[transformationName]> transformation(s)");
  }

	println("Total transformations applied: <totalTransformationCount>");
	println("Files with error: <errors>");	
	println("Number of files: <size(allFiles)>");  
  int endTime = realTime();
  println("endTime: <endTime>");
}

public map[str, int] initTransformationsCount(list[Transformation] transformations) {
  return (( ) | it + (t.name : 0) | Transformation t <- transformations);
}

public tuple[CompilationUnit, int, map[str, int]] applyTransformations(
    str code,
    int totalTransformationCount,
    map[str, int] transformationCount,
    list[Transformation] transformations
  ) {
  println("applyTransformations_started");  
  CompilationUnit unit;
  try{
    unit = parse(#CompilationUnit, code);
  }
  catch: {
    unit = parse(#CompilationUnit, "");
    println("caughtException: <unit>");
    return <unit, totalTransformationCount, transformationCount>;
  }
  println("importsTransformFile: ");

  for(Transformation transformation <- transformations) {
    CompilationUnit transformedUnit = transformation.function(unit);
    if(unit != transformedUnit) {
      println("Transformed! <transformation.name>");
      transformationCount[transformation.name] += 1;
      totalTransformationCount += 1;
    }
    unit = transformedUnit;
  }

  return <unit, totalTransformationCount, transformationCount>;
}

private CompilationUnit loomTransform(CompilationUnit c) {
  println("fileFound: <file>");
  c = executeLoomTransformation(c, file);
  return c;
}
