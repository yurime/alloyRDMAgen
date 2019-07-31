package ch.ethz.srl;
//done
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class MemoryLocationTest {
    @Test public void twoMemLocs() throws Err {
	URL url = this.getClass().getResource("/twomemlocs.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(2, res.labelToMemoryLocations.keySet().size());
	assertNotNull(res.labelToMemoryLocations.get("MemoryLocation$0"));
	assertNotNull(res.labelToMemoryLocations.get("MemoryLocation$1"));

	TGMemoryLocation ml0 = res.labelToMemoryLocations.get("MemoryLocation$0");
	assertEquals(ml0.toString(), "X");

	TGMemoryLocation ml1 = res.labelToMemoryLocations.get("MemoryLocation$1");
	assertEquals(ml1.toString(), "Y");

	TGNode n0 = res.labelToNodes.get("Node$0");
	TGNode n1 = res.labelToNodes.get("Node$1");

	assert(n0.memoryLocations.contains(ml0) ||
	       n1.memoryLocations.contains(ml0));
	assert(!(n0.memoryLocations.contains(ml0) &&
		 n1.memoryLocations.contains(ml0)));

	assert(n0.memoryLocations.contains(ml1) ||
	       n1.memoryLocations.contains(ml1));
	assert(!(n0.memoryLocations.contains(ml1) &&
		 n1.memoryLocations.contains(ml1)));
    }

    @Test public void twoMemLocsOneRemote() throws Err {
	URL url = this.getClass().getResource("/twomemlocsoneremote.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(2, res.labelToMemoryLocations.keySet().size());
	assertNotNull(res.labelToMemoryLocations.get("MemoryLocation$0"));
	assertNotNull(res.labelToMemoryLocations.get("MemoryLocation$1"));

	TGMemoryLocation ml0 = res.labelToMemoryLocations.get("MemoryLocation$0");
	assertEquals(ml0.toString(), "X");

	TGMemoryLocation ml1 = res.labelToMemoryLocations.get("MemoryLocation$1");
	assertEquals(ml1.toString(), "Y");

	TGNode n0 = res.labelToNodes.get("Node$0");
	TGNode n1 = res.labelToNodes.get("Node$1");

	assert(n0.memoryLocations.contains(ml0) ||
	       n1.memoryLocations.contains(ml0));
	assert(!(n0.memoryLocations.contains(ml0) &&
		 n1.memoryLocations.contains(ml0)));

	assert(n0.memoryLocations.contains(ml1) ||
	       n1.memoryLocations.contains(ml1));
	assert(!(n0.memoryLocations.contains(ml1) &&
		 n1.memoryLocations.contains(ml1)));
    }
}
