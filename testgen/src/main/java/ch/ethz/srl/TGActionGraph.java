// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.util.*;

import ch.ethz.srl.util.DirectedGraph;

public class TGActionGraph implements DirectedGraph<TGAction> {
    List<TGAction> heads;
    List<TGAction> tails;
    Collection<TGAction> actions;

    protected TGActionGraph(Collection<TGAction> actions) {
        this.actions = actions;
        heads = new LinkedList<>();
        tails = new LinkedList<>();

        for (TGAction a : actions) {
            if (a.getPreds().size() == 0)
                heads.add(a);
            if (a.getSuccs().size() == 0)
                tails.add(a);
        }
    }

    public List<TGAction> getHeads() { return heads; }
    public List<TGAction> getTails() { return tails; }
    public List<TGAction> getPredsOf(TGAction s) { return s.getPreds(); }
    public List<TGAction> getSuccsOf(TGAction s) { return s.getSuccs(); }
    public int size() { return actions.size(); }
    public Iterator<TGAction> iterator() { return actions.iterator(); }

    public void remove(TGAction a) {
        actions.remove(a);
        if (getHeads().contains(a)) getHeads().remove(a);
        if (getTails().contains(a)) getTails().remove(a);

        for (TGAction p : a.getPreds()) {
            p.getSuccs().remove(a);
            if (p.getSuccs().size() == 0) tails.add(p);
        }

        for (TGAction p : a.getSuccs()) {
            p.getPreds().remove(a);
            if (p.getPreds().size() == 0) heads.add(p);
        }
    }

    public void replace(TGAction old, TGAction n) {
        actions.remove(old);
        actions.add(n);

        if (getHeads().contains(old)) {
            getHeads().remove(old);
            getHeads().add(n);
        }
        if (getTails().contains(old)) {
            getTails().remove(old);
            getTails().add(n);
        }

        for (TGAction p : old.getPreds()) {
            p.getSuccs().remove(old);
            p.getSuccs().add(n);
            n.getPreds().add(p);
        }

        for (TGAction p : old.getSuccs()) {
            p.getPreds().remove(old);
            p.getPreds().add(n);
            n.getSuccs().add(p);
        }
    }
}
