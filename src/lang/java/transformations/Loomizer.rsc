module lang::java::transformations::Loomizer
import IO;
import ParseTree;
import util::Maybe;
import util::MaybeManipulation;
import Map;
extend Type;
extend Message;
extend List;
import Set;
import String;
import lang::java::\syntax::Java18;
import DateTime;

data Argument = argument(str argType, Expression expression);
map[VariableDeclaratorId, UnannType] variableNameTypeMap = ( );
map[VariableDeclaratorId, UnannType] classVariableNameTypeMap = ( );
map[str, str] methodTypeMap = ( );
map[str, str] consThisTypeMap = ( );
list[str] variableN = [];
list[str] variableTy = [];
bool isThreadFacImportNeeded = false;
CompilationUnit compilationUnit;
loc locFile;
datetime startedTIme;

/* executing both detection and transformation 
*  each compilationUnit corresponding to each java file and location of the file are passed as arguments
*/
public CompilationUnit executeLoomTransformation(CompilationUnit unit, loc file) {
	startedTIme = now();
	println("startedTIme: <startedTIme>");
	// This map is maintained to add class level declared variables
	classVariableNameTypeMap = ( );
	// This map is maintained to add method level variables and arguments passed in
	variableNameTypeMap = ( );
	// The following map is responsible to store the method name and the return tpe
	methodTypeMap = ( );
	// The following map is responsible to store the constructor instance var name and the data tpe
	consThisTypeMap = ( );
	println("transformation started: <file>");
	variableN = [];
	variableTy = [];
	compilationUnit = unit;
	locFile = file;
	isThreadFacImportNeeded = false;
	extractInstanceVariables(unit);
	unit = extractMethodsAndPatterns(unit, file);
	/* If the thread factory is used during the transformations, it needs to be imported */
	if (isThreadFacImportNeeded) {
		unit = updateImports(unit);
	}
	return unit;
}

/* core of the loomizer where traversing through all the elements
*  detection and then transformation happens
*/
public CompilationUnit extractMethodsAndPatterns(CompilationUnit unit, loc file) {
  datetime methodTime = now();
  println("class file extraction started: <methodTime>");
  MethodDeclaration previousMethodDeclaration; 
  int count = 0;
  unit = top-down visit(unit) {
	// extracting class variables
	case FieldDeclaration f: {
		UnannType vType;
		VariableDeclaratorId name;
		f = top-down visit(f) {
			case UnannType s: { 
				vType = s;
			}
			case VariableDeclaratorId s: {
				name = s;
			}
		}
		classVariableNameTypeMap += (name : vType);
	}
	// go through each method
	case MethodDeclaration b : {
		count += 1;
		if (count > 1 && contains(unparse(previousMethodDeclaration), unparse(b))) {
			println("inner method found");
		} else {
			variableNameTypeMap = classVariableNameTypeMap;
		}
		methodName="";
		returnType="";
		b = top-down visit(b) {
			case MethodHeader h: {
				h = top-down visit(h) {
					case MethodDeclarator md: {
						md = top-down visit(md) {
							case FormalParameter f : { 
								UnannType vType;
								VariableDeclaratorId name;
								f = top-down visit(f) {
									case UnannType s: { 
										vType = s;
									}
									case VariableDeclaratorId s: {
										name = s;
									}
								}
								// store names and types of arguments in each method in the following map
								variableNameTypeMap += (name : vType);
							}
							case Identifier i: {
								methodName = unparse(i);
								println("analyzing method: <methodName>");
							}
						}
					}
					case Result r: {
						returnType = unparse(r);
					}
				}
				methodTypeMap += (methodName : returnType );
			}
			// variables declared within the method are considered
			case LocalVariableDeclaration lvd: { 
				UnannType vType;
				VariableDeclaratorId name;
				lvd = top-down visit(lvd) {
					case UnannType s: { 
						vType = s;
					}
					case VariableDeclaratorId s: {
						name = s;
					}
				}
				variableNameTypeMap += (name : vType);
			}
		}
		previousMethodDeclaration = b;
	}
	case (BlockStatement) `Thread <VariableDeclaratorId id> = new Thread(<ArgumentList args>);` : {
		BlockStatement blockstatementExp = (BlockStatement) `Thread <VariableDeclaratorId id> = new Thread(<ArgumentList args>);`;
		println("bb: <blockstatementExp>");
		datetime detectedTime = now();
  		println("blockStatement : <blockstatementExp> detected : <detectedTime>");
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		// extract argument list
		top-down visit(blockstatementExp) {
			case ArgumentList argList : argumentList += argList; 
		}
		//get types of arguments
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		println("numberOfTypes :<numberOfTypes>");
		BlockStatement replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal2: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str expressionArgument = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
					replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
					isReplacement = true;
				}
			}
		} else if (numberOfTypes == 2) {
			println("numberOfTypes44 :<types[0]>");
		    println("numberOfTypes66 :<types[1]>");

			str type0 = types[0];
			str type1 = types[1];
			if ((type0 != "String" && type0 != "Runnable" && type0 != "ThreadGroup")) {
					str typeOfArg = findTypeOfArg(unit, type0, file, "");
					println("typeOfArgFinal6: <typeOfArg>");
					Expression exp = typesOfArguments[type0];
					delete(typesOfArguments, type0);
					type0 = typeOfArg;
					typesOfArguments += (typeOfArg: exp);

			}
			if ((type1 != "String" && type1 != "Runnable" && type1 != "ThreadGroup")) {
					str typeOfArg = findTypeOfArg(unit, type1, file, "");
					println("typeOfArgFinal7: <typeOfArg>");
					Expression exp = typesOfArguments[type1];
					delete(typesOfArguments, type1);
					type1 = typeOfArg;
					typesOfArguments += (typeOfArg: exp);
			}
			if ((types[0] == "ThreadGroup" && types[1] == "Runnable") || (types[0] == "Runnable" && types[1] == "ThreadGroup")) {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str expressionArgument = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
						replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
						isReplacement = true;
						break;
					}
				}
			} else if (types[0] == "ThreadGroup" && (types[1] != "String" && types[1] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[1]];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if (types[1] == "ThreadGroup" && (types[0] != "String" && types[0] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[0]];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if ((types[0] == "Runnable" && (types[1] == "String" || types[1] == "StringBuffer")) || ((types[0] == "String" || types[0] == "StringBuffer") && types[1] == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String" || tId == "StringBuffer") {
						Expression argument0 = typesOfArguments[tId];
						nameArguments = unparse(argument0);
					}
				}
				ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
				ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>);`;
				isReplacement = true;
			}
		} else if (numberOfTypes == 3) {
			str runnableArguments = "";
			str nameArguments = "";
			for(str tId <- typesOfArguments) {
				if (tId == "Runnable") {
					Expression argument0 = typesOfArguments[tId];
					runnableArguments = unparse(argument0);
				}
				if (tId == "String" || tId == "StringBuffer") {
					Expression argument0 = typesOfArguments[tId];
					nameArguments = unparse(argument0);
				}
			}
			ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
			ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
			replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>);`;
		    isReplacement = true;
		}
		if (isReplacement == true) {
			datetime transformedTime = now();
  			println("blockStatement : <replacingExpression> transformed : <transformedTime>");
			insert(replacingExpression);
		}
	}
	case (ReturnStatement) `return new Thread(<ArgumentList args>);` : {
		ReturnStatement returnSte = (ReturnStatement) `return new Thread(<ArgumentList args>);`;
		datetime detectedTime = now();
  		println("returnStatement : <returnSte> detected : <detectedTime>");
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(returnSte) {
			case ArgumentList argList : argumentList += argList; 
		}
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		println("types_found: <types[0]> :<types[1]>");
		ReturnStatement replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal1: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str expressionArgument = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
					replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
					isReplacement = true;
				}
			}
		}
		else if (numberOfTypes == 2) {
			str type0 = types[0];
			str type1 = types[1];
			if ((type0 != "String" && type0 != "Runnable" && type0 != "ThreadGroup")) {
					str typeOfArg = findTypeOfArg(unit, type0, file, "");
					println("typeOfArgFinal6: <typeOfArg>");
					Expression exp = typesOfArguments[type0];
					delete(typesOfArguments, type0);
					type0 = typeOfArg;
					typesOfArguments += (typeOfArg: exp);

			}
			if ((type1 != "String" && type1 != "Runnable" && type1 != "ThreadGroup")) {
					str typeOfArg = findTypeOfArg(unit, type1, file, "");
					println("typeOfArgFinal7: <typeOfArg>");
					Expression exp = typesOfArguments[type1];
					delete(typesOfArguments, type1);
					type1 = typeOfArg;
					typesOfArguments += (typeOfArg: exp);
			}
			if ((type0 == "ThreadGroup" && type1 == "Runnable") || (type0 == "Runnable" && type1 == "ThreadGroup")) {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str expressionArgument = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
						replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
						isReplacement = true;
						break;
					}
				}
			} else if (type0 == "ThreadGroup" && (type1 != "String" && type1 != "Runnable")) {
				Expression argument0 = typesOfArguments[type1];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if (type1 == "ThreadGroup" && (type0 != "String" && type0 != "Runnable")) {
				Expression argument0 = typesOfArguments[type0];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if ((type0 == "Runnable" && ( type1 == "String" || type1 == "StringBuffer" )) || ((type0 == "String" || type0 == "StringBuffer") && type1 == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String" || tId == "StringBuffer") {
						Expression argument0 = typesOfArguments[tId];
						nameArguments = unparse(argument0);
					}
				}
				ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
				ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>);`;
				isReplacement = true;
			}
		} else if (numberOfTypes == 3) {
			str runnableArguments = "";
			str nameArguments = "";
			for(str tId <- typesOfArguments) {
				if (tId == "Runnable") {
					Expression argument0 = typesOfArguments[tId];
					runnableArguments = unparse(argument0);
				}
				if (tId == "String" || tId == "StringBuffer") {
					Expression argument0 = typesOfArguments[tId];
					nameArguments = unparse(argument0);
				}
			}
			ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
			ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
			replacingExpression = (ReturnStatement) `return Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>);`;
		    isReplacement = true;
		}
		if (isReplacement == true) {
			datetime transformedTime = now();
  			println("returnStatement : <replacingExpression> transformed : <transformedTime>");
			insert(replacingExpression);
		}
	}
	case (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)` : {
		StatementExpression exp = (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)`;
		datetime detectedTime = now();
  		println("statementExpr : <exp> detected : <detectedTime>");
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(exp) {
			case ArgumentList argList : argumentList += argList; 
		}
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		println("types: <types>");
		StatementExpression replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str expressionArgument = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
					replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
					isReplacement = true;
				}
			}
		}
		else if (numberOfTypes == 2) {
			if ((types[0] == "ThreadGroup" && types[1] == "Runnable") || (types[0] == "Runnable" && types[1] == "ThreadGroup")) {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str expressionArgument = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
						replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
						isReplacement = true;
						break;
					}
				}
			} else if (types[0] == "ThreadGroup" && (types[1] != "String" && types[1] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[1]];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else if (types[1] == "ThreadGroup" && (types[0] != "String" && types[0] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[0]];
				str expressionArgument = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, expressionArgument);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else if ((types[0] == "Runnable" && (types[1] == "String" || types[1] == "StringBuffer")) || ((types[0] == "String" || types[0] == "StringBuffer") && types[1] == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String" || tId == "StringBuffer") {
						Expression argument0 = typesOfArguments[tId];
						nameArguments = unparse(argument0);
					}
				}
				ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
				ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>)`;
				isReplacement = true;
			}
		} else if (numberOfTypes == 3) {
			str runnableArguments = "";
			str nameArguments = "";
			for(str tId <- typesOfArguments) {
				if (tId == "Runnable") {
					Expression argument0 = typesOfArguments[tId];
					runnableArguments = unparse(argument0);
				}
				if (tId == "String" || tId == "StringBuffer") {
					Expression argument0 = typesOfArguments[tId];
					nameArguments = unparse(argument0);
				}
			}
			ArgumentList runnableArgs = parse(#ArgumentList, runnableArguments);
			ArgumentList nameArgs = parse(#ArgumentList, nameArguments);
			replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().name(<ArgumentList nameArgs>).unstarted(<ArgumentList runnableArgs>)`;
		    isReplacement = true;
		}
		if (isReplacement == true) {
			datetime transformedTime = now();
  			println("returnStatement : <replacingExpression> transformed : <transformedTime>");
			insert(replacingExpression);
		}
	}
	case (MethodInvocation) `<ExpressionName exp>.getId()` : {
		MethodInvocation mi = (MethodInvocation) `<ExpressionName exp>.getId()`;
		MethodInvocation mi2 = (MethodInvocation) `<ExpressionName exp>.threadId()`;
		datetime detectedTime = now();
  		println("methodInvocation : <mi> detected : <detectedTime>");
		bool threadIdUseFound = false;
		top-down visit(mi) {
			case ExpressionName exp: {
				for(VariableDeclaratorId vId <- variableNameTypeMap) {
					str unparsedExp = trim(unparse(exp));
					if (startsWith(unparsedExp, "this.")) {
							unparsedExp = substring(unparsedExp, 5);
						}
					if (trim(unparse(vId)) == unparsedExp) {
						if (trim(unparse(variableNameTypeMap[vId])) == "Thread") {
							threadIdUseFound = true;
							break;
						}
					}
				}
			}
		}
		if (threadIdUseFound) {
			datetime transformedTime = now();
  			println("methodInvocation : <mi2> transformed : <transformedTime>");
			insert((MethodInvocation) `<ExpressionName exp>.threadId()`);
		}	
	}
	case (MethodInvocation) `Thread.currentThread().getId()` : { 
		datetime detectedTime = now();
  		println("methodInvocation : detected : <detectedTime>");
		datetime transformedTime = now();
  		println("methodInvocation : transformed : <transformedTime>"); 
		insert((MethodInvocation) `Thread.currentThread().threadId()`);
	}
	case MethodBody b: {
		bool isThreadFacAdded = false;
		str variableNameForThreadFac = "threadFactory";
		for(VariableDeclaratorId vId <- variableNameTypeMap) {
			if (variableNameForThreadFac == unparse(vId)) {
				variableNameForThreadFac = "threadFactory1";
			}
		}
		ArgumentList threadFactoryArgs = parse(#ArgumentList, variableNameForThreadFac);

		b = top-down visit(b) {
			case (Statement) `<LeftHandSide id> = Executors.newCachedThreadPool();`: {
				Statement ste = (Statement) `<LeftHandSide id> = Executors.newCachedThreadPool();`;
				datetime detectedTime = now();
  				println("statement : <ste> detected : <detectedTime>");
				isThreadFacAdded = true;
				Statement replacingExpression = (Statement) `<LeftHandSide id> = Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>);`;
				datetime transformedTime = now();
  				println("statement : <replacingExpression> transformed : <transformedTime>");
				insert(replacingExpression);
			}
			case (MethodInvocation) `Executors.newCachedThreadPool()`: {
				MethodInvocation detection = (MethodInvocation) `Executors.newCachedThreadPool()`;
				datetime detectedTime = now();
  				println("methodInvocation : <detection> detected : <detectedTime>");
				isThreadFacAdded = true;
				MethodInvocation replacingExpression = (MethodInvocation) `Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>)`;
				datetime transformedTime = now();
  				println("statement : <replacingExpression> transformed : <transformedTime>");
				insert(replacingExpression);
			}
			case (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`: {
				MethodInvocation methodInv =  (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`;
				list[ArgumentList] argumentList = [];
				top-down visit(methodInv) {
					case ArgumentList argList : argumentList += argList; 
				}
				int numberOfArguments = getCountOfArguments(argumentList);
				
				if (numberOfArguments == 1 ) {
					isThreadFacAdded = true;
					datetime detectedTime = now();
  					println("methodInvocation : <methodInv> detected : <detectedTime>");
					str argumentsForNewMethodInv = variableNameForThreadFac;
					ArgumentList threadFactoryArgs = parse(#ArgumentList, argumentsForNewMethodInv);
					MethodInvocation replacingExpression = (MethodInvocation) `Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>)`;
					datetime transformedTime = now();
  					println("methodInvocation : <replacingExpression> transformed : <transformedTime>");
					insert(replacingExpression);
				}
			}
		}
		VariableDeclaratorId vId = parse(#VariableDeclaratorId, variableNameForThreadFac);
		BlockStatement statementToBeAdded = (BlockStatement) `ThreadFactory <VariableDeclaratorId vId> = Thread.ofVirtual().factory();`;
		if (isThreadFacAdded) {
			isThreadFacImportNeeded = true;
			str unparsedMethodBody = unparse(b);
			unparsedMethodBody = replaceFirst(unparsedMethodBody, "{", "");
			unparsedMethodBody = replaceLastCurlyBrace(unparsedMethodBody);
			str methodBody = "{\n" + unparse(statementToBeAdded) + "\n" + insertLastCurlyBrace(unparsedMethodBody);
			MethodBody newBody = parse(#MethodBody, methodBody);
			insert(newBody);
  		}
	}
	case ConstructorBody b: {
		bool isThreadFacAdded = false;
		str variableNameForThreadFac = "threadFactory";
		variableNameTypeMap = classVariableNameTypeMap;
		for(VariableDeclaratorId vId <- variableNameTypeMap) {
			if (variableNameForThreadFac == unparse(vId)) {
				variableNameForThreadFac = "threadFactory1";
			}
		}
		ArgumentList threadFactoryArgs = parse(#ArgumentList, variableNameForThreadFac);

		b = top-down visit(b) {
			case (Statement) `<LeftHandSide id> = Executors.newCachedThreadPool();`: {
				Statement ste = (Statement) `<LeftHandSide id> = Executors.newCachedThreadPool();`;
				datetime detectedTime = now();
  				println("statement : <ste> detected : <detectedTime>");
				isThreadFacAdded = true;
				Statement replacingExpression = (Statement) `<LeftHandSide id> = Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>);`; 
				datetime transformedTime = now();
				println("statement : <replacingExpression> transformed : <transformedTime>");
				insert(replacingExpression);
			}
			case (MethodInvocation) `Executors.newCachedThreadPool()`: {
				MethodInvocation methodInvocation = (MethodInvocation) `Executors.newCachedThreadPool()`;
				datetime detectedTime = now();
  				println("methodInvo : <methodInvocation> detected : <detectedTime>");
				isThreadFacAdded = true;
				MethodInvocation replacingExpression = (MethodInvocation) `Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>)`;
				datetime transformedTime = now();
				println("methodInvo : <replacingExpression> transformed : <transformedTime>");
				insert(replacingExpression);
			}
			case (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`: {
				MethodInvocation methodInvocation = (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`;
				datetime detectedTime = now();
  				println("methodInvo : <methodInvocation> detected : <detectedTime>");
				MethodInvocation methodInv =  (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`;
				list[ArgumentList] argumentList = [];
				top-down visit(methodInv) {
					case ArgumentList argList : argumentList += argList; 
				}
				int numberOfArguments = getCountOfArguments(argumentList);
				
				if (numberOfArguments == 1 ) {
					isThreadFacAdded = true;
					str argumentsForNewMethodInv = variableNameForThreadFac;
					ArgumentList threadFactoryArgs = parse(#ArgumentList, argumentsForNewMethodInv);
					MethodInvocation replacingExpression = (MethodInvocation) `Executors.newThreadPerTaskExecutor(<ArgumentList threadFactoryArgs>)`;
					datetime transformedTime = now();
					println("methodInvo : <replacingExpression> transformed : <transformedTime>");
					insert(replacingExpression);
				}
			}
		}
		VariableDeclaratorId vId = parse(#VariableDeclaratorId, variableNameForThreadFac);
		BlockStatement statementToBeAdded = (BlockStatement) `ThreadFactory <VariableDeclaratorId vId> = Thread.ofVirtual().factory();`;
		if (isThreadFacAdded) {
			isThreadFacImportNeeded = true;
			str unparsedMethodBody = unparse(b);
			unparsedMethodBody = replaceFirst(unparsedMethodBody, "{", "");
			unparsedMethodBody = replaceLastCurlyBrace(unparsedMethodBody);
			str methodBody = "{\n" + unparse(statementToBeAdded) + "\n" + insertLastCurlyBrace(unparsedMethodBody);
			ConstructorBody newBody = parse(#ConstructorBody, methodBody);
			insert(newBody);
  		}
	}
  }
  return unit;
}

/* This method goes through the imports and if it has not imported ThreadFactory, we modify the
*  the imports by adding the specific import statement and then parse all the imports string back to 
* Imports type.
*/
private CompilationUnit updateImports(CompilationUnit unit) {
	unit = top-down visit(unit) {
		case Imports imports : {
			imports = top-down visit(imports) {
				case (ImportDeclaration) `import java.util.concurrent.ThreadFactory;`: {
					return unit;
				}
			}
			str importString = unparse(imports);
			if (importString == "") {
				importString = "import java.util.concurrent.ThreadFactory;";
			} else {
				importString += ("\n" + "import java.util.concurrent.ThreadFactory;");
			}
			insert parse(#Imports, importString);
		}
	}
	return unit;
}


public void extractInstanceVariables(CompilationUnit unit) {
	map[str, str] varNameAndType = ( );
	top-down visit(unit) {
		case ConstructorBody b: {	
			b = top-down visit(b) {
				case BlockStatements bs: {
					bs = top-down visit(bs) {
						case (StatementExpression) `<LeftHandSide id> = <ClassInstanceCreationExpression c>`: {
							StatementExpression exp = (StatementExpression) `<LeftHandSide id> = <ClassInstanceCreationExpression c>`;
							println("ClassInstanceCreationExpression: <exp>");
							vId = "";
							vType = "";
							exp = top-down visit(exp) {
								case LeftHandSide id: {
									vId = trim(unparse(id));
									if (startsWith(vId, "this.")) {
										vId = substring(vId, 5);
									}
								}
								case ClassOrInterfaceTypeToInstantiate c: {
									vType = trim(unparse(c));
								}
							}
							varNameAndType+=(vId: vType);
						}
					}
				}
			}
			consThisTypeMap = varNameAndType;
		}
	}
}

/* The following method extracts types of arguments */
public map[str, Expression] getTypesOfArguments(list[ArgumentList] argumentList) {
	map[str, Expression] typesOfArguments = ( );
	//loop through each argument
	for(ArgumentList argList <- argumentList) {
			top-down visit(argList) {
				case Expression e : {
					str unparsedExp = unparse(e);
					// the parameter which controls if the type of the argument is found
					bool isTypeFound = false;
					// if the argument is a concatenation with any other variable
					if (contains(unparsedExp, "+")) {
						list[str] args = split("+", unparsedExp);
						for (str arg01 <- args) {
							unparsedExp = trim(arg01);
							// if there is a string as an argument
							if(startsWith(unparsedExp,"\"") && endsWith(unparsedExp, "\"") && (isTypeFound == false)) {
								typesOfArguments += ("String" : e); 
								isTypeFound = true;
							}
							if (isTypeFound == false) {
								// loop through previously extracted variable map
								for(VariableDeclaratorId vId <- variableNameTypeMap) {
									str variableId = trim(unparse(vId));
									// check if the variable starts with this.
									if (startsWith(unparsedExp, "this.")) {
										unparsedExp = substring(unparsedExp, 5);
									}
									if (startsWith(variableId, "this.")) {
										variableId = substring(variableId, 5);
									}
									if (endsWith(unparsedExp, ".toString()") && (isTypeFound == false)) {
										typesOfArguments += ("String" : e); 
										isTypeFound = true;
									}
									if (variableId == trim(unparsedExp) && (isTypeFound == false)) {
										isTypeFound = true;
										typesOfArguments += (trim(unparse(variableNameTypeMap[vId])): e);
									}
								}
								if (isTypeFound == false) {
									// loop through previously extracted class variables
									for(VariableDeclaratorId vId <- classVariableNameTypeMap) {
										print("VariableDeclaratorId: <vId>");
										str variableId = trim(unparse(vId));
										if (startsWith(unparsedExp, "this.")) {
											unparsedExp = substring(unparsedExp, 5);
										}
										if (startsWith(variableId, "this.")) {
											variableId = substring(variableId, 5);
										}
										if (endsWith(unparsedExp, ".toString()")) {
											typesOfArguments += ("String" : e); 
											isTypeFound = true;
										}
										if (variableId == trim(unparsedExp) && (isTypeFound == false)) {
											isTypeFound = true;
											typesOfArguments += (trim(unparse(classVariableNameTypeMap[vId])): e);
										}
									}
								}
								// check if they are in generic types
								if (isTypeFound == false) {
									top-down visit(e) {
										case IntegerLiteral i : { 
											if(equalUnparsed(e, i)) {
												typesOfArguments += ("int" : e); 
												isTypeFound = true;
											}
										}
										case StringLiteral s : { 
											if(equalUnparsed(e, s)) {
												typesOfArguments += ("String" : e); 
												isTypeFound = true;
											} 
										}
										case BooleanLiteral b : { 
											if(equalUnparsed(e, b)) {
												typesOfArguments += ("boolean" : e);
												isTypeFound = true;
											} 
										}
									}
								}
								if (isTypeFound == false) {
									// the argument can contain a method call as well.
									if (endsWith(unparsedExp, "()") || endsWith(unparsedExp, ")")) {
										indexVal = findFirst(unparsedExp, "(");
										// extract the method name
										variableNameExt = substring(unparsedExp, 0, indexVal);
										// loop through method type map to identify the return type of that method
										for (str methodName <- methodTypeMap) {
											print("methodTypeMap: <methodName> : <methodTypeMap[methodName]>: <variableNameExt>");
											if (trim(methodName) == trim(variableNameExt)) {
												isTypeFound = true;
												typesOfArguments += (trim(unparse(methodTypeMap[methodName])): e);
											}
										}
									}
								}
								if (isTypeFound == false) {
									typesOfArguments += ("String" : e); 
									isTypeFound = true;
								}
							} 
						}
					} else {
						// sometimes there are arguments as "this", then we need to see interfaces of the class
						if (trim(unparsedExp) == "this") {
							top-down visit(compilationUnit) {
								case NormalClassDeclaration classDec: {
									top-down visit(classDec) {
										case Superinterfaces su: {
											top-down visit(su) {
												case InterfaceType interfaceType: {
													if (trim(unparse(interfaceType)) == "Runnable") {
														typesOfArguments += ("Runnable" : e); 
														isTypeFound = true;
													}
												}
											}
										} 
									} 
								}
							}	
						} else {
							for(str vId <- consThisTypeMap) {
								str variableId = trim(unparse(vId));
								if (startsWith(unparsedExp, "this.")) {
									unparsedExp = substring(unparsedExp, 5);
								}
								if (startsWith(variableId, "this.")) {
									variableId = substring(variableId, 5);
								}
								if (endsWith(unparsedExp, ".toString()")) {
									typesOfArguments += ("String" : e); 
									isTypeFound = true;
								}
								if (variableId == trim(unparsedExp) && (isTypeFound == false)) {
									isTypeFound = true;
									typesOfArguments += (trim(unparse(consThisTypeMap[vId])): e);
								}
							}
							if (isTypeFound == false) {
								for(VariableDeclaratorId vId <- variableNameTypeMap) {
									str variableId = trim(unparse(vId));
									if (startsWith(unparsedExp, "this.")) {
										unparsedExp = substring(unparsedExp, 5);
									}
									if (startsWith(variableId, "this.")) {
										variableId = substring(variableId, 5);
									}
									if (endsWith(unparsedExp, ".toString()")) {
										typesOfArguments += ("String" : e); 
										isTypeFound = true;
									}
									if (variableId == trim(unparsedExp) && (isTypeFound == false)) {
										isTypeFound = true;
										typesOfArguments += (trim(unparse(variableNameTypeMap[vId])): e);
									}
								}
							}
							if (isTypeFound == false) {
								for(VariableDeclaratorId vId <- classVariableNameTypeMap) {
									str variableId = trim(unparse(vId));
									if (startsWith(unparsedExp, "this.")) {
										unparsedExp = substring(unparsedExp, 5);
									}
									if (startsWith(variableId, "this.")) {
										variableId = substring(variableId, 5);
									}
									if (endsWith(unparsedExp, ".toString()")) {
										typesOfArguments += ("String" : e); 
										isTypeFound = true;
									}
									if (variableId == trim(unparsedExp) && (isTypeFound == false)) {
										isTypeFound = true;
										typesOfArguments += (trim(unparse(classVariableNameTypeMap[vId])): e);
									}
								}
							}
							if (isTypeFound == false) {
								top-down visit(e) {
									case IntegerLiteral i : { 
										if(equalUnparsed(e, i)) {
											typesOfArguments += ("int" : e); 
											isTypeFound = true;
										}
									}
									case StringLiteral s : { 
										if(equalUnparsed(e, s)) {
											typesOfArguments += ("String" : e); 
											isTypeFound = true;
										} 
									}
									case BooleanLiteral b : { 
										if(equalUnparsed(e, b)) {
											typesOfArguments += ("boolean" : e);
											isTypeFound = true;
										} 
									}
								}
							}
							if (isTypeFound == false) {
								if (endsWith(unparsedExp, "()") || endsWith(unparsedExp, ")")) {
									indexVal = findFirst(unparsedExp, "(");
									variableNameExt = substring(unparsedExp, 0, indexVal);
									for (str methodName <- methodTypeMap) {
										print("methodTypeMap: <methodName> : <methodTypeMap[methodName]>: <variableNameExt>");
										if (trim(methodName) == trim(variableNameExt)) {
											isTypeFound = true;
											typesOfArguments += (trim(unparse(methodTypeMap[methodName])): e);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		return typesOfArguments;
}

/* this method is used to get number of arguments */
public int getCountOfArguments(list[ArgumentList] argumentList) {
	int count = 0;
	for(ArgumentList argList <- argumentList) {
			top-down visit(argList) {
				case Expression e : {
					count += 1;
				}
			}
		}
	return count;
}

/* this method is used to evaluate the equality of two variables */
private bool equalUnparsed(&A argument, &B literal) {
  return unparse(argument) == unparse(literal);
}

private str replaceLastCurlyBrace(str methodBody) {
	list[str] lines = split("\n", methodBody);
	bool isComment = false;
	bool commentStarted = false;
	str newMethodBody = "";
	list[str] reversedLines = [];
	bool isReplaced = false;
	for(str line <- reverse(lines)) {
		if (startsWith(trim(line), "\\")) {
			isComment = true;
		} else if (endsWith(trim(line), "*/")) {
			isComment = true;
			commentStarted = true;
		} else if (startsWith(trim(line), "/*") || startsWith(trim(line), "/**")) {
			isComment = true;
			commentStarted = false;
		} else if (startsWith(trim(line), "*") && commentStarted) {
			isComment = true;
		} else if (contains(line, "}") && !isReplaced) {
			line = replaceLast(line, "}", "");
			isReplaced = true;
		}
		reversedLines += line;
	}
	for (str line <- reverse(reversedLines)) {
		newMethodBody += (line + "\n");
	}
	return newMethodBody;
}

/* This method is used to add the last curly brace at the end of the method body section and if there
* are comments in the beginning of the next method, rascal confuses in extracting method body and hence
* it includes those comments as well. So, here we go through the method body in the reverse order and 
* if it is a comment, we ignore those lines and put the final curly brace appropriately.
*/
private str insertLastCurlyBrace(str methodBody) {
	list[str] lines = split("\n", methodBody);
	bool isComment = false;
	bool commentStarted = false;
	str newMethodBody = "";
	list[str] reversedLines = [];
	bool isReplaced = false;
	for(str line <- reverse(lines)) {
		if (startsWith(trim(line), "\\")) {
			isComment = true;
		} else if (endsWith(trim(line), "*/")) {
			isComment = true;
			commentStarted = true;
		} else if (startsWith(trim(line), "/*") || startsWith(trim(line), "/**")) {
			isComment = true;
			commentStarted = false;
		} else if (startsWith(trim(line), "*") && commentStarted) {
			isComment = true;
		} else if (!isReplaced && trim(line) != "") {
			line += "}";
			isReplaced = true;
		}
		reversedLines += line;
	}
	for (str line <- reverse(reversedLines)) {
		newMethodBody += (line + "\n");
	}
	return newMethodBody;
}


/* The following method is used when the type of argument/variable is not obvious, which is a class
* of defined and the class itself inherits or implements an obvious known class.
* If the class is directly inherited or implemented some known class, we use it as the type of the argument,
* else, we go to parent class and see if it has implemented some known interface by repetitively
* calling to the same method 5 times. 
*/
public str findTypeOfArg(CompilationUnit unit, str argName, loc file, str typeOfArgument) {
	bool isSubClassPresentInFile = false;
	bool isSubClassPresentInPackage = false;
	bool isImportedType = false;
	str typeOfArg = typeOfArgument;
	int count = 0;
	while ( typeOfArg == "" ) {
			top-down visit(unit) {
				case NormalClassDeclaration classDec: {
					int count = 0;
					if (typeOfArg == "") {
						top-down visit(classDec) {
							case Identifier id: {
								if (trim(unparse(id)) == trim(argName) && count == 0) {
									isSubClassPresentInFile = true;
								}
								count+=1;
							}
							case Superinterfaces su: {
								if (isSubClassPresentInFile && typeOfArg == "") {
									top-down visit(su) {
										case InterfaceType interfaceType: {
											if (trim(unparse(interfaceType)) == "Runnable") {
												typeOfArg = "Runnable";
											}
										}
									}
								}
							}
							case Superclass su: {
								if (isSubClassPresentInFile && typeOfArg == "") {
									top-down visit(su) {
										case ClassType classType: {
											if (typeOfArg == "") {
												argName = unparse(classType);
												isSubClassPresentInFile = false;
											}
										}
									}
								} 
									
							}
						} 
					} 
				}
			}
			

			if (!isSubClassPresentInFile && typeOfArg == "") {
				isSubClassPresentInPackage  = true;
				
				str originalFilePath = file.path[1..];
				str replacingFileName = file.file;
				str replacementFile = trim(argName) + ".java";
				str modifiedPath = replaceLast(originalFilePath, replacingFileName, replacementFile);
				loc subClassLocation = |file:///| + modifiedPath;
				str content = readFile(subClassLocation);
				CompilationUnit unit2 = parse(#CompilationUnit, content);
				unit = unit2;
				file = subClassLocation;
			}
			count += 1;
			if (count == 5) {
				break;
			}
	}
	
	return typeOfArg;
}
    


// assumed Class types can be found within the package
// unparseable files to compilationUnits, ignored