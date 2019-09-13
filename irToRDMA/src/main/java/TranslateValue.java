import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by andrei on 8/30/15.
 */
public class TranslateValue {
    StringBuffer programBuffer, actionR, actionW, actionSx, actionRp, actionRpq, actionWp, actionWpq, actionRWpq,
                 MemoryLocation, Processes, Nodes, InitialValue, actionPollCQ, Integers, Assertion, Items;
    int actionsNumber;
    boolean check_robustness;

    public TranslateValue() {
        this.actionsNumber = 0;
        this.programBuffer = new StringBuffer();
        this.actionR = new StringBuffer();
        this.actionW = new StringBuffer();
        this.actionSx = new StringBuffer();
        this.actionRp = new StringBuffer();
        this.actionRpq = new StringBuffer();
        this.actionWp = new StringBuffer();
        this.actionWpq = new StringBuffer();
        this.actionRWpq = new StringBuffer();
        this.MemoryLocation = new StringBuffer();
        this.Processes = new StringBuffer();
        this.Nodes = new StringBuffer();
        this.InitialValue = new StringBuffer();
        this.actionPollCQ = new StringBuffer();
        this.Integers = new StringBuffer();
        this.Assertion = new StringBuffer();
        this.Items = new StringBuffer();
    }

    /* propertyFlag values
    *   0: ignore assertions and do not add robustness criteria
    *   1: add assertions if any, but do not add robustness criteria if assertions are absent
    *   2: add assertions if any, and add robustness criteria if assertions are absent */
    public String toString(int propertyFlag, String additionalConstraints) {
        StringBuffer result = new StringBuffer();

        result.append("open stability_check\n\n");
        result.append("pred Test [] {\n");
        result.append(" some ");
        if (InitialValue.length() > 0) {
            result.append("disj " + InitialValue.toString() + ": InitialValue,\n");
        }
        if (Integers.length() > 0) {
            result.append("disj " + Integers.toString() + ": Register,\n");
        }
        if (actionR.length() > 0) {
            result.append("disj " + actionR.toString() + ": action R,\n");
        }
        if (actionW.length() > 0) {
            result.append("disj " + actionW.toString() + ": (Write - InitialValue),\n");
        }
        if (actionRp.length() > 0) {
            result.append("disj " + actionRp.toString() + ": action R^p,\n");
        }
        if (actionRpq.length() > 0) {
            result.append("disj " + actionRpq.toString() + ": action R^{p-->q},\n");
        }
        
        if (actionWp.length() > 0) {
            result.append("disj " + actionWp.toString() + ": action W^p,\n");
        }
        if (actionWpq.length() > 0) {
            result.append("disj " + actionWpq.toString() + ": action W^{p-->q},\n");
        }
        if (actionRWpq.length() > 0) {
            result.append("disj " + actionRWpq.toString() + ": action RW^{p-->q},\n");
        }
        if (actionPollCQ.length() > 0) {
            result.append("disj " + actionPollCQ.toString() + ": action poll_cq^{p-->q},\n");
        }
        if (Items.length() > 0) {
            result.append("disj " + Items.toString() + ": Item,\n");
        }
        if (MemoryLocation.length() > 0) {
            result.append("disj " + MemoryLocation.toString() + ": MemoryLocation,\n");
        }

        result.append("disj " + Nodes.toString() + ": Node | \n");
        result.append("disj " + Processes.toString() + ": Thr | \n");

        result.append(" #Item = " + actionsNumber + "\n");

        if (propertyFlag > 0) {
            if (Assertion.length() > 0) {
            /* Check assertion */
                result.append(" and not (" + Assertion.toString() + ")\n");
                this.check_robustness = false;
            } else if (propertyFlag > 1) {
            /* Check robustness */
                result.append(" and Robust.is_robust = 0 \n");
                this.check_robustness = true;
            }
        }

        if (additionalConstraints != null) {
            result.append(" and " + additionalConstraints + "\n");
        }


        result.append(programBuffer);

        result.append("}\n\n");

        result.append("run Test for " + actionsNumber + "\n");


        return result.toString();
    }
}