


/**
 * Created by andrei on 28/8/15.
 * Modified by yuri on 9/19.
 */
public class Proc {
    int procId;
    static int serverId=0;

    public Proc(int n) {
        this.procId = n;
    }

    public boolean isServer() {
        return procId==serverId;
    }
    @Override
    public String toString() {
        return procId + "";
    }

    @Override
    public boolean equals(Object other) {
        if (other instanceof Proc)
            return ((Proc)other).procId == procId;
        return false;
    }

    @Override
    public int hashCode() {
        return procId;
    }
}
