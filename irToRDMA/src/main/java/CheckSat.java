
import java.io.File;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;

import edu.mit.csail.sdg.alloy4.A4Reporter;
import edu.mit.csail.sdg.alloy4.Err;
import edu.mit.csail.sdg.alloy4.XMLNode;
import edu.mit.csail.sdg.alloy4compiler.ast.*;
import edu.mit.csail.sdg.alloy4compiler.parser.CompUtil;
import edu.mit.csail.sdg.alloy4compiler.translator.*;
import edu.mit.csail.sdg.alloy4graph.GraphViewer;
import edu.mit.csail.sdg.alloy4viz.AlloyInstance;
import edu.mit.csail.sdg.alloy4viz.AlloyModel;
import edu.mit.csail.sdg.alloy4viz.StaticInstanceReader;
import edu.mit.csail.sdg.alloy4viz.VizGUI;

public class CheckSat {

    public static String READER_LABEL() { return FILE_NAME() + ("Reader"); }
    public static String READ_LABEL() { return FILE_NAME() + ("R"); }

    public static String RV_FIELD_LABEL() { return "rV"; }

    public static String REG_FIELD_LABEL() { return "reg"; }
    public static String FILE_NAME() {return "stability_check/"; }

    public static HashMap<String, String> actionToSkolem = new HashMap<>();
    public static HashMap<String, Integer> actionToValue = new HashMap<>();
    public static HashMap<String, String> actionToRegister = new HashMap<>();

    public static void getTokens(A4Solution sol) {
        for (ExprVar sk: sol.getAllSkolems()) {
            try {
                A4TupleSet l = (A4TupleSet)sol.eval((Expr) sk);
                actionToSkolem.put(l.iterator().next().toString(), sk.label);
            } catch (Err err) {
                err.printStackTrace();
            }
        }
    }

    public static void getReaderValues(A4Solution sol) {
        for (Sig s : sol.getAllReachableSigs()) {
            if (s.label.equals(READER_LABEL())) {
                for (Sig.Field f : s.getFields()) {
                    if (f.label.equals(RV_FIELD_LABEL())) {
                        A4TupleSet val4Reader = sol.eval(f);
                        for (A4Tuple v4r : val4Reader) {
                            int v = Integer.parseInt(v4r.atom(1));
                            actionToValue.put(v4r.atom(0), v);
                        }
                    }
                }
            }
        }
    }

    public static void getRegisters(A4Solution sol) {
        for (Sig s : sol.getAllReachableSigs()) {
            if (s.label.equals(READ_LABEL())) {
                for (Sig.Field f : s.getFields()) {
                    if (f.label.equals(REG_FIELD_LABEL())) {
                        A4TupleSet val4Reader = sol.eval(f);
                        for (A4Tuple v4r : val4Reader) {
                            actionToRegister.put(v4r.atom(0), v4r.atom(1));
                        }
                    }
                }
            }
        }
    }

    public static String extractActionName(String skolem) {
        String predicateName = "$Test_";
        return skolem.substring(skolem.lastIndexOf(predicateName) + predicateName.length());
    }


    static HashMap<String, Integer> parseReaders(A4Solution solution) {
        //System.out.println(solution);
        getTokens(solution);
        getReaderValues(solution);
        getRegisters(solution);
        HashMap<String, Integer> result = new HashMap<>();

        for (Sig s : solution.getAllReachableSigs()) {

            if (s.label.equals(READ_LABEL())) {
                A4TupleSet readers = solution.eval(s);
                for (A4Tuple reader : readers) {
                    String label = reader.atom(0);
                    /* Print the labels of all the local readers */
                    result.put(extractActionName(actionToSkolem.get(actionToRegister.get(label))), actionToValue.get(label));

                }
            }
        }
        return result;

    }

    public static HashMap<String, Integer> getLocals(String inputFileName) throws Exception {
        A4Reporter rep = new A4Reporter();
        File tmpAls = new File(inputFileName);
        {
            Module world = CompUtil.parseEverything_fromFile(rep, null, inputFileName);
            A4Options opt = new A4Options();
            opt.originalFilename = tmpAls.getAbsolutePath();
            opt.solver = A4Options.SatSolver.SAT4J;
            Command cmd = world.getAllCommands().get(0);
            A4Solution sol = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), cmd, opt);
            if (sol.satisfiable()) {
                /* Get values for the local variables */
                return parseReaders(sol);
            } else {
                return null;
            }
        }
    }

    public static boolean isSat(String inputFileName) throws Exception {
        A4Reporter rep = new A4Reporter();
        File tmpAls = new File(inputFileName);
        {
            Module world = CompUtil.parseEverything_fromFile(rep, null, inputFileName);
            A4Options opt = new A4Options();
            opt.originalFilename = tmpAls.getAbsolutePath();
            opt.solver = A4Options.SatSolver.SAT4J;
            Command cmd = world.getAllCommands().get(0);
            A4Solution sol = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), cmd, opt);
            if (sol.satisfiable()) {
                sol.writeXML("sol.xml");
                AlloyInstance inst = StaticInstanceReader.parseInstance(new File("sol.xml"));
                VizGUI viz = new VizGUI(false, "", null);
                viz.loadXML("sol.xml", false);
                viz.loadThemeFile("net_theme.thm");
                viz.getViewer().alloySaveAsPNG("image.png", 1, 1, 1);
            }
            return sol.satisfiable();
        }
    }
}
