// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.util.*;

import ch.ethz.srl.util.DirectedGraph;

public class TGRDMAactionGraph implements DirectedGraph<TGRDMAaction> {
    List<TGRDMAaction> heads;
    List<TGRDMAaction> tails;
    Collection<TGRDMAaction> actions;

    protected TGRDMAactionGraph(Collection<TGRDMAaction> actions) {
        this.actions = actions;
        heads = new LinkedList<>();
        tails = new LinkedList<>();

        for (TGRDMAaction a : actions) {
            if (a.getSwPreds().size() == 0)
                heads.add(a);
            if (a.getSwSuccs().size() == 0)
                tails.add(a);
        }
    }

    public List<TGRDMAaction> getHeads() { return heads; }
    public List<TGRDMAaction> getTails() { return tails; }
    public List<TGRDMAaction> getPredsOf(TGRDMAaction s) { return s.getSwPreds(); }
    public List<TGRDMAaction> getSuccsOf(TGRDMAaction s) { return s.getSwSuccs(); }
    public int size() { return actions.size(); }
    public Iterator<TGRDMAaction> iterator() { return actions.iterator(); }

    public void remove(TGRDMAaction a) {
        actions.remove(a);
        if (getHeads().contains(a)) getHeads().remove(a);
        if (getTails().contains(a)) getTails().remove(a);

        for (TGRDMAaction p : a.getSwPreds()) {
            p.getSwSuccs().remove(a);
            if (p.getSwSuccs().size() == 0) tails.add(p);
        }

        for (TGRDMAaction p : a.getSwSuccs()) {
            p.getSwPreds().remove(a);
            if (p.getSwPreds().size() == 0) heads.add(p);
        }
    }

    public void replace(TGRDMAaction old, TGRDMAaction n) {
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

        for (TGRDMAaction p : old.getSwPreds()) {
            p.getSwSuccs().remove(old);
            p.getSwSuccs().add(n);
            n.getSwPreds().add(p);
        }

        for (TGRDMAaction p : old.getSwSuccs()) {
            p.getSwPreds().remove(old);
            p.getSwPreds().add(n);
            n.getSwSuccs().add(p);
        }
    }
}
