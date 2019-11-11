package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class WriterTest {
    @Test public void twoWriters() throws Err {
	URL url = this.getClass().getResource("/twowriters.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	TGMemoryLocation ml0 = res.labelToMemoryLocations.get("MemoryLocation$0");
	assertEquals(ml0.toString(), "X");

	TGMemoryLocation ml1 = res.labelToMemoryLocations.get("MemoryLocation$1");
	assertEquals(ml1.toString(), "Y");

	//TGThread t0 = res.labelToThreads.get("Thr$0");
	//TGThread t1 = res.labelToThreads.get("Thr$1");

	TGWriter w0 = res.labelToWriters.get("Writer$0");
	assert(w0.getLoc() == ml0 || w0.getLoc() == ml1);
	assertEquals(w0.getWv(), 4);
    }

    @Test public void twoWritersInitialValue() throws Err {
	URL url = this.getClass().getResource("/twowriters_initialvalues.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	TGMemoryLocation ml0 = res.labelToMemoryLocations.get("MemoryLocation$0");
	TGMemoryLocation ml1 = res.labelToMemoryLocations.get("MemoryLocation$1");

	assertEquals(ml0.initialValue, new Integer(4));
	assertEquals(ml1.initialValue, new Integer(4));

	TGThread t0 = res.labelToThreads.get("Thr$0");
	TGThread t1 = res.labelToThreads.get("Thr$1");

	TGWriter w0 = res.labelToWriters.get("Init$0");
	assert(t0.actions.contains(w0) || t1.actions.contains(w0));
    }
}
