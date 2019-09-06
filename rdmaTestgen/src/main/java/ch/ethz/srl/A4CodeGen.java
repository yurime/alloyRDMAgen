// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import edu.mit.csail.sdg.alloy4compiler.ast.Sig;
import edu.mit.csail.sdg.alloy4compiler.ast.Sig.Field;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Solution;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Tuple;
import edu.mit.csail.sdg.alloy4compiler.translator.A4TupleSet;

import java.util.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import java.io.PrintWriter;

import ch.ethz.srl.A4CodeGen.State;
import ch.ethz.srl.util.PseudoTopologicalOrderer;

class TGMemoryLocation {
    A4CodeGen.State s;
    String label; // alloy name
    String prettyLabel;
    Integer initialValue;

    public TGMemoryLocation(A4CodeGen.State s,
                            String label) {
        this.s = s;
        this.label = label;
    }

    @Override
    public String toString() {
        if (prettyLabel == null) {
            if (s.memLocCount < SHARED_VAR_NAMES.length())
                prettyLabel = Character.toString(SHARED_VAR_NAMES.charAt(s.memLocCount++));

            if (prettyLabel == null)
                prettyLabel = label;
        }
        return prettyLabel;
    }

    public static final String SHARED_VAR_NAMES = "XYZWVU";
}

class TGRegister {
    A4CodeGen.State s;
    String label; // alloy name
    String prettyLabel;
    Integer initialValue;

    public TGRegister(A4CodeGen.State s,
                      String label) {
        this.s = s;
        this.label = label;
    }

    @Override
    public String toString() {
        if (prettyLabel == null) {
            if (s.registerCount < LOCAL_VAR_NAMES.length())
                prettyLabel = Character.toString(LOCAL_VAR_NAMES.charAt(s.registerCount++));

            if (prettyLabel == null)
                prettyLabel = label;
        }
        return prettyLabel;
    }

    public static final String LOCAL_VAR_NAMES = "abcdef";
}

interface TGWriter extends TGAction {
    public int getWv();
    public void setWv(int wV);
    public TGMemoryLocation getWl();
    public void setWl(TGMemoryLocation wl);
    public boolean isLocalWrite();
}

class TGWriterImpl extends TGActionImpl implements TGWriter {
    private TGMemoryLocation wl;
    private boolean isLocalWrite;//TODO: should add isNICWrite/isCPUWrite?
    int wV;

    public TGWriterImpl(A4CodeGen.State s,
                    String label, TGMemoryLocation wl, int wV) {
        super(s, label); setWl(wl); this.wV = wV;
    }

    public TGWriterImpl(A4CodeGen.State s,
                    String label, TGMemoryLocation wl, int wV, boolean isLocalWrite) {
        this(s, label, wl, wV);
        this.isLocalWrite = isLocalWrite;
    }

    @Override public String toString() {
        return String.format("store %s = %d", wl, wV);
    }

    public int getWv() { return wV; }
    public void setWv(int wV) {
        this.wV = wV;
    }

    public TGMemoryLocation getWl() { return wl; }
    public void setWl(TGMemoryLocation wl) {
        this.wl = wl;
    }

    public boolean isLocalWrite() { return isLocalWrite; }
}

class TGRDMAWriterImpl extends TGWriterImpl implements TGRDMAaction {
    List<TGRDMAaction> swpreds;
    List<TGRDMAaction> swsuccs;

    public TGRDMAWriterImpl(A4CodeGen.State s,
            String label, TGMemoryLocation wl, int wV)  {
    	super(s,label,wl,wV);
        this.swpreds = new LinkedList<>();
        this.swsuccs = new LinkedList<>();
    }

    @Override
    public List<TGRDMAaction> getSwPreds() { return swpreds; }
    @Override
    public List<TGRDMAaction> getSwSuccs() { return swsuccs; }

}
class TGRDMAReaderImpl extends TGReaderImpl implements TGRDMAaction {
    List<TGRDMAaction> swpreds;
    List<TGRDMAaction> swsuccs;

    public TGRDMAReaderImpl(A4CodeGen.State s,
            String label, TGMemoryLocation rl, int rV) {
    	super(s,label,rl,rV);
        this.swpreds = new LinkedList<>();
        this.swsuccs = new LinkedList<>();
    }

    @Override
    public List<TGRDMAaction> getSwPreds() { return swpreds; }
    @Override
    public List<TGRDMAaction> getSwSuccs() { return swsuccs; }

}
class TGInitialValue extends TGWriterImpl {
    public TGInitialValue(A4CodeGen.State s,
                          String label, TGMemoryLocation wl, int wV) {
        super(s, label, wl, wV);
    }
}

abstract class TGInstruction extends TGActionImpl {
    public TGInstruction(A4CodeGen.State s, String label) {
        super(s, label);
    }

    
	public static void assertValidInstrActs(TGSX sx, TGRDMAaction first_nic_act, TGRDMAaction second_nic_act, Map<TGAction, TGThread> actionToThread) {
		assert first_nic_act != null && second_nic_act != null && sx != null ;
		assert sx.getSwSuccs().size() == 1 && sx.getSwSuccs().contains(first_nic_act);
		assert first_nic_act.getSwSuccs().size() == 1 && first_nic_act.getSwSuccs().contains(second_nic_act);
		assert first_nic_act.getSwPreds().size() >= 1 && first_nic_act.getSwPreds().contains(sx);
		assert second_nic_act.getSwPreds().size() >= 1 && second_nic_act.getSwPreds().contains(first_nic_act);
		assert actionToThread.get(sx) != null;
		assert actionToThread.get(sx).label == actionToThread.get(second_nic_act).label;
		assert actionToThread.get(second_nic_act).label == actionToThread.get(first_nic_act).label;
		
	}
	public static void assertValidFencedInstrActs(TGSX sx, TGnF nf, TGRDMAaction first_nic_act, TGRDMAaction second_nic_act, Map<TGAction, TGThread> actionToThread) {
		assert first_nic_act != null && second_nic_act != null && sx != null && nf !=null;
		assert sx.getSwSuccs().size() == 1 && sx.getSwSuccs().contains(nf);
		assert nf.getSwSuccs().size() == 1 && nf.getSwSuccs().contains(first_nic_act);
		assert first_nic_act.getSwSuccs().size() == 1 && first_nic_act.getSwSuccs().contains(second_nic_act);

		assert second_nic_act.getSwPreds().size() >= 1 && second_nic_act.getSwPreds().contains(first_nic_act);
		assert first_nic_act.getSwPreds().size() >= 1 && first_nic_act.getSwPreds().contains(nf);
		assert nf.getSwPreds().size() >= 1 && nf.getSwPreds().contains(sx);
		assert actionToThread.get(sx) != null;
		assert actionToThread.get(sx).label == actionToThread.get(nf).label;
		assert actionToThread.get(nf).label == actionToThread.get(second_nic_act).label;
		assert actionToThread.get(second_nic_act).label == actionToThread.get(first_nic_act).label;		
	}
}

interface TGReader extends TGAction {
    public int getRv();
    public void setRv(int rV);
    public TGMemoryLocation getRl();
    public void setRl(TGMemoryLocation rl);
}

class TGReaderImpl extends TGActionImpl implements TGReader {
    private TGMemoryLocation rl;
    int rV;

    public TGReaderImpl(A4CodeGen.State s,
                    String label, TGMemoryLocation rl, int rV) {
        super(s, label); setRl(rl); this.rV = rV;
    }

    public int getRv() { return rV; }
    public void setRv(int rV) { this.rV = rV; }
    public TGMemoryLocation getRl() { return rl; }
    public void setRl(TGMemoryLocation rl) { this.rl = rl; }
}

class TGnRWpq extends TGRDMAWriterImpl implements TGRDMAaction, TGReader, TGWriter {
    private TGMemoryLocation rl;
    int rV;

    public TGnRWpq(A4CodeGen.State s, String label,
                             TGMemoryLocation rl, int rV,
                             TGMemoryLocation wl, int wV) {
        super(s, label, wl, wV);
        this.rV=rV;
        //wl=rl
    }

    public int getRv() { return rV; }
    public void setRv(int rV) { this.rV = rV; }
    //public int geWv() { return wV; } // inherited from TGWriterImpl 
    //public void setWv(int wV) { this.wV = wV; }
    public TGMemoryLocation getRl() { return rl; }
    public void setRl(TGMemoryLocation rl) { this.rl = rl; }
}

class TGReadpq extends TGRDMAReaderImpl implements TGRDMAaction {
    public TGReadpq(A4CodeGen.State s, String label,
                        TGMemoryLocation rl, int rV) {
        super(s, label, rl, rV);
    }
}

class TGReadp extends TGRDMAReaderImpl implements TGRDMAaction {
    public TGReadp(A4CodeGen.State s, String label,
                        TGMemoryLocation rl, int rV) {
        super(s, label, rl, rV);
    }
}

/* local read */
class TGRead extends TGReaderImpl implements TGAction {
    public TGRead(A4CodeGen.State s, String label,
                  TGMemoryLocation rl, int rV, TGRegister reg) {
        super(s, label, rl, rV);
        this.reg = reg;
    }

    TGRegister reg;

    @Override public String toString() {
        return String.format("load %s = %s",
                             reg==null ? "?" : reg.toString(), getRl());
    }
}

class TGWritepq extends TGRDMAWriterImpl implements TGWriter, TGRDMAaction {
    public TGWritepq(A4CodeGen.State s, String label,
                         TGMemoryLocation wl, int wV) {
        super(s, label, wl, wV);
    }
}

class TGWritep extends TGRDMAWriterImpl implements TGWriter, TGRDMAaction {
    public TGWritep(A4CodeGen.State s, String label,
                         TGMemoryLocation wl, int wV) {
        super(s, label, wl, wV);
    }
}
class TGWrite extends TGWriterImpl implements TGWriter, TGAction {
    public TGWrite(A4CodeGen.State s, String label,
                         TGMemoryLocation wl, int wV) {
        super(s, label, wl, wV);
    }
}

class TGSX extends TGRDMAactionImpl implements TGRDMAaction {
    public TGSX(A4CodeGen.State s, String label) {
        super(s, label);
    }
}

class TGnF extends TGRDMAactionImpl implements TGRDMAaction {
    public TGnF(A4CodeGen.State s, String label) {
        super(s, label);
    }
}


class TGRemotePut extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGReadp rp;
    TGWritepq remoteWrite;

    public TGRemotePut(A4CodeGen.State s,
                       String label,
                       Set<TGAction> actions,
                       TGSX     sx,
                       TGReadp rp,
                       TGWritepq wpq) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.rp = rp;
        this.remoteWrite = wpq;
    }

    @Override
    public String toString() {
        return String.format("put (%s,%d,%s)", remoteWrite.getWl(), getD().id, rp.getRl());
    }
    public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {

        Set<TGAction> rpActions = new HashSet<>();

        // find the remote write, external read
        TGReadp er = null;
        TGWritepq rw = null;
        TGSX sx = null;
        for (TGAction a : actions) {
            if (a instanceof TGWritepq) {
                rw = (TGWritepq)a;
                rpActions.add(rw);
            } else if (a instanceof TGReadp) {
                er = (TGReadp)a;
                rpActions.add(er);
            }else if (a instanceof TGSX) {
                sx = (TGSX)a;
                rpActions.add(sx);
            }
        }

        if (rw == null || er == null || sx == null) throw new RuntimeException("Error constructing TGRemotePut: rr or ew or sx are null");

        //assert rw.getD() == er.getD();// TODO: not clear to me. Only the origin is equal for my model, should Action::getO() be added? maybe ew is p and in the other model p->q

        assertValidInstrActs(sx,er,rw, actionToThread); 
        assert sx.getD() == er.getD();

        TGThread thr = actionToThread.get(sx);
        TGActionGraph tag = po.get(thr);

        TGRemotePut putf = new TGRemotePut(state, label, rpActions,
                                         sx, er, rw);
        putf.setD(rw.getD());

        tag.remove(er);
        tag.remove(rw);
        tag.replace(sx, putf);

        return putf;
	}
}

class TGRemoteGet extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGReadpq rpq;
    TGWritep wp;

    public TGRemoteGet(A4CodeGen.State s,
                       String label,
                       Set<TGAction> actions,
                       TGSX     sx,
                       TGReadpq rpq,
                       TGWritep wp) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.rpq = rpq;
        this.wp = wp;
    }

    @Override
    public String toString() {
        return String.format("%s = get (%s,%s)", wp.getWl(), rpq.getRl(), rpq.getD().id);
    }
    
	public static TGInstruction Compose(State state, String label, Set<TGAction> actions, Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po){
        Set<TGAction> rgActions = new HashSet<>();

        // find the remote read, external write, and sx
        TGWritep ew = null;
        TGReadpq rr = null;
        TGSX sx = null;
        for (TGAction a : actions) {
            if (a instanceof TGWritep) {
                ew = (TGWritep)a;
                rgActions.add(ew);
            } else if (a instanceof TGReadpq) {
                rr = (TGReadpq)a;
                rgActions.add(rr);
            }else if (a instanceof TGSX) {
                sx = (TGSX)a;
                rgActions.add(sx);
            }
        }

        if (rr == null || ew == null || sx == null) throw new RuntimeException("Error constructing TGRemoteGet: rr or ew or sx are null");

        assertValidInstrActs(sx, rr, ew, actionToThread);
		assert sx.getD() == ew.getD();
        //assert rr.getD() == ew.getD();// TODO: not clear to me. Only the origin is equal for my model, should Action::getO() be added? maybe ew is p and in the other model p->q

        TGRemoteGet rg = new TGRemoteGet(state, label, rgActions,
                                         sx, rr, ew);
        rg.setD(rr.getD());// this one makes sense. The get is p-->q


        TGThread thr = actionToThread.get(sx);
        TGActionGraph tag = po.get(thr);
        
        tag.remove(rr);
        tag.remove(ew);
        tag.replace(sx, rg);
        return rg;
	}
}

class TGRemoteCompareAndSwap extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGWritep wp;
    TGnRWpq rwpq;

    public TGRemoteCompareAndSwap(A4CodeGen.State s,
                            String label,
                            Set<TGAction> actions,
                            TGSX     sx,
                            TGnRWpq rwpq,
                            TGWritep wp) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.rwpq = rwpq;
        this.wp = wp;
    }

    @Override
    public String toString() {//X = cas(Z^q,y,w)
        return String.format("%s = cas (%s^%s,%d,%d,%d)", wp.getWl(), rwpq.getWl(), rwpq.getD().id, rwpq.getRv(), rwpq.getWv() );
    }

	public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {
        Set<TGAction> rcasActions = new HashSet<>();

        // find the remote readwrite pq, write p, and sx
        TGSX sx = null;
        TGWritep ew = null;
        TGnRWpq rrw = null;
        for (TGAction a : actions) {
        	if (a instanceof TGSX) {
                sx = (TGSX)a;
                rcasActions.add(sx);
            } else if (a instanceof TGnRWpq) {
                rrw = ((TGnRWpq)a);
                rcasActions.add(rrw);
            } else if (a instanceof TGWritep) {
                ew = (TGWritep)a;
                rcasActions.add(ew);
            }
        }
        assertValidInstrActs(sx,rrw,ew, actionToThread); 
        
        if (!(sx != null && ew != null && rrw != null)) throw new RuntimeException("Error constructing TGRemoteCompareAndSwap: rr or ew or sx are null");

        TGThread thr = actionToThread.get(ew);
        TGActionGraph tag = po.get(thr);

        TGRemoteCompareAndSwap rcas = new TGRemoteCompareAndSwap
            (state, label, rcasActions, sx, rrw, ew);
        rcas.setD(rrw.getD());

        tag.remove(ew);
        tag.remove(rrw);
        tag.replace(sx, rcas);
        return rcas;
	}

}

class TGRemoteGetAccumulate extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGWritep wp;
    TGnRWpq rwpq;

    public TGRemoteGetAccumulate(A4CodeGen.State s,
                                 String label,
                                 Set<TGAction> actions,
                                 TGSX     sx,
                                 TGWritep wp,
                                 TGnRWpq rwpq) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.rwpq = rwpq;
        this.wp = wp;
    }

    @Override
    public String toString() {// X = rga( Y^T1, y)
        return String.format("%s = rga (%s^%s, %d)", wp.getWl(), rwpq.getWl(), rwpq.getD().id, rwpq.getWv()); // TODO: is the model wrong? Where does the value (y) appear in execution?
    }

	public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {

        Set<TGAction> rgaActions = new HashSet<>();

        // find the remote write, external read
        TGSX sx = null;
        TGnRWpq rrw = null;
        TGWritep ew = null;
        for (TGAction a : actions) {
        	if (a instanceof TGSX) {
                sx = (TGSX)a;
                rgaActions.add(sx);
            } else if (a instanceof TGnRWpq) {
                rrw = (TGnRWpq)a;
                rgaActions.add(rrw);
            } else if (a instanceof TGWritep) {
                ew = (TGWritep)a;
                rgaActions.add(ew);
            }
        }

        if (sx == null || rrw == null || ew == null) throw new RuntimeException("Error constructing TGRemoteGetAccumulate: rr or ew or sx are null");

        assertValidInstrActs(sx,rrw,ew, actionToThread); 

        assert sx.getD() == ew.getD();
        TGThread thr = actionToThread.get(sx);
        TGActionGraph tag = po.get(thr);

        TGRemoteGetAccumulate rga = new TGRemoteGetAccumulate(state, label, rgaActions,
                                                              sx, ew, rrw);
        rga.setD(rrw.getD());

        tag.remove(rrw);
        tag.remove(ew);
        tag.replace(sx, rga);
        return rga;

	}
}

class TGFencedRemoteGet extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGnF     nf;
    TGReadpq rpq;
    TGWritep wp;

    public TGFencedRemoteGet(A4CodeGen.State s,
                       String label,
                       Set<TGAction> actions,
                       TGSX     sx,
                       TGnF     nf,
                       TGReadpq rpq,
                       TGWritep wp) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.nf = nf;
        this.rpq = rpq;
        this.wp = wp;
    }
	public static TGInstruction Compose(State state, String label, Set<TGAction> actions, Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po){
        Set<TGAction> rgActions = new HashSet<>();

        // find the remote read, external write, and sx
        TGWritep ew = null;
        TGReadpq rr = null;
        TGnF nf = null;
        TGSX sx = null;
        for (TGAction a : actions) {
            if (a instanceof TGWritep) {
                ew = (TGWritep)a;
                rgActions.add(ew);
            } else if (a instanceof TGReadpq) {
                rr = (TGReadpq)a;
                rgActions.add(rr);
            }else if (a instanceof TGSX) {
                sx = (TGSX)a;
                rgActions.add(sx);
            }else if (a instanceof TGnF) {
                nf = (TGnF)a;
                rgActions.add(nf);
            }
        }

        if (rr == null || ew == null || sx == null|| nf == null) throw new RuntimeException("Error constructing TGFencedRemoteGet: rr or ew or sx are null");

        assertValidFencedInstrActs(sx, nf, rr, ew, actionToThread);
		assert sx.getD() == ew.getD();
        //assert rr.getD() == ew.getD();// TODO: not clear to me. Only the origin is equal for my model, should Action::getO() be added? maybe ew is p and in the other model p->q

        TGFencedRemoteGet getf = new TGFencedRemoteGet(state, label, rgActions,
                                         sx, nf, rr, ew);
        getf.setD(rr.getD());// this one makes sense. The get is p-->q


        TGThread thr = actionToThread.get(sx);
        TGActionGraph tag = po.get(thr);
        
        tag.remove(rr);
        tag.remove(ew);
        tag.remove(nf);
        tag.replace(sx, getf);
        return getf;
	}
    @Override
    public String toString() {
        return String.format("%s = getf (%s,%s)", wp.getWl(), rpq.getRl(), rpq.getD().id);
    }
}

class TGFencedRemotePut extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGnF     nf;
    TGReadp rp;
    TGWritepq remoteWrite;

    public TGFencedRemotePut(A4CodeGen.State s,
                       String label,
                       Set<TGAction> actions,
                       TGSX     sx,
                       TGnF     nf,
                       TGReadp rp,
                       TGWritepq wpq) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.nf = nf;
        this.rp = rp;
        this.remoteWrite = wpq;
    }

    @Override
    public String toString() {
        return String.format("putf (%s,%d,%s)", remoteWrite.getWl(), getD().id, rp.getRl());
    }
    public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {

        Set<TGAction> rpActions = new HashSet<>();

        // find the remote write, external read
        TGReadp er = null;
        TGWritepq rw = null;
        TGSX sx = null;
        TGnF nf = null;
        for (TGAction a : actions) {
            if (a instanceof TGWritepq) {
                rw = (TGWritepq)a;
                rpActions.add(rw);
            } else if (a instanceof TGReadp) {
                er = (TGReadp)a;
                rpActions.add(er);
            }else if (a instanceof TGSX) {
                sx = (TGSX)a;
                rpActions.add(sx);
            }else if (a instanceof TGnF) {
                nf = (TGnF)a;
                rpActions.add(nf);
            }
        }

        if (rw == null || er == null || sx == null|| nf == null) throw new RuntimeException("Error constructing TGFencedRemotePut: rr or ew or sx are null");

        //assert rw.getD() == er.getD();// TODO: not clear to me. Only the origin is equal for my model, should Action::getO() be added? maybe ew is p and in the other model p->q

        assertValidFencedInstrActs(sx,nf,er,rw, actionToThread); 
        assert sx.getD() == er.getD();

        TGThread thr = actionToThread.get(sx);
        TGActionGraph tag = po.get(thr);

        TGFencedRemotePut putf = new TGFencedRemotePut(state, label, rpActions,
                                         sx, nf, er, rw);
        putf.setD(rw.getD());

        tag.remove(er);
        tag.remove(rw);
        tag.remove(nf);
        tag.replace(sx, putf);

        return putf;
	}
}

class TGFencedRemoteCompareAndSwap extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGnF     nf;
    TGWritep wp;
    TGnRWpq rwpq;

    public TGFencedRemoteCompareAndSwap(A4CodeGen.State s,
                            String label,
                            Set<TGAction> actions,
                            TGSX     sx,
                            TGnF     nf,
                            TGnRWpq rwpq,
                            TGWritep wp) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.nf = nf;
        this.rwpq = rwpq;
        this.wp = wp;
    }

    @Override
    public String toString() {//X = casf(Z^q,y,w)
        return String.format("%s = casf (%s^%s,%d,%d,%d)", wp.getWl(), rwpq.getWl(), rwpq.getD().id, rwpq.getRv(), rwpq.getWv() );
    }

	public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {
        Set<TGAction> rcasfActions = new HashSet<>();

        // find the remote readwrite pq, write p, and sx
        TGSX sx = null;
        TGWritep wp = null;
        TGnRWpq rwpq = null;
        TGnF nf = null;
        for (TGAction a : actions) {
        	if (a instanceof TGSX) {
                sx = (TGSX)a;
                rcasfActions.add(sx);
            } else if (a instanceof TGnRWpq) {
                rwpq = ((TGnRWpq)a);
                rcasfActions.add(rwpq);
            } else if (a instanceof TGWritep) {
                wp = (TGWritep)a;
                rcasfActions.add(wp);
            }else if (a instanceof TGnF) {
                nf = (TGnF)a;
                rcasfActions.add(wp);
            }
        }
        assertValidFencedInstrActs(sx,nf, rwpq,wp, actionToThread); 
        
        if (!(sx != null && wp != null && rwpq != null)) throw new RuntimeException("Error constructing TGRemoteCompareAndSwap: rr or ew or sx are null");

        TGThread thr = actionToThread.get(wp);
        TGActionGraph tag = po.get(thr);

        TGFencedRemoteCompareAndSwap casf = new TGFencedRemoteCompareAndSwap
            (state, label, rcasfActions, sx, nf, rwpq, wp);
        casf.setD(rwpq.getD());

        tag.remove(wp);
        tag.remove(rwpq);
        tag.remove(nf);
        tag.replace(sx, casf);
        return casf;
	}
}

class TGFencedRemoteGetAccumulate extends TGInstruction {
    Set<TGAction> actions;
    TGSX     sx;
    TGnF     nf;
    TGWritep wp;
    TGnRWpq rwpq;

    public TGFencedRemoteGetAccumulate(A4CodeGen.State s,
                                 String label,
                                 Set<TGAction> actions,
                                 TGSX     sx,
                                 TGnF     nf,
                                 TGnRWpq rwpq,
                                 TGWritep wp) {
        super(s, label);
        this.actions = actions;
        this.sx = sx;
        this.nf = nf;
        this.rwpq = rwpq;
        this.wp = wp;
    }

    @Override
    public String toString() {// X = rgaf( Y^T1, y)
        return String.format("%s = rgaf (%s^%s, %d)", wp.getWl(), rwpq.getWl(), rwpq.getD().id, rwpq.getWv()); // TODO: is the model wrong? Where does the value (y) appear in execution?
    }
	public static TGInstruction Compose(State state, String label, Set<TGAction> actions,
			Map<TGAction, TGThread> actionToThread, Map<TGThread, TGActionGraph> po) {
        Set<TGAction> rgafActions = new HashSet<>();

        // find the remote readwrite pq, write p, and sx
        TGSX sx = null;
        TGWritep wp = null;
        TGnRWpq rwpq = null;
        TGnF nf = null;
        for (TGAction a : actions) {
        	if (a instanceof TGSX) {
                sx = (TGSX)a;
                rgafActions.add(sx);
            } else if (a instanceof TGnRWpq) {
                rwpq = ((TGnRWpq)a);
                rgafActions.add(rwpq);
            } else if (a instanceof TGWritep) {
                wp = (TGWritep)a;
                rgafActions.add(wp);
            }else if (a instanceof TGnF) {
                nf = (TGnF)a;
                rgafActions.add(wp);
            }
        }
        assertValidFencedInstrActs(sx,nf, rwpq,wp, actionToThread); 
        
        if (!(sx != null && wp != null && rwpq != null)) throw new RuntimeException("Error constructing TGRemoteCompareAndSwap: rr or ew or sx are null");

        TGThread thr = actionToThread.get(wp);
        TGActionGraph tag = po.get(thr);

        TGFencedRemoteGetAccumulate rgaf = new TGFencedRemoteGetAccumulate
            (state, label, rgafActions, sx, nf, rwpq, wp);
        rgaf.setD(rwpq.getD());

        tag.remove(wp);
        tag.remove(rwpq);
        tag.remove(nf);
        tag.replace(sx, rgaf);
        return rgaf;
	}
    
}

class TGPollCQ extends TGActionImpl {
    public TGPollCQ(A4CodeGen.State s, String label) {
        super(s, label);
    }

    @Override
    public String toString() {// poll_CQ T1
        return String.format("poll_cq (%d)", getD().id);
    }
}

public class A4CodeGen {
    class State {
        int memLocCount = 0;
        int registerCount = 0;
    }

    public final String MODULE;

    public String m(String mm) { return MODULE + mm; }

    public String ACTION_LABEL() { return m("Action"); }
    public String LOC_CPU_ACTION_LABEL() { return m("LocalCPUaction"); }
    public String PO_FIELD_LABEL() { return "po"; }
    public String SW_FIELD_LABEL() { return "sw"; }
    public String RDMAaction_LABEL() { return m("RDMAaction"); }
    public String NODE_LABEL() { return m("Node"); }
    public String THR_LABEL() { return m("Thr"); }
    public String O_FIELD_LABEL() { return "o"; }
    public String D_FIELD_LABEL() { return "d"; }
    public String MEMORY_LOCATION_LABEL() { return m("MemoryLocation"); }
    public String REGISTER_LABEL() { return m("Register"); }
    public String HOST_FIELD_LABEL() { return "host"; }
    public String INITIAL_VALUE_LABEL() { return m("Init"); }
    public String WRITER_LABEL() { return m("Writer"); }
    public String WL_FIELD_LABEL() { return "wl"; }
    public String WV_FIELD_LABEL() { return "wV"; }
    public String READER_LABEL() { return m("Reader"); }
    public String RL_FIELD_LABEL() { return "rl"; }
    public String RV_FIELD_LABEL() { return "rV"; }
    public String POLL_CQ_LABEL() { return m("poll_cq"); }
    public String NF_LABEL() { return m("nF"); }
    public String R_LABEL() { return m("R"); }
    public String SX_LABEL() { return m("Sx"); }
    public String W_LABEL() { return m("W"); }
    public String Put_LABEL() { return m("Put"); }
    public String PutF_LABEL() { return m("PutF"); }
    public String Get_LABEL() { return m("Get"); }
    public String GetF_LABEL() { return m("GetF"); }
    public String RGA_LABEL() { return m("Rga"); }
    public String RGAF_LABEL() { return m("RgaF"); }
    public String CAS_LABEL() { return m("Cas"); }
    public String CASF_LABEL() { return m("CasF"); }
    public String INSTRUCTION_LABEL() { return m("Instruction"); }
    public String ACTIONS_FIELD_LABEL() { return "actions"; }
    public String WITNESS_LABEL() { return m("Witness"); }

    A4Solution solution;
    State state;
    Map<String, TGAction> labelToActions = new HashMap<>();
    Map<String, TGRDMAaction> labelToRDMAactions = new HashMap<>();
    Map<String, TGMemoryLocation> labelToMemoryLocations =
        new HashMap<>();
    Map<String, TGRegister> labelToRegisters = new HashMap<>();
    Map<String, TGWriter> labelToWriters = new HashMap<>();
    Map<String, TGReader> labelToReaders = new HashMap<>();
    Map<String, TGSX> labelToSxs = new HashMap<>();
    Map<String, TGPollCQ> LabelToPollCQ = new HashMap<>();
    Map<String, TGThread> labelToThreads = new HashMap<>();
    Map<String, TGNode> labelToNodes = new HashMap<>();
    Map<TGThread, TGActionGraph> po = new HashMap<>();
    TGRDMAactionGraph sw = null;
    Map<TGAction, TGThread> actionToThread = new HashMap<>();

    // the next maps are currently write-only
    Map<String, TGInstruction> labelToInstr = new HashMap<>();

    TGReader witness;
    TGThread witnessThread;
    Map<TGThread, List<TGReader>> threadToLocalReads = new HashMap<>();

    public A4CodeGen(A4Solution solution, String m) {
        this.solution = solution;
        this.MODULE = m;
        this.state = new State();
    }

    Pattern stemPattern = Pattern.compile("(\\w*/)*(n?[RW][RW]?[p]?[q]?|Init)(\\w*)(\\$.*)?");
    /* create a TGWriter of the appropriate subtype */
    /* NOTE: not fresh if RemoteReadWrite & already exists */
    TGWriter newTGWriter(A4CodeGen.State s,
                         String label, TGMemoryLocation wl, int wV) {
        Matcher m = stemPattern.matcher(label);
        if (m.matches()) {
            String stem = m.group(2);
            if (stem.equals("nRWpq")) {
                if (labelToReaders.containsKey(label)) {
                    TGnRWpq rw = (TGnRWpq)labelToReaders.get(label);
                    rw.setWl(wl); rw.setWv(wV);
                    return rw;
                }
                return new TGnRWpq(s, label, null, 0, wl, wV);
            }
            if (stem.equals("W"))
                return new TGWrite(s, label, wl, wV);
            if (stem.equals("nWp"))
                return new TGWritep(s, label, wl, wV);
            if (stem.equals("nWpq"))
                return new TGWritepq(s, label, wl, wV);
            if (stem.equals("Init"))
                return new TGInitialValue(s, label, wl, wV);
            if (stem.equals("nRWpq"))
                return null;
        }
        return new TGWriterImpl(s, label, wl, wV, true);
    }

    /* create a TGReader of the appropriate subtype */
    /* NOTE: not fresh if RemoteReadWrite & already exists */
    TGReader newTGReader(A4CodeGen.State s,
                         String label,
                         TGMemoryLocation rl, int rV,
                         TGRegister reg) {
        Matcher m = stemPattern.matcher(label);
        if (m.matches()) {
            String stem = m.group(2);
            if (stem.equals("nRWpq")) {
                if (labelToWriters.containsKey(label)) {
                    TGnRWpq rw = (TGnRWpq)labelToWriters.get(label);
                    rw.setRl(rl); rw.rV = rV;
                    return rw;
                }
                return new TGnRWpq(s, label, rl, rV, null, 0);
            }
            if (stem.equals("nRpq"))
                return new TGReadpq(s, label, rl, rV);
            if (stem.equals("nRp"))
                return new TGReadp(s, label, rl, rV);
            if (stem.equals("R"))
                return new TGRead(s, label, rl, rV, null);
        }
        if (true) {
            System.out.println("TGReader Matcher error, can't parse: " + label);
            System.exit(1);
        }
        return new TGReaderImpl(s, label, rl, rV);
    }

    void parseNodes() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(NODE_LABEL())) {
                A4TupleSet nodes = solution.eval(s);
                for (A4Tuple n : nodes) {
                    String label = n.atom(0);
                    TGNode node = new TGNode(state, label,
                                                   new ArrayList<>(),//memory locations
                                                   new ArrayList<>());//threads
                                                   
                    labelToNodes.put(label, node);
                }
            }
        }
    }
    
    void parseThreads() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(THR_LABEL())) {
                A4TupleSet threads = solution.eval(s);
                for (A4Tuple t : threads) {
                    String label = t.atom(0);
                    TGThread thread = new TGThread(state, label,
                                                   //new ArrayList<>(),//memory locations
                                                   new ArrayList<>(),//registers
                                                   new ArrayList<>());//actions
                    labelToThreads.put(label, thread);
                }
                for (Field f : s.getFields()) {
                    if (f.label.equals(HOST_FIELD_LABEL())) {
                        A4TupleSet node4MemLoc = solution.eval(f);
                        for (A4Tuple n4m : node4MemLoc) {
                            TGThread t = labelToThreads.get(n4m.atom(0));
                            TGNode n = labelToNodes.get(n4m.atom(1));
                            n.threads.add(t);
                        }
                    }
                }
            }
        }
    }

    void parseMemoryLocations() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(MEMORY_LOCATION_LABEL())) {
                A4TupleSet mls = solution.eval(s);
                for (A4Tuple ml : mls) {
                    String label = ml.atom(0);
                    TGMemoryLocation memLoc = new TGMemoryLocation(state,
                                                                   label);
                    labelToMemoryLocations.put(label, memLoc);
                }

                for (Field f : s.getFields()) {
                    if (f.label.equals(HOST_FIELD_LABEL())) {
                        A4TupleSet node4MemLoc = solution.eval(f);
                        for (A4Tuple n4m : node4MemLoc) {
                            TGMemoryLocation m = labelToMemoryLocations.get(n4m.atom(0));
                            TGNode n = labelToNodes.get(n4m.atom(1));
                            n.memoryLocations.add(m);
                        }
                    }
                }               
            }
        }
    }

    void parseRegisters() {//finding all local reads, and for each read creating a unique local variable
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(R_LABEL())) {
                A4TupleSet rs = solution.eval(s);
                for (A4Tuple rl : rs) {
                    String label = rl.atom(0);
                    TGRegister r = new TGRegister(state,
                                                  label);
                    labelToRegisters.put(label, r);
                }

                for (Field f : s.getFields()) {
                    if (f.label.equals(O_FIELD_LABEL())) {
                        A4TupleSet thread4Reg = solution.eval(f);
                        for (A4Tuple t4r : thread4Reg) {
                            TGRegister r = labelToRegisters.get(t4r.atom(0));
                            TGThread t = labelToThreads.get(t4r.atom(1));
                            t.registers.add(r);
                        }
                    }
                }
            }
        }
    }

    void parseWriters() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(WRITER_LABEL())) {
                A4TupleSet writers = solution.eval(s);
                for (A4Tuple writer : writers) {
                    String label = writer.atom(0);
                    TGWriter w = newTGWriter(state, label, null, 0);
                    
                    if(w instanceof TGRDMAaction) {
                    	labelToRDMAactions.put(label, (TGRDMAaction)w);                    	
                    }
                    labelToWriters.put(label, w);
                    labelToActions.put(label, w);
                }
                for (Field f : s.getFields()) {
                    if (f.label.equals(WV_FIELD_LABEL())) {
                        A4TupleSet val4Writer = solution.eval(f);
                        for (A4Tuple v4w : val4Writer) {
                            TGWriter w = labelToWriters.get(v4w.atom(0));
                            int v = Integer.parseInt(v4w.atom(1));
                            w.setWv(v);
                        }
                    }
                    if (f.label.equals(WL_FIELD_LABEL())) {
                        A4TupleSet loc4Writer = solution.eval(f);
                        for (A4Tuple l4w : loc4Writer) {
                            TGWriter w = labelToWriters.get(l4w.atom(0));
                            TGMemoryLocation l = labelToMemoryLocations.get(l4w.atom(1));
                            w.setWl(l);
                        }
                    }
                }
            }
        }
    }

    void parseReaders() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(READER_LABEL())) {
                A4TupleSet readers = solution.eval(s);
                for (A4Tuple reader : readers) {
                    String label = reader.atom(0);
                    TGReader r = newTGReader(state, label, null, 0, null);
                    if(r instanceof TGRDMAaction) {
                    	labelToRDMAactions.put(label, (TGRDMAaction)r);                    	
                    }
                    labelToReaders.put(label, r);
                    labelToActions.put(label, r);
                }
                for (Field f : s.getFields()) {
                    if (f.label.equals(RV_FIELD_LABEL())) {
                        A4TupleSet val4Reader = solution.eval(f);
                        for (A4Tuple v4r : val4Reader) {
                            TGReader r = labelToReaders.get(v4r.atom(0));
                            int v = Integer.parseInt(v4r.atom(1));
                            r.setRv(v);
                        }
                    }
                    if (f.label.equals(RL_FIELD_LABEL())) {
                        A4TupleSet loc4Reader = solution.eval(f);
                        for (A4Tuple l4r : loc4Reader) {
                            TGReader r = labelToReaders.get(l4r.atom(0));
                            TGMemoryLocation l = labelToMemoryLocations.get(l4r.atom(1));
                            r.setRl(l);
                        }
                    }
                }
            }
        }
/*
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(R_LABEL())) {
                for (Field f : s.getFields()) {
                    if (f.label.equals(REG_FIELD_LABEL())) {
                        A4TupleSet reg4Reader = solution.eval(f);
                        for (A4Tuple r4r : reg4Reader) {
                            TGRead r = (TGRead)labelToReaders.get(r4r.atom(0));
                            TGRegister l = labelToRegisters.get(r4r.atom(1));
                            r.reg = l;
                        }
                    }
                }
            }           
        }
        */
    }


    void parseSx() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(SX_LABEL())) {
                A4TupleSet sxActions = solution.eval(s);
                for (A4Tuple sx_tuple : sxActions) {
                    String label = sx_tuple.atom(0);
                    TGSX sx = new TGSX(state, label);
                    labelToSxs.put(label, sx);
                    labelToActions.put(label, sx);
                    labelToRDMAactions.put(label, sx);
                }                
            }
        }
    }


    void parseNf() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(NF_LABEL())) {
                A4TupleSet nfActions = solution.eval(s);
                for (A4Tuple nf_tuple : nfActions) {
                    String label = nf_tuple.atom(0);
                    TGnF nf = new TGnF(state, label);
                    labelToActions.put(label, nf);
                    labelToRDMAactions.put(label, nf);
                }                
            }
        }
    }

    void parsePollcq() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(POLL_CQ_LABEL())) {
                A4TupleSet pollcqs = solution.eval(s);
                for (A4Tuple pollcq : pollcqs) {
                    String label = pollcq.atom(0);
                    TGPollCQ pcq = new TGPollCQ(state, label);
                    LabelToPollCQ.put(label, pcq);
                    labelToActions.put(label, pcq);
                }
                // parseOriginDestination handles assignment to threads
            }
        }
    }

    void parseInitialValues() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(INITIAL_VALUE_LABEL())) {
                A4TupleSet initialValues = solution.eval(s);
                for (A4Tuple iv : initialValues) {
                    TGWriter w = labelToWriters.get(iv.atom(0));
                    w.getWl().initialValue = w.getWv();
                }
            }
        }
    }

    void parseOriginDestinationThreads() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(ACTION_LABEL())) {
                A4TupleSet actions = solution.eval(s);
                for (A4Tuple a : actions) {
                    String label = a.atom(0);
                    if (labelToActions.get(label) == null) {
                        TGAction action = new TGActionImpl(state, label);
                        labelToActions.put(label, action);
                    }
                }
                for (Field f : s.getFields()) {
                    if (f.label.equals(O_FIELD_LABEL())) {
                        A4TupleSet thread4Action = solution.eval(f);
                        for (A4Tuple t4a : thread4Action) {
                            TGAction a = labelToActions.get(t4a.atom(0));
                            TGThread t = labelToThreads.get(t4a.atom(1));
                            t.actions.add(a);
                            actionToThread.put(a, t);
                        }
                    }
                    if (f.label.equals(D_FIELD_LABEL())) {
                        A4TupleSet thread4Action = solution.eval(f);
                        for (A4Tuple t4a : thread4Action) {
                            TGAction a = labelToActions.get(t4a.atom(0));
                            TGThread t = labelToThreads.get(t4a.atom(1));
                            a.setD(t);
                        }
                    }
                }
            }
        }
    }

    
    void parseProgramOrder() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(LOC_CPU_ACTION_LABEL())) {
                for (Field f : s.getFields()) {
                    if (f.label.equals(PO_FIELD_LABEL())) {
                        A4TupleSet pos = solution.eval(f);
                        for (A4Tuple po : pos) {
                            TGAction src = labelToActions.get(po.atom(0));
                            TGAction dest = labelToActions.get(po.atom(1));

                            src.getSuccs().add(dest);
                            dest.getPreds().add(src);
                        }
                    }
                }
            }
        }

        for (TGThread t : labelToThreads.values()) {
            po.put(t, new TGActionGraph(t.actions));
        }
    }

    void parseSynchroniseWith() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(RDMAaction_LABEL())) {
                for (Field f : s.getFields()) {
                    if (f.label.equals(SW_FIELD_LABEL())) {
                        A4TupleSet pos = solution.eval(f);
                        for (A4Tuple po : pos) {
                            TGRDMAaction src = labelToRDMAactions.get(po.atom(0));
                            TGRDMAaction dest = labelToRDMAactions.get(po.atom(1));

                            src.getSwSuccs().add(dest);
                            dest.getSwPreds().add(src);
                        }
                    }
                }
            }
        }
        sw=new TGRDMAactionGraph(labelToRDMAactions.values());
    }
    
    void combineRemoteOp() {//TODO: they all are duplicated for fenced ops
        // rg has: label, actions, sx, read pq, write p
        // rp has: label, actions, sx, read p, write pq
        Map<String, Set<TGAction>> ropLabelToActions = new HashMap<>();

        // populate the 'actions' map based on Statement.actions
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(INSTRUCTION_LABEL())) {
                for (Field f : s.getFields()) {
                    if (f.label.equals(ACTIONS_FIELD_LABEL())) {
                        A4TupleSet actions = solution.eval(f);
                        for (A4Tuple action : actions) {
                            String rop = action.atom(0);
                            if (ropLabelToActions.get(rop) == null) {
                                ropLabelToActions.put(rop,
                                                      new HashSet<>());
                            }
                            Set<TGAction> rops = ropLabelToActions.get(rop);
                            rops.add(labelToActions.get(action.atom(1)));
                        }
                    }
                }
            }
        }

        //TODO: each if below is could be refactored. e.g. for the next one: create as a method of TGRemoteGet
        // the method could be inherited from TGStatement above, and activated accordingly
        // rg
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(Get_LABEL())) {
                A4TupleSet rgs = solution.eval(s);
                for (A4Tuple rgt : rgs) {
                    String label = rgt.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rg = TGRemoteGet.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rg);
                    labelToActions.put(label, rg);
                }
            }else if (s.label.equals(Put_LABEL())) {
                A4TupleSet rps = solution.eval(s);
                for (A4Tuple rpt : rps) {
                    String label = rpt.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rp = TGRemotePut.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rp);
                    labelToActions.put(label, rp);
                }
            }else if (s.label.equals(RGA_LABEL())) {
                A4TupleSet rgas = solution.eval(s);
                for (A4Tuple rgat : rgas) {
                    String label = rgat.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);                    

                    TGInstruction rga = TGRemoteGetAccumulate.Compose(state, label, actions, actionToThread, po);                    labelToInstr.put(label, rga);
                    labelToInstr.put(label, rga);
                    labelToActions.put(label, rga);                
                }
            }else if (s.label.equals(CAS_LABEL())) {
                A4TupleSet rcass = solution.eval(s);
                for (A4Tuple rcast : rcass) {
                    String label = rcast.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rcas = TGRemoteCompareAndSwap.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rcas);
                    labelToActions.put(label, rcas);
                }
            }else if (s.label.equals(GetF_LABEL())) {
                A4TupleSet rgs = solution.eval(s);
                for (A4Tuple rgt : rgs) {
                    String label = rgt.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rg = TGFencedRemoteGet.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rg);
                    labelToActions.put(label, rg);
                }
            }else if (s.label.equals(PutF_LABEL())) {
                A4TupleSet rps = solution.eval(s);
                for (A4Tuple rpt : rps) {
                    String label = rpt.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rp = TGFencedRemotePut.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rp);
                    labelToActions.put(label, rp);
                }
            }else if (s.label.equals(RGAF_LABEL())) {
                A4TupleSet rgas = solution.eval(s);
                for (A4Tuple rgat : rgas) {
                    String label = rgat.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);                    

                    TGInstruction rga = TGFencedRemoteGetAccumulate.Compose(state, label, actions, actionToThread, po);                    labelToInstr.put(label, rga);
                    labelToInstr.put(label, rga);
                    labelToActions.put(label, rga);                
                }
            }else if (s.label.equals(CASF_LABEL())) {
                A4TupleSet rcass = solution.eval(s);
                for (A4Tuple rcast : rcass) {
                    String label = rcast.atom(0);
                    Set<TGAction> actions = ropLabelToActions.get(label);

                    TGInstruction rcas = TGFencedRemoteCompareAndSwap.Compose(state, label, actions, actionToThread, po);
                    labelToInstr.put(label, rcas);
                    labelToActions.put(label, rcas);
                }
            }
        }
    }

    void parseWitness() {
        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(WITNESS_LABEL())) {
                A4TupleSet ws = solution.eval(s);
                for (A4Tuple w : ws) {
                    witness = (TGReader)labelToReaders.get(w.atom(0));
                }
            }
        }
        if (witness != null) {
            witnessThread = actionToThread.get(witness);
        }
    }

    void parseLocalReads() {
        for (TGThread t : labelToThreads.values()) {
            threadToLocalReads.put(t, new ArrayList<TGReader>());
        }

        for (Sig s : solution.getAllReachableSigs()) {
            if (s.label.equals(R_LABEL())) {
                A4TupleSet rs = solution.eval(s);
                for (A4Tuple r : rs) {

                	TGReader read = (TGReader)labelToReaders.get(r.atom(0));
                    TGThread thread = actionToThread.get(read);

                    threadToLocalReads.get(thread).add(read);
                }
            }
        }
    }

    // also renumbers existing threads
    void eliminateEmptyThreads() {// TODO: redundant? Done at the level of Alloy? 
        Set<TGThread> emptyThreads = new HashSet<>();
        for (TGThread t : labelToThreads.values()) {
            TGActionGraph tag = po.get(t);
            if (tag.actions.size() == 0)
                emptyThreads.add(t);
        }

        for (TGThread t : emptyThreads) {
            labelToThreads.remove(t.label);
            //t.host.threads.remove(t);//TODO: remove the thread from the correct node
        }

        int counter = 0;
        for (TGThread t : labelToThreads.values()) {
            t.id = counter++;
        }
    }

    // also renumbers existing threads
    void eliminateEmptyNodes() {// TODO: redundant? Done at the level of Alloy? 
        Set<TGNode> emptyNodes = new HashSet<>();
        for (TGNode n : labelToNodes.values()) {
            if (n.threads.size() == 0)
                emptyNodes.add(n);
        }

        for (TGNode n : emptyNodes) {
            labelToNodes.remove(n.label);
        }

        int counter = 0;
        for (TGNode n : labelToNodes.values()) {
            n.id = counter++;
        }
    }
    void createModel() {
        parseNodes();
        parseMemoryLocations();
        parseThreads();
        parseRegisters();
        parseReaders(); 
        parseWriters(); 
        parseSx();
        parseNf();
        parsePollcq();
        parseOriginDestinationThreads();
        parseInitialValues();
        parseProgramOrder();
        parseSynchroniseWith();
        parseWitness();
        parseLocalReads();
        combineRemoteOp();
        eliminateEmptyThreads();//safety? not assuming removed from alloy?
        //eliminateEmptyNodes();
    }

    void printThreads(PrintWriter w, int number, TGNode n) {
        int process_number = 1;
        for (TGThread t : n.threads) {
            if (process_number > 1) w.println();
            w.format("process %d\n", t.id);
            process_number++;

            boolean first = true;
            
            if (!t.registers.isEmpty()) {
                StringBuilder locals = new StringBuilder("local ");
                first = true;
                for (TGRegister r : t.registers) {
                    if (first)
                        first = false;
                    else
                        locals.append(", ");
                    locals.append(r);
                }
                locals.append(";");
                w.println(locals);
            }

            PseudoTopologicalOrderer<TGAction> pto = new PseudoTopologicalOrderer<>();
            for (TGAction a : pto.newList(po.get(t), false)) {
                if (a instanceof TGInitialValue)
                    continue;

                w.println(a + ";");
            }

            // check stage:
            //if (t == witnessThread && witness != null)
            //    w.printf("assert (!(%s == %s));\n", witness.reg, witness.rV);

            // also check the values of other local reads
            /*List<TGRead> localReads = threadToLocalReads.get(t);
            if ( ! localReads.isEmpty()) {
                TGRead lr = localReads.get(0);
                w.printf("assert (!((%s == %s)", lr.reg, lr.rV);

                for (int i = 1; i < localReads.size(); i++) {
                    lr = localReads.get(i);
                    w.printf(" && (%s == %s)", lr.reg, lr.rV);
                }

                w.printf("));\n");
            }*/



        }
        w.println("// ---\n");
    }

    void printNodes(PrintWriter w, int number) {
        int node_number = 1;
        for (TGNode n : labelToNodes.values()) {
            if (node_number > 1) w.println();
            w.format("node %d\n", n.id);
            node_number++;

            boolean first = true;
            if (!n.memoryLocations.isEmpty()) {
                StringBuilder memlocs = new StringBuilder("shared ");
                for (TGMemoryLocation ml : n.memoryLocations) {
                    if (first)
                        first = false;
                    else
                        memlocs.append(", ");

                    memlocs.append(ml);
                    if (ml.initialValue != null) {
                        memlocs.append(" = "); 
                        memlocs.append(ml.initialValue.toString());
                    }
                }
                memlocs.append(";");
                w.println(memlocs);
            }

            if (!n.threads.isEmpty()) {
            	printThreads(w, number, n);
            }

            
            // check stage:
            //if (t == witnessThread && witness != null)
            //    w.printf("assert (!(%s == %s));\n", witness.reg, witness.rV);

            // // also check the values of other local reads
            //List<TGRead> localReads = threadToLocalReads.get(t);
            //if ( ! localReads.isEmpty()) {
            //    TGRead lr = localReads.get(0);
            //    w.printf("assert (!((%s == %s)", lr.reg, lr.rV);
            //
            //    for (int i = 1; i < localReads.size(); i++) {
            //        lr = localReads.get(i);
            //        w.printf(" && (%s == %s)", lr.reg, lr.rV);
            //    }
            //
            //    w.printf("));\n");
            // }



        }
        w.println("// --- ---\n");
    }

    public void emitCode(PrintWriter w, int number) {
        createModel();
        printNodes(w, number);
    }
}
