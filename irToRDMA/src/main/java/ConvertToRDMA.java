import java.io.*;

import java.util.Set;
import java.util.HashSet;
import java.util.TreeSet;
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Arrays;

import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;

public class ConvertToRDMA { // Intelliband, VPI_Verbs API
    public static String DEFAULT_OUTPUT_DIR = "output";

    String inputFileName;
    ParseTree tree;
    VarsValue varsValue;
    InstanceValue instanceValue;
    TranslateValue translateValue;

    public ConvertToRDMA(String inputFileName, ParseTree tree) {
        this.inputFileName = inputFileName;
        this.tree = tree;

        translateValue = new TranslateValue();
        TranslateVisitor translateVisitor = new TranslateVisitor(translateValue);
        translateVisitor.visit(tree);
//
//        instanceValue = new InstanceValue();
//        RmaVisitor rmaVisitor = new RmaVisitor(instanceValue);
//        rmaVisitor.visit(tree);
//
//        varsValue = new VarsValue();
//        VarsVisitor varsVisitor = new VarsVisitor(varsValue, instanceValue);
//        varsVisitor.visit(tree);
    }

    public void incorporateOriginalIR(PrintStream os) throws java.io.IOException {
//        BufferedReader br = new BufferedReader(new FileReader(inputFileName));
//        String s = null;
//        while ((s = br.readLine()) != null) {
//	    if (s.equals("process 0"))
//		os.println("process 0 (client)");
//	    else if (s.equals("process 1"))
//		os.println("process 1 (server)");
//	    else
//		os.println(s);
//        }
//        br.close();
    	throw new RuntimeException("not implemented yet");
    }
//
    public void incorporateSharedVarDecls(PrintStream os) throws java.io.IOException {
//        Set<Var> allVars = new HashSet<Var>();
//        /* counters for the observed outputs of the program */
//        for (int i = 0; i < instanceValue.outputs.size(); i++) {
//            os.printf("long cnt_%d = 0;\n", i);
//        }
//	os.printf("long unexpected_cnt = 0;\n");
//
//        for (Proc p : instanceValue.processes) {
//            allVars.addAll(varsValue.procToShared.get(p));
//        }
//
//        os.printf("long long * all_failed;\n");
//        os.printf("long long * client_state, * server_state;\n");
//        for (Var v : allVars) {
//            os.printf("long long * %s;\n", v.name, instanceValue.varNameToIndex.get(v.name));
//        }
    	throw new RuntimeException("not implemented yet");
    }
//
    void emitVarPointerAssigns(PrintStream os, Proc p) throws java.io.IOException {
//	for (Var v : varsValue.procToShared.get(p)) {
//	    os.printf("    %s = &vars[%d];\n", v.name,
//		      instanceValue.varNameToIndex.get(v.name));
//	}
//	if (p.procNumber > 1) {
//	}
    	throw new RuntimeException("not implemented yet");
    }
//
    public void incorporateSharedVars(PrintStream os) throws java.io.IOException {
//	os.printf("  all_failed = &vars[0];\n");
//	os.printf("  if (app == CLIENT) {\n");
//	os.printf("    client_state = &vars[1];\n");
//	os.printf("    *client_state = 0;\n");
//	os.printf("    server_state = &vars[2];\n");
//	os.printf("  } else {\n");
//	os.printf("    client_state = &vars[1];\n");
//	os.printf("    server_state = &vars[2];\n");
//	os.printf("    *server_state = 0;\n");
//	os.printf("  }\n");
//	Set<Var> sharedVars = new TreeSet<>();
//	for (Proc p : instanceValue.processes) {
//	    sharedVars.addAll(varsValue.procToShared.get(p));
//	}
//	for (Var v : sharedVars) {
//	    os.printf("  %s = &vars[%d];\n", v.name,
//		      instanceValue.varNameToIndex.get(v.name));
//	}
    	throw new RuntimeException("not implemented yet");
   }
//
    public void incorporateLocalDecls(PrintStream os) throws java.io.IOException {
//        StringBuilder vars = new StringBuilder();
//        for (Proc p : instanceValue.processes) {
//            for (Var v : varsValue.procToLocal.get(p)) {
//                if (vars.length() > 0) vars.append(", ");
//                vars.append(v.name);
//            }
//        }
//        os.printf("long long %s;\n", vars);
//    }
//
//    int getAllVarsSize() {
//	List<Var> allVars = new LinkedList<>();
//	for (Proc p : instanceValue.processes) {
//	    for (Var v : varsValue.procToShared.get(p)) {
//		allVars.add(v);
//	    }
//	}
//	return allVars.size();
    	throw new RuntimeException("not implemented yet");
    }
//
    void emitInitialValues(PrintStream os, Proc p) throws java.io.IOException {
//	for (Var v : varsValue.procToShared.get(p)) {
//	    if (v.hasInitialValue)
//		os.printf("    *%s = %d;\n", v, v.iv);
//	}
    	throw new RuntimeException("not implemented yet");
    }
//
    public void incorporateTestInit(PrintStream os) throws java.io.IOException {
//        boolean haveTwo = (instanceValue.processes.size() > 1);
//
//        if (haveTwo) {
//            os.printf("  if (app == CLIENT) {\n");
//            emitInitialValues(os, new Proc(0));
//            os.printf("  } else {\n");
//            emitInitialValues(os, new Proc(1));
//            os.printf("  }\n");
//        } else {
//            emitInitialValues(os, new Proc(0));
//        }
    	throw new RuntimeException("not implemented yet");
    }
//
    void emitPerProcTestBody(PrintStream os, Proc p) throws java.io.IOException {
//	for (String s : instanceValue.processContents.get(p.procNumber)) {
//	    os.println("    if (rand() % 2 == 1) { usleep(1); }");
//	    os.println("    " + s);
//	}
    	throw new RuntimeException("not implemented yet");
    }
//
    public void incorporateTestBody(PrintStream os) throws java.io.IOException {
//        boolean haveTwo = (instanceValue.processes.size() > 1);
//
//        if (haveTwo) {
//            os.printf("  if (app == CLIENT) {\n");
//            /* add long sleep for first thread */
//            os.println("    if (rand() % 2 == 1) { usleep(5 + (rand()%10)); }");
//            emitPerProcTestBody(os, new Proc(0));
//            os.printf("  } else {\n");
//            emitPerProcTestBody(os, new Proc(1));
//            os.printf("  }\n");
//        } else {
//            emitPerProcTestBody(os, new Proc(0));
//        }

    	throw new RuntimeException("not implemented yet");
    }
//
    private String checkThread(int nrProcs, int procId) {
//        if (nrProcs == 1) {
//            return "(1)";
//        } else {
//            return String.format("(app == %s)", procId == 0 ? "CLIENT" : "SERVER");
//        }
    	throw new RuntimeException("not implemented yet");
    }
//
public void incorporateTestWitnesses(PrintStream os) throws java.io.IOException {
        boolean firstVar = true;
 //       for (Node n : instanceValue.nodes) {
//          	for (Proc p : instanceValue.processes) {
		 //           if (!varsValue.procToLocal.get(p).isEmpty()) {
		//                os.printf("  if %s {\n",
		//                        checkThread(instanceValue.processes.size(), p.procNumber));
		//                for (Var v : varsValue.procToLocal.get(p)) {
		//                    // (local vars don't have initial values)
		//                    if (p.procNumber == 0) {
		//                        os.printf("    *%s_global = %s;\n", v, v);
		//                    } else {
		//                        os.printf("    *%s_global = %s;\n", v, v);
		//                        os.printf("    rdma_operation(app, conn, *conn->peer_mr, %s_global - vars, %s_global, conn->rdma_mr, IBV_WR_RDMA_WRITE, 0);\n", v, v);
		//                    }
		//                }
		//                os.printf("  }\n");
	//	            }
		
//        }
//
//	os.printf("  send_flush(peer, cq, conn, true);\n");
//	os.printf("#if DUMP_VARS\n");
//	for (Proc p : instanceValue.processes) {
//	    StringBuilder varFormats = new StringBuilder(), varNames = new StringBuilder();
//	    for (Var v : varsValue.procToShared.get(p)) {
//		if (firstVar) {
//		    firstVar = false;
//		} else {
//		    varFormats.append(" ");
//		}
//		varNames.append(", ");
//
//		String vf = String.format("%s=%%lld", v.name);
//		varFormats.append(vf);
//		varNames.append("*"+v.name);
//	    }
//
//	    if (p.procNumber == 0) {
//		os.printf("  if (app == CLIENT) {\n");
//	    }
//	    else {
//		os.printf("  if (app != CLIENT) {\n");
//	    }
//	    os.printf("    printf(\"values: %s\\n\"%s);\n", varFormats.toString(), varNames.toString());
//	    os.printf("  }\n");
//	}
	os.printf("#endif\n");
	throw new RuntimeException("not implemented yet");
}
//
    public void incorporateTestCollate(PrintStream os) throws java.io.IOException {
//        boolean firstVar = true;
//        StringBuilder varFormats = new StringBuilder(),
//            varNames = new StringBuilder();
//
//        os.printf("\n    /* Load results from global _received variables to locals */\n");
//        os.printf("    if %s {\n", checkThread(instanceValue.processes.size(), 0));
//        for (Proc p : instanceValue.processes) {
//            for (Var v : varsValue.procToLocal.get(p)) {
//                os.printf("        %s = *%s_global;\n", v, v);
//            }
//        }
//        os.printf("    }\n");
//
//        for (Proc p : instanceValue.processes) {
//            for (Var v : varsValue.procToLocal.get(p)) {
//                if (firstVar) {
//                    firstVar = false;
//                } else {
//                    varFormats.append(" ");
//                }
//                varNames.append(", ");
//
//                String vf = String.format("%s=%%lld", v );
//                varFormats.append(vf);
//                varNames.append(v);
//            }
//        }
//
//        os.printf("\n    /* Check which output is observed */\n");
//
//        os.printf("    if %s {\n", checkThread(instanceValue.processes.size(), 0));
//	if (instanceValue.outputs.size() == 0)
//	    os.println("        if (0) ;");
//        for (int i = 0; i < instanceValue.outputs.size(); i++) {
//            String output = instanceValue.outputs.get(i);
//            os.printf("        %sif %s cnt_%d++;\n", (i == 0)? "" : "else ",  output, instanceValue.outputs.indexOf(output));
//        }
//        os.printf("        else {\n");
//	os.printf("          fprintf(stderr, \"UNEXPECTED: %s\\n\"%s);\n", varFormats.toString(), varNames.toString());
//	os.printf("          unexpected_cnt++;\n");
//	os.printf("        }\n");
//
//        os.printf("    }\n");
//    }
//    
//    StringBuilder simpleExpressionBuffer;
//    List<String> vars;
//    private Object visitSimpleExpression(TLParser.SimpleExpressionContext ctx) {
//        if (ctx.And() != null) {
//            /* simpleExpression And simpleExpression*/
//            simpleExpressionBuffer.append("(");
//            visitSimpleExpression(ctx.simpleExpression(0));
//            simpleExpressionBuffer.append(" && ");
//            visitSimpleExpression(ctx.simpleExpression(1));
//            simpleExpressionBuffer.append(")");
//
//        } else if (ctx.Or() != null) {
//            /* simpleExpression Or simpleExpression */
//            simpleExpressionBuffer.append("(");
//            visitSimpleExpression(ctx.simpleExpression(0));
//            simpleExpressionBuffer.append(" || ");
//            visitSimpleExpression(ctx.simpleExpression(1));
//            simpleExpressionBuffer.append(")");
//
//        } else if (ctx.Excl() != null) {
//            /* Excl simpleExpression */
//            simpleExpressionBuffer.append("!(");
//            visitSimpleExpression(ctx.simpleExpression(0));
//            simpleExpressionBuffer.append(")");
//
//        } else if (ctx.OParen() != null) {
//            /* OParen simpleExpression CParen */
//            simpleExpressionBuffer.append("(");
//            visitSimpleExpression(ctx.simpleExpression(0));
//            simpleExpressionBuffer.append(")");
//
//        } else if (ctx.Equals() != null) {
//            /* Identifier Equals rhs */
//            vars.add(ctx.Identifier().getText());
//            simpleExpressionBuffer.append(ctx.Identifier().getText() + " == " );
//            visitRhs(ctx.rhs());
//
//        } else if (ctx.NEquals() != null) {
//            /* Identifier NEquals rhs */
//            vars.add(ctx.Identifier().getText());
//            simpleExpressionBuffer.append("(" + ctx.Identifier().getText() + " != " );
//            visitRhs(ctx.rhs());
//            simpleExpressionBuffer.append(")");
//
//        } else {
//            System.err.println("Error");
//            System.exit(1);
//        }
//        return null;

    	throw new RuntimeException("not implemented yet");
    }
//
//    public Object visitRhs(TLParser.RhsContext ctx) {
//        if (ctx.Number() != null) {
//            simpleExpressionBuffer.append(ctx.getText()+"L");
//        } else {
//            simpleExpressionBuffer.append(ctx.getText());
//        }
//        return null;
//    }
//
    public void incorporateStats(PrintStream os) throws java.io.IOException {
//        /* print the execution outputs */
//
//        os.printf("    if %s {\n", checkThread(instanceValue.processes.size(), 0));
//        for (int i = 0; i < instanceValue.outputs.size(); i++) {
//            String output = instanceValue.outputs.get(i);
//            os.println("        fprintf(stderr, \"OBSERVED " + output + ": %ld\\n\", cnt_" + instanceValue.outputs.indexOf(output) + ");");
//        }
//	os.printf("        fprintf(stderr, \"unexpected count %%ld\\n\", unexpected_cnt);\n");
//        os.printf("    }\n");

    	throw new RuntimeException("not implemented yet");
    }
//
    public void macroExpand(PrintStream os, int payload, String outputName) throws java.io.IOException {
        switch (payload) {
        case 0:
            os.printf("%s\n", outputName);
            break;
        case 3:
	    incorporateSharedVarDecls(os);
	    break;
	case 4:
	    incorporateSharedVars(os);
	    break;
        case 5:
            incorporateLocalDecls(os);
            break;

        case 11:
            incorporateOriginalIR(os);
            break;

	case 12:
	    incorporateTestInit(os);
	    break;
	case 13:
	    incorporateTestBody(os);
	    break;
	case 14:
	    incorporateTestWitnesses(os);//incorporate all possible outcomes
	    break;
	case 15:
	    incorporateTestCollate(os);
	    break;
	case 16:
	    incorporateStats(os);
	    break;

        default:
	    System.out.printf("warning: unrecognized macro $%d\n", payload);
            os.printf("$%d\n", payload);
            break;
        }
    }
//
//    public void expandTemplate(File outputDir, String outputName) throws java.io.IOException {
//        for (String fn : Arrays.asList("rdma-test.c", "rdma-test.h")) {
//            File os = new File(outputDir, fn);
//            PrintStream ps = new PrintStream(os);
//
//            InputStream in = ConvertToRDMA.class.getClassLoader().getResourceAsStream(fn);
//            BufferedReader br = new BufferedReader(new InputStreamReader(in));
//            String s;
//
//            while ((s = br.readLine()) != null) {
//                String st = s.trim();
//                if (st.contains("{0}")) {
//                    st = st.replace("{0}", outputName);
//                    ps.println(st);
//		} else if (st.contains("{2}")) {
//		    List<Var> allVars = new LinkedList<>();
//		    for (Proc p : instanceValue.processes) {
//			for (Var v : varsValue.procToShared.get(p)) {
//			    allVars.add(v);
//			}
//		    }
//
//		    // implicit: all_failed, client_state, server_state
//		    st = s.replace("{2}", Integer.toString(allVars.size()+3));
//		    ps.println(st);
//		} else if (st.startsWith("$")) {
//                    if (st.endsWith(";")) st = st.substring(0, st.length()-1);
//                    int payload = Integer.parseInt(st.substring(1));
//                    macroExpand(ps, payload, outputName);
//                } else {
//                    ps.println(s);
//                }
//            }
//            br.close();
//            ps.close();
//        }
//    }
//
//    public void generateAuxiliaries(File outputDir, String outputName) throws java.io.IOException {
//        for (String fn : Arrays.asList("Makefile", "rdma-client.c", "rdma-common.c", "rdma-common.h", "rdma-server.c", "rdma-starter.c", "rdma-single.c")) {
//            File os = new File(outputDir, fn);
//            PrintStream ps = new PrintStream(os);
//
//            InputStream in = ConvertToRDMA.class.getClassLoader().getResourceAsStream(fn);
//            BufferedReader br = new BufferedReader(new InputStreamReader(in));
//            String s;
//
//            while ((s = br.readLine()) != null) {
//                String st = s.trim();
//                if (st.contains("{0}")) {
//                    st = st.replace("{0}", outputName);
//                    ps.println(st);
//                } else {
//                    ps.println(s);
//                }
//            }
//            br.close();
//            ps.close();
//        }
//    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("Please specify input file name and output name");
            System.exit(1);
        }
        String inputFileName = args[0];
        String outputFileName = args[1];

//        /* Parse input program */
//        TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));
//        TLParser parser = new TLParser(new CommonTokenStream(lexer));
//
//        parser.setBuildParseTree(true);
//        ParseTree tree = parser.parse();
//
//        ConvertToRDMA c = new ConvertToRDMA(inputFileName, tree);
//
//        String allOutputDirName = DEFAULT_OUTPUT_DIR;
//        File allOutputDir = new File(allOutputDirName);
//        if (!allOutputDir.exists()) {
//            allOutputDir.mkdir();
//            if (!allOutputDir.exists()) {
//                System.err.printf("could not create output directory %s; aborting.\n",
//                                  allOutputDirName);
//                System.exit(1);
//            }
//        }
//        if (!allOutputDir.isDirectory()) {
//            System.err.printf("output directory %s is not directory; aborting.\n",
//                              allOutputDirName);
//            System.exit(1);
//        }
//
//        String thisOutputDirName = allOutputDir + File.separator + outputFileName;
//        File thisOutputDir = new File(thisOutputDirName);
//        if (!thisOutputDir.exists()) {
//            thisOutputDir.mkdir();
//            if (!thisOutputDir.exists()) {
//                System.err.printf("could not create output directory %s; aborting.\n",
//                                  thisOutputDirName);
//                System.exit(1);
//            }
//        }
//        if (!thisOutputDir.isDirectory()) {
//            System.err.printf("output directory %s is not directory; aborting.\n",
//                              thisOutputDirName);
//            System.exit(1);
//        }
//
//        c.expandTemplate(thisOutputDir, outputFileName);
//        c.generateAuxiliaries(thisOutputDir, outputFileName);
    }
}
// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
