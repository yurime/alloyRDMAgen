// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-

import org.antlr.v4.runtime.tree.TerminalNode;

/**
 * Created by andrei on 28/8/15.
 * Modified by Yuri 09/2019
 */
public class Var implements Comparable<Var> {
    String name;
    boolean hasInitialValue;
    int iv;

    public Var(String node) {
        this.name = node;
        this.hasInitialValue = false;
    }

    public Var(String node, int iv) {
        this.name = node;
        this.hasInitialValue = true;
        this.iv = iv;
    }

    @Override
    public String toString() {
        return name;
    }

    @Override
    public int compareTo(Var other) {
        return name.compareTo(other.name);
    }
}
