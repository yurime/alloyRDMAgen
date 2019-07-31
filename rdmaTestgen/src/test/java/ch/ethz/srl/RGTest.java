package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class RGTest {
    @Test public void combineActions() throws Err {
        URL url = this.getClass().getResource("/rg.als");
        A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
        res.createModel();

        assert(res.labelToWriters.keySet().size() >= 2);

        boolean containsRG = false;
        for (TGThread thr: res.labelToThreads.values()) {
            boolean hereContainsRG = false;
            TGActionGraph tag = res.po.get(thr);

            for (TGAction a : tag.actions) {
                if (a instanceof TGRemoteGet) {
                    containsRG = true;
                    hereContainsRG = true;
                }
            }
            if (hereContainsRG) {
                for (TGAction a : tag.getHeads()) {
                    int count = 1;
                    while (a.getSuccs().size() > 0) {
                        a = a.getSuccs().get(0);
                        count++;
                    }
                    assertEquals(2, count);
                }

                for (TGAction a : tag.getTails()) {
                    int count = 1;
                    while (a.getPreds().size() > 0) {
                        a = a.getPreds().get(0);
                        count++;
                    }
                    assertEquals(2, count);
                }
            }
        }
        assertTrue(containsRG);
    }
}
