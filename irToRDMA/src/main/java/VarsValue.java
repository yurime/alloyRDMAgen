import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

/**
 * Created by andrei on 8/28/15.
 */
public class VarsValue {
    List<Var> localVars, sharedVars;
    Map<Proc, List<Var>> procToLocal, procToShared;
    Map<Var, String> localToRHS;

    public VarsValue() {
        procToLocal = new HashMap<>();
        procToShared = new HashMap<>();
        localToRHS = new HashMap<>();
        localVars = new LinkedList<>();
        sharedVars = new LinkedList<>();
    }

    @Override
    public String toString() {
        StringBuffer result = new StringBuffer();
        result.append("local vars = ");
        for (Var v:localVars) {
            result.append(v + " ");
        }

        result.append("sharedVars = ");
        for (Var v:sharedVars) {
            result.append(v + " ");
        }

        result.append("locals:");
        for (Proc p:procToLocal.keySet()) {
            result.append("proc " + p + " : ");
            for (Var v:procToLocal.get(p)) {
                result.append(v + " ");
            }
        }

        result.append("shared:");

        for (Proc p:procToShared.keySet()) {
            result.append("proc " + p + " : ");
            for (Var v:procToShared.get(p)) {
                result.append(v + " ");
            }
        }

        return result.toString();
    }
}
