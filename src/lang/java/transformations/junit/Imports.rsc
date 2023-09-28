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

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
	unit = extractMethodsAndPatterns(unit);
	return unit;
}

public CompilationUnit extractMethodsAndPatterns(CompilationUnit unit) {
  MethodDeclaration previousMethodDeclaration; 
  int count = 0;
  unit = top-down visit(unit) {
	case MethodDeclaration b : {
		count += 1;
		if (count > 1 && contains(unparse(previousMethodDeclaration), unparse(b))) {
			println("inner method found");
		} else {
			variableNameTypeMap = ( );
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
		// println("blockstatement: found, numberOfArguments: <numberOfTypes>");
		BlockStatement replacingExpression;
		bool isReplacement = false;
		if (numberOfTypes == 1) {
			if (types[0] == "Runnable") {
				Expression argument0 = typesOfArguments["Runnable"];
				str assertAllInvocationArguments = unparse(argument0);
				ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
				replacingExpression = (BlockStatement) `Thread <VariableDeclaratorId id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>);`;
				isReplacement = true;
			}
		}
		else if (numberOfTypes == 2) {
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
			case (MethodInvocation) `Thread.currentThread().getId()` => (MethodInvocation) `Thread.currentThread().threadId()` 
		}
		VariableDeclaratorId vId = parse(#VariableDeclaratorId, variableNameForThreadFac);
		BlockStatement statementToBeAdded = (BlockStatement) `ThreadFactory <VariableDeclaratorId vId> = Thread.ofVirtual().factory();`;
		if (isThreadFacAdded) {
			str unparsedMethodBody = unparse(b);
			unparsedMethodBody = replaceFirst(unparsedMethodBody, "{", "");
			unparsedMethodBody = replaceLast(unparsedMethodBody, "}", "");
			str methodBody = "{\n" + unparse(statementToBeAdded) + "\n" + unparsedMethodBody +  "}";
			MethodBody newBody = parse(#MethodBody, methodBody);
			insert(newBody);
  		}
	}
  }
  return unit;
}

public map[str, Expression] getTypesOfArguments(list[ArgumentList] argumentList) {
	map[str, Expression] typesOfArguments = ( );
	for(ArgumentList argList <- argumentList) {
			top-down visit(argList) {
				case Expression e : {
					bool isTypeFound = false;
					for(VariableDeclaratorId vId <- variableNameTypeMap) {
						if (trim(unparse(vId)) == trim(unparse(e))) {
							isTypeFound = true;
							typesOfArguments += (trim(unparse(variableNameTypeMap[vId])): e);
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
