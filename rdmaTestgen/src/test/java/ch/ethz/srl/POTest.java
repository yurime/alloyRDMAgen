package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.util.List;
import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

import ch.ethz.srl.util.PseudoTopologicalOrderer;

public class POTest {
    @Test public void correctActionsPerThread() throws Err {
	URL url = this.getClass().getResource("/po.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	TGThread t0 = res.labelToThreads.get("Thr$0");
	assertEquals(2, t0.actions.size());

	TGThread t1 = res.labelToThreads.get("Thr$1");
	assertEquals(2, t1.actions.size());
    }

    @Test public void twoIVsTwoWriters() throws Err {
	URL url = this.getClass().getResource("/po.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	for (TGThread t : res.labelToThreads.values()) {
	    TGActionGraph g = res.po.get(t);
	    assertEquals("1 head", 1, g.getHeads().size());
	    assertEquals("1 tail", 1, g.getTails().size());

	    TGAction hd = g.getHeads().get(0);
	    TGAction tl = g.getTails().get(0);

	    // check the manual hd and tl calc
	    assert(hd.getLabel().startsWith("Init"));
	    assert(tl.getLabel().startsWith("W"));

	    // and also that returned from the pto
	    PseudoTopologicalOrderer<TGAction> pto = new PseudoTopologicalOrderer<>();
	    List<TGAction> l = pto.newList(res.po.get(t), false);
	    assert(l.get(0).getLabel().startsWith("Init"));
	    assert(l.get(1).getLabel().startsWith("W"));
	}
    }


    @Test public void oneThreadThreeActions() throws Err {
	URL url = this.getClass().getResource("/po3.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	int longestThread = 0;
	for (TGThread t : res.labelToThreads.values()) {
	    if (t.actions.size() > longestThread)
	    	longestThread = t.actions.size();

	    TGActionGraph g = res.po.get(t);
	    assertTrue(">= 1 head", g.getHeads().size() >= 1);
	    assertTrue(">= 1 tail", g.getTails().size() >= 1);

	    assert(g.getHeads().stream().anyMatch((hd) -> hd.getLabel().startsWith("Init")));
	    assert(g.getTails().stream().allMatch((tl) -> tl.getLabel().startsWith("W")));

	    // and also that returned from the pto
	    PseudoTopologicalOrderer<TGAction> pto = new PseudoTopologicalOrderer<>();
	    List<TGAction> l = pto.newList(res.po.get(t), false);
	    assertTrue(l.get(0).getLabel().startsWith("Init"));
	    for (int i = 1; i < l.size(); i++)
	    	assertTrue(l.get(i).getLabel().startsWith("W"));
	}
	assertTrue("longestThread at least 3", longestThread >= 3);
   }

}
