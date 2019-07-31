package ch.ethz.srl;
//done
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class ThreadsTest {
    @Test public void twoThreads() throws Err {
	URL url = this.getClass().getResource("/twothreads.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(2, res.labelToThreads.keySet().size());
	assertNotNull(res.labelToThreads.get("Thr$0"));
	assertNotNull(res.labelToThreads.get("Thr$1"));
    }

    @Test public void noThreads() throws Err {
	URL url = this.getClass().getResource("/nothreads.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(0, res.labelToThreads.keySet().size());
    }
}
