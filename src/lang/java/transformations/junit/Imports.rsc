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
list[BlockStatement] refactoredStatements = [];

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
	unit = extractMethodsAndPatterns(unit);
	return unit;
}

public CompilationUnit extractMethodsAndPatterns(CompilationUnit unit) {
  unit = top-down visit(unit) {
	case MethodDeclaration b : {
		refactoredStatements = [];
		variableNameTypeMap = ( );
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
	}
	case (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)` : {
		StatementExpression exp = (StatementExpression) `<LeftHandSide id> = new Thread(<ArgumentList args>)`;
	
		map[str, Expression] typesOfArguments = ( );

		list[ArgumentList] argumentList = [];
		top-down visit(exp) {
			case ArgumentList argList : argumentList += argList; 
		}
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
						println("type not Found: <e>");
					}
				}
			}
		}
		int numberOfArguments = size(typesOfArguments);
		list[str] types = toList(typesOfArguments<0>);
		int numberOfTypes = size(types);
		StatementExpression replacingExpression;
		if (numberOfTypes == 2) {
			if (types[0] == "ThreadGroup" && types[1] == "Runnable") {
				for(str tId <- typesOfArguments) {
					if (tId == "Runnable") {
						Expression argument0 = typesOfArguments[tId];
						str assertAllInvocationArguments = unparse(argument0);
						ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
						replacingExpression = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().unstarted(<ArgumentList lambdas>)`;
						println("replacingExpression : <replacingExpression>");
						break;
					}
				}
	
			}
		}
		insert(replacingExpression);
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
			// case (MethodInvocation) `Executors.newFixedThreadPool(<ArgumentList args>)`: {
			// 	isThreadFacAdded = true;
			// 	insert((MethodInvocation) `Executors.newCachedThreadPool(threadFactory)`);
			// }
			case (MethodInvocation) `Thread.currentThread().getId()` => (MethodInvocation) `Thread.currentThread().threadId()` 
		}
		BlockStatement statementToBeAdded = (BlockStatement) `ThreadFactory threadFactory = Thread.ofVirtual().factory();`;
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

