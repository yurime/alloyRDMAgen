// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.util.List;
import java.util.LinkedList;

interface TGAction {
    public String getLabel();
    public List<TGAction> getPreds();
    public List<TGAction> getSuccs();
    public TGThread getD();
    public void setD(TGThread d);
}

class TGActionImpl implements TGAction {
    String label;
    List<TGAction> preds;// TODO: makes sense for all actions connected by po. not here. maybe sw+po? or is it hb?
    List<TGAction> succs;
    TGThread d;

    public TGActionImpl(A4CodeGen.State s,
                        String label) {
        this.label = label;
        this.preds = new LinkedList<>();
        this.succs = new LinkedList<>();
    }

    @Override
    public List<TGAction> getPreds() { return preds; }
    @Override
    public List<TGAction> getSuccs() { return succs; }
    @Override
    public TGThread getD() { return d; }
    @Override
    public void setD(TGThread d) { this.d = d; }

    @Override
    public String getLabel() { return label; }
    @Override
    public String toString() { return label; }
}
