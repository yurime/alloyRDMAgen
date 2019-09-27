import static org.junit.Assert.fail;

import java.io.File;
import java.io.IOException;

import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;


public class Driver {

    public static TranslateValue getResult(File arg) {

    	TranslateValue translateValue = new TranslateValue();
    	try {
	    	String inputFileName = arg.getAbsolutePath();
	        TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));
	
	        TLParser parser = new TLParser(new CommonTokenStream(lexer));
	        parser.setBuildParseTree(true);
	        ParseTree tree = parser.parse();
	        /* Generate program in Alloy */
	
	        TranslateVisitor translateVisitor = new TranslateVisitor(translateValue);
	        translateVisitor.visit(tree);	
        } catch (IOException e) {
    		// TODO Auto-generated catch block for reading from file 
    		e.printStackTrace();
    		fail();
    	}
    	return translateValue;
    }
}
