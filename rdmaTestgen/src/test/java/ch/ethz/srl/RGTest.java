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
        TGRDMAactionGraph swtag = res.sw;
        
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
                    int i_count = 1;
                    while (a.getSuccs().size() > 0) {
                        a = a.getSuccs().get(0);
                        i_count++;
                    }
                    assertEquals(1, i_count);
                }
                for (TGAction a : tag.getTails()) {
                    int i_count = 1;
                    while (a.getPreds().size() > 0) {
                        a = a.getPreds().get(0);
                        i_count++;
                    }
                    assertEquals(1, i_count);
                }
                
                for (TGRDMAaction a : swtag.getHeads()) {
                    int a_count = 1;
                    while (a.getSwSuccs().size() > 0) {
                        a = a.getSwSuccs().get(0);
                        a_count++;
                    }
                    assertEquals(4, a_count);
                }

                for (TGRDMAaction a : swtag.getTails()) {
                    int a_count = 1;
                    while (a.getSwPreds().size() > 0) {
                        a = a.getSwPreds().get(0);
                        a_count++;
                    }
                    assertEquals(4, a_count);
                }
            }
        }
        assertTrue(containsRG);
    }
    @Test public void combineActionsRGf() throws Err {
        URL url = this.getClass().getResource("/rgf.als");
        A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
        res.createModel();

        assert(res.labelToWriters.keySet().size() >= 2);

        boolean containsRGf = false;
        TGRDMAactionGraph swtag = res.sw;
        
        for (TGThread thr: res.labelToThreads.values()) {
            boolean hereContainsRGf = false;
            TGActionGraph tag = res.po.get(thr);

            for (TGAction a : tag.actions) {
                if (a instanceof TGFencedRemoteGet) {
                    containsRGf = true;
                    hereContainsRGf = true;
                }
            }
            if (hereContainsRGf) {
            	for (TGAction a : tag.getHeads()) {
                    int i_count = 1;
                    while (a.getSuccs().size() > 0) {
                        a = a.getSuccs().get(0);
                        i_count++;
                    }
                    assertEquals(1, i_count);
                }
                for (TGAction a : tag.getTails()) {
                    int i_count = 1;
                    while (a.getPreds().size() > 0) {
                        a = a.getPreds().get(0);
                        i_count++;
                    }
                    assertEquals(1, i_count);
                }
                
                for (TGRDMAaction a : swtag.getHeads()) {
                    int a_count = 1;
                    while (a.getSwSuccs().size() > 0) {
                        a = a.getSwSuccs().get(0);
                        a_count++;
                    }
                    assertEquals(5, a_count);
                }

                for (TGRDMAaction a : swtag.getTails()) {
                    int a_count = 1;
                    while (a.getSwPreds().size() > 0) {
                        a = a.getSwPreds().get(0);
                        a_count++;
                    }
                    assertEquals(5, a_count);
                }
            }
        }
        assertTrue(containsRGf);
    }
    
}
