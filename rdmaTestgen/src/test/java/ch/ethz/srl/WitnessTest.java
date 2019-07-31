package ch.ethz.srl;

import static org.junit.Assert.*;
import org.junit.*;

import java.io.File;
import java.net.URL;

import edu.mit.csail.sdg.alloy4.Err;

public class WitnessTest {
    @Test public void combineActions() throws Err {
	URL url = this.getClass().getResource("/witness.als");
	A4CodeGen res = Driver.getFirstResult(new File(url.getFile()));
	res.createModel();

	assertNotNull(res.witness);
    }
}
