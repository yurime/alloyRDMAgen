package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class TwoPutsTest {
  @Test public void combineActions() throws Err {
	URL url = this.getClass().getResource("/twoputs.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assert(res.labelToWriters.keySet().size() >= 2);

	boolean won = false;
    TGRDMAactionGraph swtag = res.sw;
	for (TGThread thr : res.labelToThreads.values()) {
	    TGActionGraph tag = res.po.get(thr);

	    int num_puts = 0;
	    for (TGAction a : tag.actions) {
			if (a instanceof TGRemotePut)
			    num_puts++;
		    }

	    if (0 == num_puts) continue;

	    assert(tag.getHeads().size() >= 1);
	    assert(tag.getTails().size() >= 1);
	    assert(swtag.getHeads().size() >= 1);
	    assert(swtag.getTails().size() >= 1);
        int a_count = 1;
        for (TGRDMAaction a : swtag.getHeads()) {
            while (a.getSwSuccs().size() > 0) {
                a_count = a_count + a.getSwSuccs().size();
                a = a.getSwSuccs().get(0);
            }
        }
        assert(6 < a_count);// 6 for two puts, + (probably 1) for sw-order
        a_count = 1;
        for (TGRDMAaction a : swtag.getTails()) {
            while (a.getSwPreds().size() > 0) {
                a_count = a_count + a.getSwPreds().size();
                a = a.getSwPreds().get(0);
            }
        }
        assert(3 < a_count);// 3 for last put, + (probably 1) for sw-order 
	    won = true;
	    num_puts=0;
	}
	assertTrue(won);
  }
  
}
