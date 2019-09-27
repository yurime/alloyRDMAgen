
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class PutTest {
    @Test public void onePut() throws Err {
		URL url = this.getClass().getResource("put.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(7,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionSx.toString().contains("vsx3"));
		assertTrue(translateValue.actionRp.toString().contains("vrp3"));
		assertTrue(translateValue.actionWpq.toString().contains("vwpq3"));

    }

}
