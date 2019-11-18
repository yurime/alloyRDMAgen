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
	String tabs;
	static String sing_tab="  ";
	
    public ConvertToRDMA(String inputFileName, ParseTree tree) {
        this.inputFileName = inputFileName;
        this.tree = tree;
        this.tabs = "  ";

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

    public void incorporateOriginalIR(PrintStream os) throws FileNotFoundException, IOException {
        BufferedReader br = new BufferedReader(new FileReader(inputFileName));
        String s = null;
        os.println("/*");
        while ((s = br.readLine()) != null) {
			os.println(s);
        }
        os.println("*/");
        br.close();
    }
//
    public void incorporateSharedVarDecls(PrintStream os, Proc p)  {
        Set<Var> allVars = new HashSet<Var>();
        /* counters for the observed outputs of the program */

		allVars.addAll(varsValue.procToShared.get(p));
        
        for (Var v : allVars) {
        	if(instanceValue.atomicVars.get(p).contains(v.name)) {
        		os.printf(tabs + "LOCAL_AT_SHARED(%s, con);\n", v.name, instanceValue.varNameToIndex.get(v.name));
        	}else {
        		os.printf(tabs + "LOCAL_SHARED(%s, con);\n", v.name, instanceValue.varNameToIndex.get(v.name));
        	}
            
        }
    }


	public void incorporateSharedVars(PrintStream os, Proc p) {
		Set<Var> sharedVars = new TreeSet<>();
		
		sharedVars.addAll(varsValue.procToShared.get(p));
		for (Var v : sharedVars) {
		    os.printf(tabs + "LOCAL_SHARED(%s, con) = %d;\n", v.name,v.iv);
		}
		if(!p.isServer()) {
			os.println(tabs + "LOCAL_SHARED(Scrap, con) = 1;\n");
		}else {
			for (Proc tar : instanceValue.processes) {
				if(tar==p) continue;
				Set<Var> remSharedVars = new TreeSet<>();
				remSharedVars.addAll(varsValue.procToShared.get(tar));
				remSharedVars.addAll(varsValue.procToLocal.get(tar));
				for (Var v : remSharedVars) {
				    os.printf(tabs + "LOCAL_SHARED(tr%s_%s, con) = 0;\n", tar, v.name);
				}
			}
		}//endof if p.isServer
	}
	public void incorporateAddConnections(PrintStream os, Proc p){
		
		for (Proc q : instanceValue.processes) {
			if(p==q) continue;
		    os.printf(tabs + "con.add_connection(%s, thr_ips[%s]);\n", q,q);
		}
		os.println(tabs+ "CONNECT_QP(whoami);\n");
	}
    /*
     * For each process p, all shared variables from processes q(<>p) he can access
     */
    public void incorporateRemAccessVars(PrintStream os, Proc me){
		for (Proc q : instanceValue.processes) {
			if(q==me) continue;
			Set<Var> sharedVars = new TreeSet<>();
			sharedVars.addAll(varsValue.procToShared.get(q));
			for (Var v : sharedVars) {
			    os.printf(tabs + "REMOTE_SHARED(%s, con.at(%d));\n", v.name, q.procId);
			}
		}
		if(!me.isServer()) {
			for (Var v : varsValue.procToLocal.get(me)) {
			    os.printf(tabs + "REMOTE_SHARED(tr%s_%s, con.at(0));\n", me, v.name);
	    	}
		}
   }

   /*
    * Local variables and creation of ConnectionManager
    */
    public void incorporateLocalDecls(PrintStream os, Proc p) {
    	StringBuilder vars = new StringBuilder();
    	for (Var v : varsValue.procToLocal.get(p)) {
    		if (vars.length() > 0) vars.append(", ");
			vars.append(v.name);
    	}

    	os.printf(tabs + "int my_id=%s;\n", p);
    	os.printf(tabs + "int ret=0;\n");
    	os.println(tabs + "string whoami=\"thr\"+my_id;");
    	if(vars.length() > 0) 
    		os.printf(tabs + "uint64_t %s;\n", vars);
    	os.printf(tabs + "rdma::ConnectionManager con(%s, thr_ports[%s]);\n", p, p);
    	   
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

    void emitPerProcTestBody(PrintStream os, Proc p) {
    	for (String s : instanceValue.processContents.get(p.procId)) {
	    	os.println(tabs + sing_tab + s);
    	}
    }
    


/*
 * for server process (or just process 0) to check the output according to 
 * the value all other processes has sent it
 */
public void incorporateTestWitnesses(PrintStream os) {
        boolean firstVar = true;
        boolean firstRemVar = true;
        StringBuilder varFormats = new StringBuilder();
        StringBuilder remote_vars = new StringBuilder();
        for (Proc p : instanceValue.processes) {
            for (Var v : varsValue.procToLocal.get(p)) {
                if (firstVar) {
                    firstVar = false;
                } else {
                    varFormats.append(" << \" \" << ");
                }
                if(p.isServer()) {
	                String vf = String.format("\"tr%s:%s=\" << %s", p.procId, v, v);
	                varFormats.append(vf);                	
                }else {
                	if (firstRemVar) {
                        firstRemVar = false;
                    } else {
                        remote_vars.append(", ");
                    }
	                String vf = String.format("\"tr%s:%s=\" << tr%s_%s", p, v, p, v);
	                varFormats.append(vf);
	                String vars = String.format("%s=tr%s_%s", v, p, v);
	                remote_vars.append(vars);
                }
            }
        }
      	if (instanceValue.outputs.size() == 0) {
    	    os.println(tabs + "if (0) ;/*NO EXPECTED OUTPUTS in IR*/");
    	    return;
      	}
      	os.println(tabs + "uint64_t " + remote_vars + ";");
      	for (int i = 0; i < instanceValue.outputs.size(); i++) {
            String output = instanceValue.outputs.get(i);
            os.printf(tabs + "%sif %s {\n", 
            		(i == 0)? "" : "}else ",  
            		output); //TODO: Make sure output is of struct (tr1_c1==2 && tr1_c2==1)  
            		
            os.println(tabs + sing_tab + "cout << FILE_NAME << \":Success\" << endl");
            os.println(tabs + sing_tab + sing_tab + "<< \"reached: \" << \"" + output + "\" << endl;   ");
        }
        os.println(tabs + "}else {");
        os.printf(tabs + sing_tab + "cerr << \"UNEXPECTED: \" << %s;\n", varFormats.toString());
        os.println(tabs + "}");
}
/*
 * Collect results for one thread wait to receive from others,
 * and check assertion.
 * The rest, each, send their local variables values to the collecting thread.
 * The collecting thread must have local shared-locations for the other threads to rdma-write their values to. 
 */
    public void incorporateTestCollate(PrintStream os, Proc p) {
        
       	if(p.isServer()) return;
		Set<Var> sentVars = new TreeSet<>();
		sentVars.addAll(varsValue.procToShared.get(p));
		sentVars.addAll(varsValue.procToLocal.get(p));
        for (Var v : sentVars) {
            os.printf(tabs + "Scrap = %s;\n", v, v);
            os.printf(tabs + "POST_PUT(con.at(0), whoami, Scrap, tr%s_%s);\n", p, v);
            os.printf(tabs + "POLL_CQ(con.at(0), whoami);\n");
        }
    }
 
    public void  incorporateCppMacros(PrintStream os, String outputName)  {

    	os.printf("#define FILE_NAME \"%s\"\n", outputName);
    	os.printf("#define NUM_THREADS %d\n", this.instanceValue.processes.size());
    }
    
    public void incorporateMain(PrintStream os)  {

        boolean firstProc=true;
        for(Proc p : instanceValue.processes) {
        	os.printf(tabs);
        	if(firstProc) {
        		firstProc=false;
        	}else {
        		os.printf("}else ");
        	}
    		os.printf("if (%s==thr_id){\n", p);
    		os.printf(tabs + sing_tab + "rc = thr%s();\n",p);
    		os.printf(tabs + sing_tab + "std::cout << \"thr%s\";\n", p);
    		
        }
		os.println(tabs + "}");

    }
    public void incorporateStats(PrintStream os) throws java.io.IOException {
//        /* print the execution outputs */
//
//        os.printf("    if %s {\n", checkThread(instanceValue.processes.size(), 0));
//        for (int i = 0; i < instanceValue.outputs.size(); i++) {
//            String output = instanceValue.outputs.get(i);
//            os.println("        fprintf(stderr, \"OBSERVED " + output + ": %ld\\n\", cnt_" + instanceValue.outputs.indexOf(output) + ");\n");
//        }
//	os.printf("        fprintf(stderr, \"unexpected count %%ld\\n\", unexpected_cnt);\n");
//        os.printf("    }\n");
    	os.printf("#if DUMP_VARS\n");
//    	for (Proc p : instanceValue.processes) {
//    	    StringBuilder varFormats = new StringBuilder(), varNames = new StringBuilder();
//    	    for (Var v : varsValue.procToShared.get(p)) {
//    		if (firstVar) {
//    		    firstVar = false;
//    		} else {
//    		    varFormats.append(" ");
//    		}
//    		varNames.append(", ");
    //
//    		String vf = String.format("%s=%%lld", v.name);
//    		varFormats.append(vf);
//    		varNames.append("*"+v.name);
//    	    }
    //
//    	    if (p.procNumber == 0) {
//    		os.printf("  if (app == CLIENT) {\n");
//    	    }
//    	    else {
//    		os.printf("  if (app != CLIENT) {\n");
//    	    }
//    	    os.printf("    printf(\"values: %s\\n\"%s);\n", varFormats.toString(), varNames.toString());
//    	    os.printf("  }\n");
//    	}
    	os.printf("#endif\n");
    	throw new RuntimeException("not implemented yet");
    }

    public void incorporateThreadMethods(PrintStream os)  {
    	for(Proc p : this.instanceValue.processes) {
	    	os.printf("int thr%s(){\n", p);
	        incorporateLocalDecls(os,p);
	    	os.println(); 
			incorporateSharedVars(os,p);
			incorporateAddConnections(os,p);
	    	incorporateRemAccessVars(os,p);
	    	os.println();			
			os.println(tabs + "SILENT_SYNC(\"program start\");");
	    	os.println(tabs + "try{"); 
			emitPerProcTestBody(os,p);
	    	os.println(tabs + "}catch(std::exception &e){");  
	    	os.println(tabs + sing_tab + "cerr << whoami << \" failed because \" << e.what() << endl;");  
	    	os.println(tabs + sing_tab + "ret = 1;");   
	    	os.println(tabs + "}");
	    	os.println(tabs + "sleep(10);");
	    	os.println(tabs + "SILENT_SYNC(\"end of operations\");");
	    	incorporateTestCollate(os,p);
	    	os.println(tabs + "SILENT_SYNC(\"end of collecting results\");");
	    	if(p.isServer()) {
	    		incorporateTestWitnesses(os);
	    	}
	    	os.println(tabs + "SILENT_SYNC(\"end of validating results\");");
	        os.println(tabs + "return ret;");
	    	os.printf("}// endof thr%s()\n", p);
	    	os.println(); os.println(); 
	    }
    }
    //public void macroExpand(PrintStream os, int payload, String outputName, Node n) throws java.io.IOException {
        public void macroExpand(PrintStream os, int payload, String outputName) throws java.io.IOException {
    	
        switch (payload) {
		case 0:
			incorporateCppMacros(os, outputName);
		    break;
		case 2:
			incorporateMain(os);
		    break;
		case 3:
			incorporateThreadMethods(os);
		    break;
//		case 4:
//			incorporateAddConnections(os,p);
//		    break;
//	    case 5:
//	        incorporateLocalDecls(os,p);
//	        break;
//	    case 10:
//	    	incorporateRemAccessVars(os,p);
//	        break;
	    case 11:
	        incorporateOriginalIR(os);
	        break;
		case 13:
		    break;
//		case 14:
//		    incorporateTestWitnesses(os);//incorporate all possible outcomes for thread 0
//		    break;
//		case 15:
//		    incorporateTestCollate(os,p);//incorporate sending results to thread 0
//		    break;
		case 16:
		    incorporateStats(os);
		    break;
	    default:
		    System.out.printf("warning: unrecognized macro $%d\n", payload);
	            os.printf("$%d\n", payload);
	            break;
	    }//end case switch
    }

    public void expandTemplate(File outputDir, String outputName) throws java.io.IOException {
    	for (String fn : Arrays.asList("template.cpp")) {
            File os = new File(outputDir, fn);
            PrintStream ps = new PrintStream(os);

            InputStream in = ConvertToRDMA.class.getClassLoader().getResourceAsStream(fn);
            BufferedReader br = new BufferedReader(new InputStreamReader(in));
            String s;

            while ((s = br.readLine()) != null) {
                String st = s.trim();
                 if (st.startsWith("//$")) {
                    st = st.substring(3, 5);
                    int payload = Integer.parseInt(st);
                    macroExpand(ps, payload, outputName);
                } else {
                    ps.println(s);
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
        //c.generateAuxiliaries(thisOutputDir, outputFileName);
    }


}
// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
