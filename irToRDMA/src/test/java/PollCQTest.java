
import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class PollCQTest {
    @Test public void pollCQ() throws Err {
		URL url = this.getClass().getResource("pollcq.ir");
		TranslateValue translateValue = 
			Driver.getResult(new File(url.getFile()));
		assertEquals(12,translateValue.actionsNumber);
		
		assertTrue(translateValue.actionPollCQ.toString().contains("pcq4"));

    }

}
