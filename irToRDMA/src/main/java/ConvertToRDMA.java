import java.io.*;

import java.util.Set;
import java.util.HashSet;
import java.util.TreeSet;
import java.util.Arrays;

import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
/**
 * (ConvertToRma)Created by Andrei on 8/15? He didn't say..
 * Modified by Yuri 09/2019 (and turned to ConvertToRDMA)
 * 
 * ConvertToRDMA.main() Will read the .ir file and inject into the rdma template code 
 * that will simulate the .ir file behavior under rdma setting. 
 *
 */
public class ConvertToRDMA { // Intelliband, VPI_Verbs API
    public static String DEFAULT_OUTPUT_DIR = "output";

    String inputFileName;
    ParseTree tree;
    VarsValue varsValue;
    InstanceValue instanceValue;
    TranslateValue translateValue;//not used?
	
    public ConvertToRDMA(String inputFileName, ParseTree tree) {
        this.inputFileName = inputFileName;
        this.tree = tree;

        translateValue = new TranslateValue();// V
        TranslateVisitor translateVisitor = new TranslateVisitor(translateValue);
        translateVisitor.visit(tree);

        instanceValue = new InstanceValue(); 
        RDMAvisitor rdmaVisitor = new RDMAvisitor(instanceValue);
        rdmaVisitor.visit(tree);

        varsValue = new VarsValue();
        VarsVisitor varsVisitor = new VarsVisitor(varsValue, instanceValue);
        varsVisitor.visit(tree);
        
    }

    public void incorporateOriginalIR(PrintStream os) throws java.io.IOException {
        BufferedReader br = new BufferedReader(new FileReader(inputFileName));
        String s = null;
        while ((s = br.readLine()) != null) {
			os.println(s);
        }
        br.close();
    	throw new RuntimeException("not implemented yet");
    }
//
    public void incorporateSharedVarDecls(PrintStream os, Proc p) throws java.io.IOException {
        Set<Var> allVars = new HashSet<Var>();
        /* counters for the observed outputs of the program */

		allVars.addAll(varsValue.procToShared.get(p));
        
        for (Var v : allVars) {
            os.printf("LOCAL_SHARED(%s, con);\n", v.name, instanceValue.varNameToIndex.get(v.name));
        }
    }
//

    public void incorporateSharedVars(PrintStream os, Proc p) throws java.io.IOException {
	Set<Var> sharedVars = new TreeSet<>();

	sharedVars.addAll(varsValue.procToShared.get(p));
	for (Var v : sharedVars) {
	    os.printf("LOCAL_SHARED(%s, con) = %d;\n", v.name,v.iv);
	}
   }
    
    public void incorporateRemAccessVars(PrintStream os, Proc me) throws java.io.IOException {
	for (Proc tar : instanceValue.processes) {
		if(tar==me) continue;
		Set<Var> sharedVars = new TreeSet<>();
		sharedVars.addAll(varsValue.procToShared.get(tar));
		for (Var v : sharedVars) {
		    os.printf("REMOTE_SHARED(%s, con.at(%d))", v.name,tar);
		}
	}
   }
//
    public void incorporateLocalDecls(PrintStream os, Proc p) throws java.io.IOException {
    	StringBuilder vars = new StringBuilder();
    	for (Var v : varsValue.procToLocal.get(p)) {
    		if (vars.length() > 0) vars.append(", ");
			vars.append(v.name);
    	}
    	os.printf("uint64_t %s;\n", vars);
    }
//
//    int getAllVarsSize() {
//	List<Var> allVars = new LinkedList<>();
//	for (Proc p : instanceValue.processes) {
//	    for (Var v : varsValue.procToShared.get(p)) {
//		allVars.add(v);
//	    }
//	}
//	return allVars.size();
//    	throw new RuntimeException("not implemented yet");
//    }
//

    void emitPerProcTestBody(PrintStream os, Proc p) throws java.io.IOException {
    	for (String s : instanceValue.processContents.get(p.procNumber)) {
    		os.println("    if (rand() % 2 == 1) { usleep(1); }");
	    	os.println("    " + s);
    	}
    }


//
public void incorporateTestWitnesses(PrintStream os) throws java.io.IOException {
        boolean firstVar = true;
        for (Node n : instanceValue.nodes) {
          	for (Proc p : instanceValue.processes) {
          		if (!varsValue.procToLocal.get(p).isEmpty()) {
		//                for (Var v : varsValue.procToLocal.get(p)) {
		//                    // (local vars don't have initial values)
		//                    if (p.procNumber == 0) {
		//                        os.printf("    *%s_global = %s;\n", v, v);
		//                    } else {
		//                        os.printf("    *%s_global = %s;\n", v, v);
		//                        os.printf("    rdma_operation(app, conn, *conn->peer_mr, %s_global - vars, %s_global, conn->rdma_mr, IBV_WR_RDMA_WRITE, 0);\n", v, v);
		//                    }
		                }
		                os.printf("  }\n");
            }
		
        }
//
//	os.printf("  send_flush(peer, cq, conn, true);\n");
	os.printf("#if DUMP_VARS\n");
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
/*
 * Collect results for one thread wait to receive from others,
 * and check assertion.
 * The rest, each, send their local variables values to the collecting thread.
 * The collecting thread must have local shared-locations for the other threads to rdma-write their values to. 
 */
    public void incorporateTestCollate(PrintStream os, Proc p) throws java.io.IOException {


//        boolean firstVar = true;
//        StringBuilder varFormats = new StringBuilder(),
//            varNames = new StringBuilder();

       	if(p.procNumber == 0) return;
        for (Var v : varsValue.procToLocal.get(p)) {
//        	    Scrap = c1;
//            POST_PUT(con,tcp_port,Scrap, tr1_c1);
//            POLL_CQ(con,tcp_port);
            os.printf("    Scrap = %s;\n", v, v);
            os.printf("    POST_PUT(con, tcp_port,Scrap,tr%d_%s);\n", p, v);
            os.printf("    POLL_CQ(con,tcp_port);");
            os.printf("    ");
        }
        
        os.printf("\n    /* Check which output is observed */\n");


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
    }
 

//    public void incorporateStats(PrintStream os) throws java.io.IOException {
////        /* print the execution outputs */
////
////        os.printf("    if %s {\n", checkThread(instanceValue.processes.size(), 0));
////        for (int i = 0; i < instanceValue.outputs.size(); i++) {
////            String output = instanceValue.outputs.get(i);
////            os.println("        fprintf(stderr, \"OBSERVED " + output + ": %ld\\n\", cnt_" + instanceValue.outputs.indexOf(output) + ");");
////        }
////	os.printf("        fprintf(stderr, \"unexpected count %%ld\\n\", unexpected_cnt);\n");
////        os.printf("    }\n");
//
//    	throw new RuntimeException("not implemented yet");
//    }

    public void macroExpand(PrintStream os, int payload, String outputName, Proc p) throws java.io.IOException {
    	
        switch (payload) {

		case 3:
			incorporateSharedVars(os,p);
		    break;
	    case 5:
	        incorporateLocalDecls(os,p);
	        break;
	    case 10:
	    	incorporateRemAccessVars(os,p);
	        break;
	    case 11:
	        incorporateOriginalIR(os);
	        break;
		case 13:
			emitPerProcTestBody(os,p);
		    break;
		case 14:
		    incorporateTestWitnesses(os);//incorporate all possible outcomes for thread 0
		    break;
		case 15:
		    incorporateTestCollate(os,p);//incorporate sending results to thread 0
		    break;
//		case 16:
//		    incorporateStats(os);
//		    break;
	    default:
		    System.out.printf("warning: unrecognized macro $%d\n", payload);
	            os.printf("$%d\n", payload);
	            break;
	    }//end case switch
    }

    public void expandTemplate(File outputDir, String outputName) throws java.io.IOException {
    	for (String fn : Arrays.asList("rdma-test.c", "rdma-test.h")) {
            File os = new File(outputDir, fn);
            PrintStream ps = new PrintStream(os);

            InputStream in = ConvertToRDMA.class.getClassLoader().getResourceAsStream(fn);
            BufferedReader br = new BufferedReader(new InputStreamReader(in));
            String s;
            int i = -1;

            while ((s = br.readLine()) != null) {
                String st = s.trim();
                 if (st.startsWith("//$")) {
                    if (st.endsWith(";")) st = st.substring(2, st.length()-3);
                    int payload = Integer.parseInt(st.substring(3));
                    macroExpand(ps, payload, outputName, new Proc(i));
                } else {
                    ps.println(s);
                    if(st.startsWith("int thr")) {
                    	++i;
                    }
                }
            }
    		br.close();
    		ps.close();
    	}
    }

    public void generateAuxiliaries(File outputDir, String outputName) throws java.io.IOException {
    	throw new RuntimeException("not implemented yet");
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
    }
	private static File getOutputDir(String outputFileName) {
		String allOutputDirName = DEFAULT_OUTPUT_DIR;
        File allOutputDir = new File(allOutputDirName);
        if (!allOutputDir.exists()) {
            allOutputDir.mkdir();
            if (!allOutputDir.exists()) {
                System.err.printf("could not create output directory %s; aborting.\n",
                                  allOutputDirName);
                System.exit(1);
            }
        }
        if (!allOutputDir.isDirectory()) {
            System.err.printf("output directory %s is not directory; aborting.\n",
                              allOutputDirName);
            System.exit(1);
        }

        String thisOutputDirName = allOutputDir + File.separator + outputFileName;
        File thisOutputDir = new File(thisOutputDirName);
        if (!thisOutputDir.exists()) {
            thisOutputDir.mkdir();
            if (!thisOutputDir.exists()) {
                System.err.printf("could not create output directory %s; aborting.\n",
                                  thisOutputDirName);
                System.exit(1);
            }
        }
        if (!thisOutputDir.isDirectory()) {
            System.err.printf("output directory %s is not directory; aborting.\n",
                              thisOutputDirName);
            System.exit(1);
        }
		return thisOutputDir;
	}
	
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("Please specify input file name and output name");
            System.exit(1);
        }
        String inputFileName = args[0];
        String outputFileName = args[1];

        /* Parse input program */
        TLLexer lexer = new TLLexer(new ANTLRFileStream(inputFileName));
        TLParser parser = new TLParser(new CommonTokenStream(lexer));

        parser.setBuildParseTree(true);
        ParseTree tree = parser.parse();

        ConvertToRDMA c = new ConvertToRDMA(inputFileName, tree);

        File thisOutputDir = getOutputDir(outputFileName);

        c.expandTemplate(thisOutputDir, outputFileName);
        c.generateAuxiliaries(thisOutputDir, outputFileName);
    }


}
// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
