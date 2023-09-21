module lang::java::transformations::junit::Imports
import IO;
import ParseTree;
import util::Maybe;
import util::MaybeManipulation;
import lang::java::\syntax::Java18;
data Argument = argument(str argType, Expression expression);

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
	unit = extractMethodBody(unit);
	Expression exp = (Expression) `Thread.ofVirtual().factory()`;
	Identifier th = parse(#Identifier, "threadFactory");
	LeftHandSide id = (LeftHandSide) `<Identifier th>`;
    StatementExpression exp2 = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().factory()`;
    ReturnStatement expression = (ReturnStatement) `return Executors.newCachedThreadPool();`;
	MethodInvocation mi = (MethodInvocation) `Executors.newCachedThreadPool()`;	
	return unit;
}

public CompilationUnit extractMethodBody(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodBody b => extractBlockStmts(b)
  }
  return unit;
}

public MethodBody extractBlockStmts(MethodBody methodBody) {
	methodBody = extractArgumentsInMethodBody(methodBody);
	methodBody = top-down visit(methodBody) {
		case BlockStatement s => isStatementAGeneralStatement(s)
		// case (StatementExpression) `<LeftHandSide id> = <Expression exp>`=> exp2
    }
	return methodBody;
}

public BlockStatement isStatementAGeneralStatement(BlockStatement statement) {
  println("BlockStatement: <statement>");  
  statement = top-down visit(statement) {
	case Statement s => isStatementWithoutTrailingSubstatement(s, statement)
    case LocalVariableDeclarationStatement s : {println("ClassDeclaration1: <s>");
	isLocalVariableDeclarationStatement(s, statement);
	}
    case ClassDeclaration s => isClassDeclarationStatement(s, statement)
  }
  return statement;
}

public LocalVariableDeclarationStatement isLocalVariableDeclarationStatement(LocalVariableDeclarationStatement statement, BlockStatement bstmt) {
  println("isLocalVariableDeclarationStatement: <statement>");  
  statement = top-down visit(statement) {
    case LocalVariableDeclaration s : { println("LocalVariableDeclaration : <s>"); isLocalVariableDeclaration(s, bstmt);}
  }
  return statement;
}

public LocalVariableDeclaration isLocalVariableDeclaration(LocalVariableDeclaration statement, BlockStatement bstmt) {
  println("isLocalVariableDeclaration: <statement>");  
  statement = top-down visit(statement) {
    case VariableModifier s : println("VariableModifier : <s>");
	case VariableDeclarator s: println("VariableDeclarator : <s>");
	case UnannType s: println("UnannType : <s>");
	case VariableDeclaratorId s: println("VariableDeclaratorId : <s>");
	case VariableInitializer s: println("VariableInitializer : <s>");
  }
  return statement;
}

public ClassDeclaration isClassDeclarationStatement(ClassDeclaration statement, BlockStatement bstmt) {
  println("isClassDeclarationStatement: <statement>");  
  statement = top-down visit(statement) {
    case NormalClassDeclaration s : println("NormalClassDeclaration : <s>");
  }
  return statement;
}

public Statement isStatementWithoutTrailingSubstatement(Statement statement, BlockStatement bstmt) {
  println("isStatementWithoutTrailingSubstatement: <statement>");  
  statement = top-down visit(statement) {
    case StatementWithoutTrailingSubstatement s => isExpressionStatement(s)
  }
  return statement;
}

public StatementWithoutTrailingSubstatement isExpressionStatement(StatementWithoutTrailingSubstatement statement) {
  println("isExpressionStatement: <statement>");  
  statement = top-down visit(statement) {
    case ExpressionStatement s => isStatementExpression(s)
  }
  return statement;
}

public ExpressionStatement isStatementExpression(ExpressionStatement statement) {
	println("isStatementExpression: <statement>");  
	statement = top-down visit(statement) {
      case StatementExpression s => verifyStatementExpression(s)
  	}
  	return statement;
}

public StatementExpression verifyStatementExpression(StatementExpression statement) {
	println("verifyStatementExpression: <statement>");  
	statement = top-down visit(statement) {
    	case MethodInvocation s => isMethodInvocation(s) 
		case Assignment s => isAssignment(s)
		case ClassInstanceCreationExpression s : { return isClassInstanceCreationExpression(s, statement); }
	}
	println("Number of files: <statement>");  
	return statement;
}

public Assignment isAssignment(Assignment statement) {
	println("isAssignment: <statement>");  
  	statement = top-down visit(statement) {
			case LeftHandSide lhs : {
				println("lhs: <lhs>");
			}
			case Expression exp: {
				println("Expression: <typeOf(exp)>");
			}
	}
	return statement;
}

public MethodInvocation isMethodInvocation(MethodInvocation statement) {
  println("isMethodInvocation: <statement>");  
  statement = top-down visit(statement) {
    case (MethodInvocation) `Executors.newCachedThreadPool()` : {
      return (MethodInvocation) `Executors.newFixedThreadPool()`;
    }
    case (MethodInvocation) `Assert.<Identifier methodName>(<ArgumentList _>)` : {
      return methodName in assertionMethods();
    }
    // case (MethodInvocation) `<MethodName methodName>(<ArgumentList _>)` : {
    //   return parse(#Identifier, unparse(methodName)) in assertionMethods();
    // } 
  }
  return statement;
}

public StatementExpression isClassInstanceCreationExpression(ClassInstanceCreationExpression statement, StatementExpression ste) {
  println("isClassInstanceCreationExpression: <statement>");  
  bool isThreadCreation = false;
  statement = top-down visit(statement) {
    case (ClassInstanceCreationExpression) `new Thread(<ArgumentList args>)` : {isThreadCreation = true;}
  }
  if (isThreadCreation) {
	LeftHandSide variable = getLHSVariableOfExpression(ste);
	Expression expression;
	ste = top-down visit(ste) {
    	case (ClassInstanceCreationExpression) `new Thread(<ArgumentList args>)` : {
			println("ste : <ste>");
			expression = (Expression) `Thread.ofVirtual().unstarted(<ArgumentList args>)`;
		}
  	}
	ste = (StatementExpression) `<LeftHandSide variable> = <Expression expression>`;
	println("modified ste : <ste>");
  }
  return ste;
}

public LeftHandSide getLHSVariableOfExpression(StatementExpression statement) {
	LeftHandSide lhs;
	top-down-break visit(statement) {
		case Assignment s: {
			top-down visit(s) {
				case LeftHandSide lhs : {
					println("lhs: <lhs>");
					return lhs;
				}
				case Expression exp: {
					println("Expression : exp");
					println("Expression type: <typeOf(exp)>");
					return lhs;
				}
			}
		}
	}
	return lhs;
} 





private Maybe[list[ArgumentList]] extractArguments(MethodBody body) {
  list[ArgumentList] args = [];
  top-down visit(body) {
    case MethodInvocation m : top-down visit(m) {
      case ArgumentList argList : args += argList;
    }
  }
  if(isEmpty(args)) return nothing();
  return just(args);
}

private Maybe[list[list[Argument]]] extractArguments(list[ArgumentList] args) {
  if(isEmpty(args)) return nothing();

  list[list[Argument]] invocationArgs = [];
  for(ArgumentList argList <- args) {
    list[Argument] argsListArguments = [];

    top-down-break visit(argList) {
      case Expression e : {
        switch(extractArgumentType(e)) {
          case just(t) : argsListArguments += argument(t, e);
          case nothing() : return nothing();
        }
      }
    }

    if(!isEmpty(invocationArgs)) {
      if(size(head(invocationArgs)) != size(argsListArguments) || isEmpty(argsListArguments)) {
        return nothing();
      }
    }

    invocationArgs += [argsListArguments];
  }

  return just(invocationArgs);
}

private Maybe[str] extractArgumentType(Expression ex) {
  top-down-break visit(ex) {
    case IntegerLiteral i : if(equalUnparsed(ex, i)) return just("int");
    case StringLiteral s : if(equalUnparsed(ex, s)) return just("String");
    case BooleanLiteral b : if(equalUnparsed(ex, b)) return just("boolean");
  }

  return nothing();
}

private bool equalUnparsed(&A argument, &B literal) {
  return unparse(argument) == unparse(literal);
}

private MethodBody extractArgumentsInMethodBody(MethodBody methodBody) {
	Maybe[list[ArgumentList]] ls = extractArguments(methodBody);
	// println("arguments: <ls>");
	list[ArgumentList] args = [];

	switch(ls) {
		case just(argList): args = argList;
		case nothing(): return methodBody;
	}
	// println("arguments List: <args>");

	list[list[Argument]] invocationArgs = [];
	switch(extractArguments(args)) {
		case just(arguments): invocationArgs = arguments;
		case nothing(): return methodBody;
	}
	// println("invocationArgs List: <invocationArgs>");

	list[FormalParameter] methodParams = [];
	str assertionArgs = "";
	int i = 0;
	for(Argument arg <- head(invocationArgs)) {
		str argName = "arg<i>";
		methodParams += parse(#FormalParameter, "<arg.argType> <argName>");
		assertionArgs += "<argName>, ";
		i += 1;
	}

	// println("Method params List: <methodParams>");
	// println("assertionArgs List: <assertionArgs>");
	return methodBody;
}