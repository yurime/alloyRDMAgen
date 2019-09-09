// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.Writer;

import edu.mit.csail.sdg.alloy4.A4Reporter;
import edu.mit.csail.sdg.alloy4.Err;
import edu.mit.csail.sdg.alloy4.ErrorWarning;
import edu.mit.csail.sdg.alloy4compiler.ast.Command;
import edu.mit.csail.sdg.alloy4compiler.ast.Expr;
import edu.mit.csail.sdg.alloy4compiler.ast.ExprCall;
import edu.mit.csail.sdg.alloy4compiler.ast.ExprUnary;
import edu.mit.csail.sdg.alloy4compiler.ast.ExprBinary;
import edu.mit.csail.sdg.alloy4compiler.ast.Func;
import edu.mit.csail.sdg.alloy4compiler.ast.Module;
import edu.mit.csail.sdg.alloy4compiler.parser.CompUtil;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Options;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Solution;
import edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod;
import edu.mit.csail.sdg.alloy4viz.VizGUI;

// to run: java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --first-solution N --limit M ../alloy/generate_litmus_time.als
// or: java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --count ../alloy/generate_litmus_time.als

public class Main {
    public static String DEFAULT_OUTPUT_DIR = "output";
    public static int DEFAULT_SCOPE = 7;

    public static void main(String[] args) throws Err, java.io.IOException {
        A4Reporter rep = new A4Reporter() {};
        int firstSolution = 0;
        int limit = -1;
        boolean countMode = false;
        String outputDirName = null;
        File outputDir = null;
        int scope = DEFAULT_SCOPE;
        int solutionCount = 0;
        int procs = 1;
        long startTime = System.currentTimeMillis();
        long lastReport = startTime;

        String timeStamp = new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(java.util.Calendar.getInstance().getTime());
        System.out.printf("started execution at timestamp %s\n", timeStamp);

        for(int i = 0; i < args.length; i++) {
            String arg = args[i];
            if (arg.equals("--count")) {
                countMode = true;
                continue;
            }
            if (arg.equals("--first-solution")) {
                firstSolution = Integer.parseInt(args[++i]);
                continue;
            }
            if (arg.equals("--limit")) {
                limit = Integer.parseInt(args[++i]);
                continue;
            }
            if (arg.equals("--scope") || arg.equals("-s")) {
                scope = Integer.parseInt(args[++i]);
                continue;
            }
            if (arg.equals("-d")) {
                outputDirName = args[++i];
                continue;
            }
            if (arg.equals("-p")) {
                procs = Integer.parseInt(args[++i]);
                continue;
            }
            
            if (outputDirName == null)
                outputDirName = DEFAULT_OUTPUT_DIR;

            outputDir = new File(outputDirName);
            if (!outputDir.exists()) {
                outputDir.mkdir();
                if (!outputDir.exists()) {
                    System.err.printf("could not create output directory %s; aborting.\n",
                                      outputDirName);
                    System.exit(1);
                }
            }
            if (!outputDir.isDirectory()) {
                System.err.printf("output directory %s is not directory; aborting.\n",
                                  outputDirName);
                System.exit(1);
            }

            String model = arg;

            String modelStem = new File(arg).getName();
            if (modelStem.indexOf(".") > 0)
                modelStem = modelStem.substring(0, modelStem.lastIndexOf("."));

            Module world = CompUtil.parseEverything_fromFile(rep, null, model);
            A4Options options = new A4Options();

            options.solver = A4Options.SatSolver.SAT4J; //A4Options.SatSolver.MiniSatJNI;

            // ... is now straightforward to replace show with something
            // that we generate programmatically
            ExprCall show = (ExprCall)(((ExprUnary)(world.parseOneExpressionFromString("show"))).sub);
            Expr q0 = show.fun.getBody().and(world.getAllReachableFacts());

            ExprCall oneThread = (ExprCall)(((ExprUnary)(world.parseOneExpressionFromString("oneThread"))).sub);
            ExprCall twoThreads = (ExprCall)(((ExprUnary)(world.parseOneExpressionFromString("twoThreads"))).sub);
            Expr query = null;
            if (procs == 1)
                query = oneThread.fun.getBody().and(q0);
            else if (procs == 2)
                query = twoThreads.fun.getBody().and(q0);
            else {
                System.err.printf("procs must be either 1 or 2");
                System.exit(1);
            }

            Command command = new Command(false, scope, -1, -1, query);
            for (A4Solution ans = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), command, options); ans.satisfiable(); ans = ans.next()) {
                solutionCount++;
                if (limit > 0 && solutionCount > firstSolution+limit) break;

                if (countMode) {
                    if (solutionCount % 1000 == 0) {
                        long now = System.currentTimeMillis();
                        if ((solutionCount % 10000 == 0) || ((now - lastReport) > 100000)) {
                            lastReport = now;
                            System.out.printf("interim count: %d (cumulative rate: %.2f ms/instance)\n", solutionCount, (now-startTime) / (float)(solutionCount - firstSolution - 1));
                        }
                    }
                    continue;
                }

                if (solutionCount > firstSolution) {
                    //A4CodeGen a4cg = new A4CodeGen(ans, "this/");// generation from juint tests
                	A4CodeGen a4cg = new A4CodeGen(ans, "t/b/e/sw/a/");
                    PrintWriter pw = null;
                    try {
                        if (outputDir == null)
                            pw = new PrintWriter(System.out);
                        else {
                            File of = new File(outputDir,
                                               String.format("%s%06d.ir", modelStem, solutionCount));
                            pw = new PrintWriter(of);
                        }
                        a4cg.emitCode(pw, solutionCount);
                        pw.close();
                    } catch (FileNotFoundException e) {
                        System.err.println("could not open output file");
                        System.exit(-1);
                    }
                }
            }
            if (countMode) {
                System.out.printf("counted %d solutions\n", solutionCount);
            }
        }

        long now = System.currentTimeMillis();
        String nowTimeStamp = new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(java.util.Calendar.getInstance().getTime());
        System.out.printf("finished execution at time %s; elapsed time %.2f s (%.2f ms/instance)\n", nowTimeStamp, (now - startTime)/1000.0, (now - startTime) / (float)(solutionCount - firstSolution - 1));
    }
}
