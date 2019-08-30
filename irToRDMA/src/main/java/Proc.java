// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-


/**
 * Created by andrei on 8/28/15.
 */
public class Proc {
    int procNumber;

    public Proc(int n) {
        this.procNumber = n;
    }

    @Override
    public String toString() {
        return procNumber + "";
    }

    @Override
    public boolean equals(Object other) {
        if (other instanceof Proc)
            return ((Proc)other).procNumber == procNumber;
        return false;
    }

    @Override
    public int hashCode() {
        return procNumber;
    }
}
