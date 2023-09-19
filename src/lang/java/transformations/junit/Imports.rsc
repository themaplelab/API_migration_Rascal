module lang::java::transformations::junit::Imports

import ParseTree;
import lang::java::\syntax::Java18;

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
    unit = top-down visit(unit) {
	   	case (MethodInvocation) `Executors.newCachedThreadPool()` => updateBlockStatement()
       	case (ClassInstanceCreationExpression) `new Thread(<ArgumentList args>)` => (ClassInstanceCreationExpression) `new Car(<ArgumentList args>)`
    }
	return unit;
}

private MethodInvocation updateBlockStatement() {
    // insert(`ThreadFactory threadFactory =Thread.ofVirtual().factory();`);
	return (MethodInvocation)  `Executors.newFixedThreadPool()`;
}


private Imports updateImports(ImportDeclaration* imports) {
	imports = top-down visit(imports) {
		case (ImportDeclaration) `import org.junit.*;` => (ImportDeclaration) `import org.junit.jupiter.api.*;`
		case (ImportDeclaration) `import org.junit.Test;` => (ImportDeclaration) `import org.junit.jupiter.api.Test;`
		case (ImportDeclaration) `import org.junit.BeforeClass;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeAll;`
		case (ImportDeclaration) `import org.junit.Before;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeEach;`
		case (ImportDeclaration) `import org.junit.After;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterEach;`
		case (ImportDeclaration) `import org.junit.AfterClass;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterAll;`
		case (ImportDeclaration) `import org.junit.Ignore;` => (ImportDeclaration) `import org.junit.jupiter.api.Disabled;`
		case (ImportDeclaration) `import static org.junit.Assert.assertArrayEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertArrayEquals;`
		case (ImportDeclaration) `import static org.junit.Assert.assertEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertEquals;`
		case (ImportDeclaration) `import static org.junit.Assert.assertFalse;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertFalse;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotNull;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNotSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotSame;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNull;`
		case (ImportDeclaration) `import static org.junit.Assert.assertSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertSame;`
		case (ImportDeclaration) `import static org.junit.Assert.assertTrue;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertTrue;`
		case (ImportDeclaration) `import static org.junit.Assert.fail;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.fail;`
		case (ImportDeclaration) `import static org.junit.Assert.*;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.*;`
	}
	return parse(#Imports, unparse(imports));
}
