module lang::java::transformations::junit::Imports

import ParseTree;
import lang::java::\syntax::Java18;

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
	MethodBody methodBody = extractMethodBody(unit);
	Expression exp = (Expression) `Thread.ofVirtual().factory()`;
	Identifier th = parse(#Identifier, "threadFactory");
	LeftHandSide id = (LeftHandSide) `<Identifier th>`;
    StatementExpression exp2 = (StatementExpression) `<LeftHandSide id> = Thread.ofVirtual().factory()`;
    ReturnStatement expression = (ReturnStatement) `return Executors.newCachedThreadPool();`;
	MethodInvocation mi = (MethodInvocation) `Executors.newCachedThreadPool()`;	
    int assertionCount = 0;
    methodBody = top-down visit(methodBody) {
		case BlockStatement s : { 
	        assertionCount += 1;
			isStatementAGeneralStatement(s);
		// 	if(isStatementAGeneralStatement(s)) {
		// 		assertionCount += 1;
		// // 	// Statement statement = statementInBlockStmt(s);
      	// 	}
	  	} 
		case (StatementExpression) `<LeftHandSide id> = <Expression exp>`=> exp2
    }
	return unit;
}

public MethodBody extractMethodBody(CompilationUnit unit) {
  top-down visit(unit) {
    case MethodBody b: return b;
  }
}

private void updateBlockStatement(MethodBody m) {
    // insert((ExpressionStatement) `ThreadFactory threadFactory = Thread.ofVirtual().factory();`);
	// return (MethodInvocation)  `Executors.newFixedThreadPool()`;
	insert((MethodInvocation) `Thread.ofVirtual().factory()`);
}

public BlockStatement isStatementAGeneralStatement(BlockStatement statement) {
  top-down visit(statement) {
    case LocalVariableDeclarationStatement _ : return statement;
    case ClassDeclaration _ : return statement;
    case Statement s => isStatementWithoutTrailingSubstatement(s, statement)
  }
  return statement;
}

public Statement isStatementWithoutTrailingSubstatement(Statement statement, BlockStatement bstmt) {
  top-down visit(statement) {
    case StatementWithoutTrailingSubstatement s => isStatementWithoutTrailingSubstatement(s)
  }
  return statement;
}

public StatementWithoutTrailingSubstatement isStatementWithoutTrailingSubstatement(StatementWithoutTrailingSubstatement statement) {
//   top-down visit(statement) {
//     case ExpressionStatement s => isExpressionStatement(s)
//   }
  return statement;
}


// private Imports updateImports(ImportDeclaration* imports) {
// 	imports = top-down visit(imports) {
// 		case (ImportDeclaration) `import org.junit.*;` => (ImportDeclaration) `import org.junit.jupiter.api.*;`
// 		case (ImportDeclaration) `import org.junit.Test;` => (ImportDeclaration) `import org.junit.jupiter.api.Test;`
// 		case (ImportDeclaration) `import org.junit.BeforeClass;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeAll;`
// 		case (ImportDeclaration) `import org.junit.Before;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeEach;`
// 		case (ImportDeclaration) `import org.junit.After;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterEach;`
// 		case (ImportDeclaration) `import org.junit.AfterClass;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterAll;`
// 		case (ImportDeclaration) `import org.junit.Ignore;` => (ImportDeclaration) `import org.junit.jupiter.api.Disabled;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertArrayEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertArrayEquals;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertEquals;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertFalse;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertFalse;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotNull;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertNotSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotSame;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNull;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertSame;`
// 		case (ImportDeclaration) `import static org.junit.Assert.assertTrue;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertTrue;`
// 		case (ImportDeclaration) `import static org.junit.Assert.fail;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.fail;`
// 		case (ImportDeclaration) `import static org.junit.Assert.*;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.*;`
// 	}
// 	return parse(#Imports, unparse(imports));
// }

// case (MethodBody) `{
// 			'<Statement stmts>
// 			'<ReturnStatement expression>
// 			'}` => 
// 			(MethodBody) `{
// 			'<Statement stmts>}`