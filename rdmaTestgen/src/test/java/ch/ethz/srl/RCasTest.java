package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class RCasTest {
    @Test public void combineActions() throws Err {
	URL url = this.getClass().getResource("/rcas.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assert(res.labelToWriters.keySet().size() >= 2);

	boolean won = false;
	for (TGThread thr : res.labelToThreads.values()) {
	    TGActionGraph tag = res.po.get(thr);

	    boolean containsRcas = false;
	    for (TGAction a : tag.actions) {
		if (a instanceof TGRemoteCompareAndSwap)
		    containsRcas = true;
	    }

	    if (!containsRcas) continue;

	    assert(tag.getHeads().size() >= 1);
	    assert(tag.getTails().size() >= 1);
	    won = true;
	}
	assertTrue(won);
    }
}
