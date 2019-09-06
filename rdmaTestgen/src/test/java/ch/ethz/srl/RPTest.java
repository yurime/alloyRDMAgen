package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class RPTest {
  @Test public void combineActions() throws Err {
	URL url = this.getClass().getResource("/rp.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assert(res.labelToWriters.keySet().size() >= 2);

	boolean won = false;
	for (TGThread thr : res.labelToThreads.values()) {
	    TGActionGraph tag = res.po.get(thr);

	    boolean containsRP = false;
	    for (TGAction a : tag.actions) {
		if (a instanceof TGRemotePut)
		    containsRP = true;
	    }

	    if (!containsRP) continue;

	    assert(tag.getHeads().size() >= 1);
	    assert(tag.getTails().size() >= 1);
	    won = true;
	}
	assertTrue(won);
  }
  
  @Test public void combineActionsPutF() throws Err {
	URL url = this.getClass().getResource("/rpf.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assert(res.labelToWriters.keySet().size() >= 2);

	boolean won = false;
	for (TGThread thr : res.labelToThreads.values()) {
	    TGActionGraph tag = res.po.get(thr);

	    boolean containsRPf = false;
	    for (TGAction a : tag.actions) {
		if (a instanceof TGFencedRemotePut)
		    containsRPf = true;
	    }

	    if (!containsRPf) continue;

	    assert(tag.getHeads().size() >= 1);
	    assert(tag.getTails().size() >= 1);
	    won = true;
	}
	assertTrue(won);
  }
}
