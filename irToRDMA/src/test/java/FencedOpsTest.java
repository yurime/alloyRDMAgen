
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class FencedOpsTest {

    
    @Test public void fencedGet() throws Err {
		URL url = this.getClass().getResource("getF.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(17,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx2"));
		assertTrue(translateValue.actionRpq.toString().contains("vrpq2"));
		assertTrue(translateValue.actionWp.toString().contains("vwp2"));
		assertTrue(translateValue.actionSx.toString().contains("vsx3"));
		assertTrue(translateValue.actionNf.toString().contains("vnf3"));
		assertTrue(translateValue.actionRpq.toString().contains("vrpq3"));
		assertTrue(translateValue.actionWp.toString().contains("vwp3"));

    }
    @Test public void fencedPut() throws Err {
		URL url = this.getClass().getResource("putF.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(17,translateValue.actionsNumber);

		assertTrue(translateValue.actionSx.toString().contains("vsx7"));
		assertTrue(translateValue.actionNf.toString().contains("vnf7"));
		assertTrue(translateValue.actionRp.toString().contains("vrp7"));
		assertTrue(translateValue.actionWpq.toString().contains("vwpq7"));

    }
    
    @Test public void fencedRga() throws Err {
		URL url = this.getClass().getResource("rgaF.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(18,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx10"));
		assertTrue(translateValue.actionNf.toString().contains("vnf10"));
		assertTrue(translateValue.actionRWpq.toString().contains("vrwpq10"));
		assertTrue(translateValue.actionWp.toString().contains("vwp10"));

    }
    
    @Test public void fencedCas() throws Err {
		URL url = this.getClass().getResource("casF.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(17,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx9"));
		assertTrue(translateValue.actionNf.toString().contains("vnf9"));
		assertTrue(translateValue.actionRWpq.toString().contains("vrwpq9"));
		assertTrue(translateValue.actionWp.toString().contains("vwp9"));

    }
    
}
