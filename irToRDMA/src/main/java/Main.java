
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
//    // recieves an alloy file and
//	// 1. generates all results.
//    public static void getAssumptions(String inputFileName) {
//        /* Parse input program */
//
//        MyErrorListener listener = new MyErrorListener();
//
//        try {
//
//            TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));
//
//            TLParser parser = new TLParser(new CommonTokenStream(lexer));
//
//            parser.setBuildParseTree(true);
//            //parser.removeErrorListeners();
//            //parser.addErrorListener(listener);
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
//            out.write(translateValue.toString(0, null));
//            out.close();
//
//        /* Loop to determine all possible outcomes */
//            HashMap<String, Integer> locals = null;
//            int cnt = 0;
//            String constraint = "";
//            StringBuffer result = new StringBuffer();
//            do {
//                locals = CheckSat.getLocals(outFileName);
//                if (locals != null) {
//                    StringBuffer sb = new StringBuffer();
//                    sb.append("not (");
//                    result.append("output(");
//                    Iterator<String> i = locals.keySet().iterator();
//                    while (i.hasNext()) {
//                        String localVar = i.next();
//                        sb.append("(value[" + localVar + "] = " + locals.get(localVar) + ")");
//                        result.append("(" + TranslateVisitor.decodeVarName(localVar) + " == " + locals.get(localVar) + ")");
//                        if (i.hasNext()) {
//                            sb.append(" and ");
//                            result.append(" && ");
//                        }
//                    }
//                    sb.append(")");
//                    result.append(");\n");
//                    if (constraint.length() > 0) {
//                        constraint = constraint + " and " + sb.toString();
//                    } else {
//                        constraint = sb.toString();
//                    }
//                    //System.out.println(sb.toString());
//                    cnt++;
//                    outFileName = inputFileName + cnt + ".als";
//                    out = new BufferedWriter(new FileWriter(outFileName));
//
//                    out.write(translateValue.toString(0, constraint));
//                    out.close();
//
//                }
//            } while (locals != null);
//
//
//            BufferedWriter br = new BufferedWriter(new FileWriter(inputFileName, true));
//            br.append(result.toString());
//            br.close();
//
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//
//    }
//
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

//            getAssumptions(args[0]);

           

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
