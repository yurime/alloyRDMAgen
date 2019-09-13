package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.util.List;
import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

import ch.ethz.srl.util.DirectedGraph;
import ch.ethz.srl.util.PseudoTopologicalOrderer;

public class PollCqTest {
    @Test public void combineActions() throws Err {
	URL url = this.getClass().getResource("/pollCq.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assert(res.labelToWriters.keySet().size() >= 2);

	TGThread thr0 = res.labelToThreads.get("Thr$0");
	TGActionGraph tag = res.po.get(thr0);

	boolean containsPollCq = false;
	for (TGAction a : tag.actions) {
	    if (a instanceof TGPollCQ)
		containsPollCq = true;
	}
	assertTrue(containsPollCq);
    }
}
