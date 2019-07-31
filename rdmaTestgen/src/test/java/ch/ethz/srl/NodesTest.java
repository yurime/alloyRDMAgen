package ch.ethz.srl;
//done
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class NodesTest {
    @Test public void twoNodes() throws Err {
	URL url = this.getClass().getResource("/twonodes.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(2, res.labelToNodes.keySet().size());
	assertNotNull(res.labelToNodes.get("Node$0"));
	assertNotNull(res.labelToNodes.get("Node$1"));
    }

    @Test public void noNodes() throws Err {
	URL url = this.getClass().getResource("/nonodes.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();
	assertEquals(0, res.labelToNodes.keySet().size());
    }
}
