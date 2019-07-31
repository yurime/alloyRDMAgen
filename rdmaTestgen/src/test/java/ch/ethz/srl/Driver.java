package ch.ethz.srl;

import java.io.File;

import edu.mit.csail.sdg.alloy4.A4Reporter;
import edu.mit.csail.sdg.alloy4.Err;
import edu.mit.csail.sdg.alloy4compiler.ast.Command;
import edu.mit.csail.sdg.alloy4compiler.ast.Module;
import edu.mit.csail.sdg.alloy4compiler.parser.CompUtil;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Options;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Solution;
import edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod;

public class Driver {
    public static A4CodeGen getFirstResult(File arg) throws Err {
        A4Reporter rep = new A4Reporter() {};

	String argName = arg.getAbsolutePath();
	Module world = CompUtil.parseEverything_fromFile(rep, null, argName);
	A4Options options = new A4Options();

	for (Command command: world.getAllCommands()) {
	    A4Solution ans = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), command, options);

	    return new A4CodeGen(ans, "this/");
	}
	return null;
    }
}
