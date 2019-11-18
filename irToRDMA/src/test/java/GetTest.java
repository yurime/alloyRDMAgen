
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class GetTest {
    @Test public void oneGet() throws Err {
		URL url = this.getClass().getResource("get.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(8,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx1"));
		assertTrue(translateValue.actionRpq.toString().contains("vrpq1"));
		assertTrue(translateValue.actionWp.toString().contains("vwp1"));

    }

    @Test public void twoGets() throws Err {
		URL url = this.getClass().getResource("twogets.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(16,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx2"));
		assertTrue(translateValue.actionRpq.toString().contains("vrpq2"));
		assertTrue(translateValue.actionWp.toString().contains("vwp2"));
		assertTrue(translateValue.actionSx.toString().contains("vsx3"));
		assertTrue(translateValue.actionRpq.toString().contains("vrpq3"));
		assertTrue(translateValue.actionWp.toString().contains("vwp3"));

    }

}
