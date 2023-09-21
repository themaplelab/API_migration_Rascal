module lang::java::transformations::junit::Imports
import IO;
import ParseTree;
import lang::java::\syntax::Java18;

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
	// Maybe[list[ArgumentList]] ls = extractAssertionsArguments(methodBody);
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
    case LocalVariableDeclarationStatement _ : println("ClassDeclaration1: <statement>");
    case ClassDeclaration s :   println("ClassDeclaration: <statement>"); 
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
				println("Expression: <exp>");
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
	str variable = getLHSVariableOfExpression(ste);
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

public str getLHSVariableOfExpression(StatementExpression statement) {
	top-down-break visit(statement) {
		case Assignment s: {
			top-down visit(s) {
				case LeftHandSide lhs : {
					println("lhs: <lhs>");
					return lhs;
				}
			}
		}
	}
} 

// private Maybe[list[ArgumentList]] extractAssertionsArguments(MethodBody body) {
//   list[ArgumentList] args = [];
//   top-down visit(body) {
//     case MethodInvocation m : top-down visit(m) {
//       case ArgumentList argList : args += argList;
//     }
//   }
//   if(isEmpty(args)) return nothing();
//   return just(args);
// }

