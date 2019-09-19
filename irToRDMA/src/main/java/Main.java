
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.util.HashMap;
import java.util.Iterator;

import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.ParseTree;

class MyErrorListener extends BaseErrorListener {
    public String error_msg;
    public MyErrorListener(){
        this.error_msg = "";
    }
    @Override
    public void syntaxError(Recognizer<?, ?> recognizer,
                            Object offendingSymbol,
                            int line,
                            int charPositionInLine,
                            String msg,
                            RecognitionException e) {
        this.error_msg = this.error_msg + "line " + line + ":" + charPositionInLine + " " + msg + "\n";
    }

}

public class Main {
	/**  Generates all possible outputs and appends them to the input file.
	 *<p><b>Pseudo algorithm:</b> 
	 *  <ol>
	 *	   <li> Generates a corresponding alloy input file </li>
	 *	   <li> While there is a result (assignment to registers):<ol>
	 *      <li> adds to the ir file a possible output result</li>
	 *      <li> creates a copy of the als file with negation of the result </li>
	 *      <li> feeds it back to alloy </li>
	 *     </li></ol>
	 *  </ol>
	 *</p>
	 * @param inputFileName -- an intermediate representation file
	 **/
    public static void getAssumptions(String inputFileName) {
        /* Parse input program */

        MyErrorListener listener = new MyErrorListener();

        try {

            TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));

            TLParser parser = new TLParser(new CommonTokenStream(lexer));

            parser.setBuildParseTree(true);
            parser.removeErrorListeners();
            parser.addErrorListener(listener);
            ParseTree tree = parser.parse();

        /* Generate program in Alloy */

            TranslateValue translateValue = new TranslateValue();
            TranslateVisitor translateVisitor = new TranslateVisitor(translateValue);
            translateVisitor.visit(tree);

            String outFileName = inputFileName + ".als";
            BufferedWriter out = new BufferedWriter(new FileWriter(outFileName));

            out.write(translateValue.toString(0, null));
            out.close();

        /* Loop to determine all possible outcomes */
            HashMap<String, Integer> locals = null;
            int cnt = 0;
            String constraint = "";
            StringBuffer result = new StringBuffer();
            locals = CheckSat.getLocals(outFileName);
            while (locals != null) {
                StringBuffer sb = new StringBuffer();
                sb.append("not (");
                result.append("output(");
                Iterator<String> i = locals.keySet().iterator();
                while (i.hasNext()) {
                	String localVar = i.next();
                	sb.append("(value[" + localVar + "] = " + locals.get(localVar) + ")");
                	result.append("(" + TranslateVisitor.decodeVarName(localVar) + " == " + locals.get(localVar) + ")");
                	if (i.hasNext()) {
                		sb.append(" and ");
                		result.append(" && ");
                	}
                }
                sb.append(")");
                result.append(");\n");
                if (constraint.length() > 0) {
                	constraint = constraint + " and " + sb.toString();
                } else {
                	constraint = sb.toString();
                }
                System.out.println(sb.toString());
                cnt++;
                outFileName = inputFileName + cnt + ".als";
                out = new BufferedWriter(new FileWriter(outFileName));
            	out.write(translateValue.toString(0, constraint));
            	out.close();
            	locals = CheckSat.getLocals(outFileName);
            } 


            BufferedWriter br = new BufferedWriter(new FileWriter(inputFileName, true));
            br.append(result.toString());
            br.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

    }

//   /** receives an alloy file and
//	  *  2. checks something.. (robustness, or assertion)
//    **/
//    public static Result checkFile(String inputFileName) {
//
//        /* Parse input program */
//
//        Result res = new Result();
//        MyErrorListener listener = new MyErrorListener();
//
//
//        try {
//
//            TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));
//
//            TLParser parser = new TLParser(new CommonTokenStream(lexer));
//
//            parser.setBuildParseTree(true);
//            parser.removeErrorListeners();
//            parser.addErrorListener(listener);
//            ParseTree tree = parser.parse();
//
//        /* Generate program in Alloy */
//
//            TranslateValue translateValue = new TranslateValue();
//            TranslateVisitor translateVisitor = new TranslateVisitor(translateValue);
//            translateVisitor.visit(tree);
//
//            String outFileName = inputFileName + ".als";
//            BufferedWriter out = new BufferedWriter(new FileWriter(outFileName));
//
//            out.write(translateValue.toString(2, null));
//            out.close();
//
//        /* Check robustness or assertion */
//
//            boolean isSat = CheckSat.isSat(outFileName);
//            res.is_sat = isSat;
//            res.check_robustness = translateValue.check_robustness;
//            res.found_error = false;
//
//        } catch (Exception e) {
//            res.found_error = true;
//            res.error_msg = listener.error_msg;
//        }
//        return res;
//
//    }

    public static void main(String[] args) throws Exception {
        try {
            if (args.length < 1) {
                System.out.println("Please specify file name.");
                System.exit(1);
            }

            getAssumptions(args[0]);

            /* Result resultAnalysis = checkFile(args[0]);

            if (resultAnalysis.found_error) {
                System.out.println("Error: " + resultAnalysis.error_msg);
            } else {
                boolean isSat = resultAnalysis.is_sat;
                if (resultAnalysis.check_robustness) {
                    System.out.println("Program is " + ((isSat) ? "not " : "") + "robust");
                } else {
                    System.out.println("Program " + ((isSat) ? "does not satisfy " : "satisfies ") + "the assertion.");
                }
            }*/ 

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
