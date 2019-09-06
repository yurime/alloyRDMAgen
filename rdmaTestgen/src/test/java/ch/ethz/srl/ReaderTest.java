package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class ReaderTest {
    @Test public void twoReaders() throws Err {
	URL url = this.getClass().getResource("/tworeaders.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	TGMemoryLocation ml0 = res.labelToMemoryLocations.get("MemoryLocation$0");
	assertEquals(ml0.toString(), "X");

	TGMemoryLocation ml1 = res.labelToMemoryLocations.get("MemoryLocation$1");
	assertEquals(ml1.toString(), "Y");

	//TGThread t0 = res.labelToThreads.get("Thr$0");
	//TGThread t1 = res.labelToThreads.get("Thr$1");

	TGReader r0 = res.labelToReaders.get("R$0");
	assert(r0.getRl() == ml0 || r0.getRl() == ml1);
	assertEquals(r0.getRv(), 4);
    }
}
