module lang::java::transformations::junit::Imports
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

data Argument = argument(str argType, Expression expression);
map[VariableDeclaratorId, UnannType] variableNameTypeMap = ( );
map[VariableDeclaratorId, UnannType] classVariableNameTypeMap = ( );

public CompilationUnit executeImportsTransformation(CompilationUnit unit, loc file) {
	classVariableNameTypeMap = ( );
	variableNameTypeMap = ( );
	unit = extractMethodsAndPatterns(unit, file);
	return unit;
}

public CompilationUnit extractMethodsAndPatterns(CompilationUnit unit, loc file) {
  MethodDeclaration previousMethodDeclaration; 
  int count = 0;
  unit = top-down visit(unit) {
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
	case MethodDeclaration b : {
		count += 1;
		if (count > 1 && contains(unparse(previousMethodDeclaration), unparse(b))) {
			println("inner method found");
		} else {
			variableNameTypeMap = classVariableNameTypeMap;
		}
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
								variableNameTypeMap += (name : vType);
							}
						}
					}
				}
			}
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
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(blockstatementExp) {
			case ArgumentList argList : argumentList += argList; 
		}
		
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		BlockStatement replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal2: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str assertAllInvocationArguments = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
					replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
					isReplacement = true;
				}
			}
		} else if (numberOfTypes == 2) {
			if ((types[0] == "ThreadGroup" && types[1] == "Runnable") || (types[0] == "Runnable" && types[1] == "ThreadGroup")) {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str assertAllInvocationArguments = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
						replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
						isReplacement = true;
						break;
					}
				}
			} else if (types[0] == "ThreadGroup" && (types[1] != "String" && types[1] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[1]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if (types[1] == "ThreadGroup" && (types[0] != "String" && types[0] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[0]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if ((types[0] == "Runnable" && types[1] == "String") || (types[0] == "String" && types[1] == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String") {
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
				if (tId == "String") {
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
			insert(replacingExpression);
		}
	}
	case (ReturnStatement) `return new Thread(<ArgumentList args>);` : {
		ReturnStatement returnSte = (ReturnStatement) `return new Thread(<ArgumentList args>);`;
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(returnSte) {
			case ArgumentList argList : argumentList += argList; 
		}
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		ReturnStatement replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal1: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str assertAllInvocationArguments = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
					replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
					isReplacement = true;
				}
			}
		}
		else if (numberOfTypes == 2) {
			if ((types[0] == "ThreadGroup" && types[1] == "Runnable") || (types[0] == "Runnable" && types[1] == "ThreadGroup")) {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str assertAllInvocationArguments = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
						replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
						isReplacement = true;
						break;
					}
				}
			} else if (types[0] == "ThreadGroup" && (types[1] != "String" && types[1] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[1]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if (types[1] == "ThreadGroup" && (types[0] != "String" && types[0] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[0]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (ReturnStatement) `return Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			} else if ((types[0] == "Runnable" && types[1] == "String") || (types[0] == "String" && types[1] == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String") {
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
				if (tId == "String") {
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
			insert(replacingExpression);
		}
	}
	case (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)` : {
		StatementExpression exp = (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)`;
	
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(exp) {
			case ArgumentList argList : argumentList += argList; 
		}
		typesOfArguments = getTypesOfArguments(argumentList);
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		StatementExpression replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else {
				str typeOfArg = findTypeOfArg(unit, types[0], file, "");
				println("typeOfArgFinal: <typeOfArg>");
				if (typeOfArg == "Runnable") {
					Expression argument0 = typesOfArguments[types[0]];
					str assertAllInvocationArguments = unparse(argument0);
					ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
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
						str assertAllInvocationArguments = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
						replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
						isReplacement = true;
						break;
					}
				}
			} else if (types[0] == "ThreadGroup" && (types[1] != "String" && types[1] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[1]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else if (types[1] == "ThreadGroup" && (types[0] != "String" && types[0] != "Runnable")) {
				Expression argument0 = typesOfArguments[types[0]];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
				isReplacement = true;
			} else if ((types[0] == "Runnable" && types[1] == "String") || (types[0] == "String" && types[1] == "Runnable")) {
				str runnableArguments = "";
				str nameArguments = "";
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						runnableArguments = unparse(argument0);
					}
					if (tId == "String") {
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
				if (tId == "String") {
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
			insert(replacingExpression);
		}
	}
	case (MethodInvocation) `<ExpressionName exp>.getId()` : {
		MethodInvocation mi = (MethodInvocation) `<ExpressionName exp>.getId()`;
		MethodInvocation mi2 = (MethodInvocation) `<ExpressionName exp>.threadId()`;
		bool threadIdUseFound = false;
		top-down visit(mi) {
			case ExpressionName exp: {
				for(VariableDeclaratorId vId <- variableNameTypeMap) {
					if (trim(unparse(vId)) == trim(unparse(exp))) {
						if (trim(unparse(variableNameTypeMap[vId])) == "Thread") {
							threadIdUseFound = true;
							break;
						}
					}
				}
			}
		}
		if (threadIdUseFound) {
			insert((MethodInvocation) `<ExpressionName exp>.threadId()`);
		}	
	}
	case (MethodInvocation) `Thread.currentThread().getId()` => (MethodInvocation) `Thread.currentThread().threadId()` 
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
				isThreadFacAdded = true;
				insert((Statement) `<LeftHandSide id> = Executors.newCachedThreadPool(<ArgumentList threadFactoryArgs>);`);
			}
			case (MethodInvocation) `Executors.newCachedThreadPool()`: {
				isThreadFacAdded = true;
				insert((MethodInvocation) `Executors.newCachedThreadPool(<ArgumentList threadFactoryArgs>)`);
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
					str argumentsForNewMethodInv = unparse(args) + "," + variableNameForThreadFac;
					ArgumentList threadFactoryArgs = parse(#ArgumentList, argumentsForNewMethodInv);
					insert((MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList threadFactoryArgs>)`);
				}
			}
		}
		VariableDeclaratorId vId = parse(#VariableDeclaratorId, variableNameForThreadFac);
		BlockStatement statementToBeAdded = (BlockStatement) `ThreadFactory <VariableDeclaratorId vId> = Thread.ofVirtual().factory();`;
		if (isThreadFacAdded) {
			str unparsedMethodBody = unparse(b);
			unparsedMethodBody = replaceFirst(unparsedMethodBody, "{", "");
			unparsedMethodBody = replaceLastCurlyBrace(unparsedMethodBody);
			str methodBody = "{\n" + unparse(statementToBeAdded) + "\n" + insertLastCurlyBrace(unparsedMethodBody);
			MethodBody newBody = parse(#MethodBody, methodBody);
			insert(newBody);
  		}
	}
	case Imports imports => updateImports(imports)
  }
  return unit;
}

private Imports updateImports(Imports imports) {
	imports = top-down visit(imports) {
		case (ImportDeclaration) `import java.util.concurrent.ThreadFactory;`: {
			return parse(#Imports, unparse(imports));
		}
	}
	str importString = unparse(imports);
	if (importString == "") {
		importString = "import java.util.concurrent.ThreadFactory;";
	} else {
		importString += ("\n" + "import java.util.concurrent.ThreadFactory;");
	}
	return parse(#Imports, importString);
}

public map[str, Expression] getTypesOfArguments(list[ArgumentList] argumentList) {
	map[str, Expression] typesOfArguments = ( );
	for(ArgumentList argList <- argumentList) {
			top-down visit(argList) {
				case Expression e : {
					bool isTypeFound = false;
					for(VariableDeclaratorId vId <- variableNameTypeMap) {
						str unparsedExp = unparse(e);
						str variableId = trim(unparse(vId));
						if (startsWith(unparsedExp, "this.")) {
							unparsedExp = substring(unparsedExp, 5);
						}
						if (startsWith(variableId, "this.")) {
							variableId = substring(variableId, 5);
						}
						if (variableId == trim(unparsedExp)) {
							isTypeFound = true;
							typesOfArguments += (trim(unparse(variableNameTypeMap[vId])): e);
						}
					}
					if (isTypeFound == false) {
						for(VariableDeclaratorId vId <- classVariableNameTypeMap) {
							str unparsedExp = unparse(e);
							str variableId = trim(unparse(vId));
							if (startsWith(unparsedExp, "this.")) {
								unparsedExp = substring(unparsedExp, 5);
							}
							if (startsWith(variableId, "this.")) {
								variableId = substring(variableId, 5);
							}
							if (variableId == trim(unparsedExp)) {
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
				}
			}
		}
		return typesOfArguments;
}

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



public str findTypeOfArg(CompilationUnit unit, str argName, loc file, str typeOfArgument) {
	bool isSubClassPresentInFile = false;
	bool isSubClassPresentInPackage = false;
	bool isImportedType = false;
	str typeOfArg = typeOfArgument;
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
	}
	
	return typeOfArg;
} 


//todo:optimize imports and format code
// assumed Class types can be found within the package