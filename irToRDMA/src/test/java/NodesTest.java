
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class NodesTest {
    @Test public void twoNodes() throws Err {
		URL url = this.getClass().getResource("/twonodes.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(2,translateValue.nodesNumber);
		assertEquals(2,translateValue.thrsNumber);
		assertEquals(4,translateValue.actionsNumber);
		
		assertTrue(translateValue.Nodes.toString().contains("n0"));
		assertTrue(translateValue.Nodes.toString().contains("n1"));
		assertTrue(translateValue.Processes.toString().contains("p0"));
		assertTrue(translateValue.Processes.toString().contains("p1"));

    }

}
