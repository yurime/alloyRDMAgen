
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class RatomicTest {
    @Test public void rga() throws Err {
		URL url = this.getClass().getResource("rga.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(17,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx10"));
		assertTrue(translateValue.actionRWpq.toString().contains("vrwpq10"));
		assertTrue(translateValue.actionWp.toString().contains("vwp10"));

    }
    @Test public void cas() throws Err {
		URL url = this.getClass().getResource("cas.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(16,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx9"));
		assertTrue(translateValue.actionRWpq.toString().contains("vrwpq9"));
		assertTrue(translateValue.actionWp.toString().contains("vwp9"));

    }

}
