// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.util.List;

class TGThread {
    String label;
    int id;
    List<TGRegister> registers;
    List<TGAction> actions;

    public TGThread(A4CodeGen.State s,    		        
                    String label,
                    List<TGRegister> registers,
                    List<TGAction> actions) {
        this.label = label;
        this.registers = registers;
        this.actions = actions;

        this.id = Integer.parseInt(label.substring(label.indexOf("$")+1));
    }

    public String toString() { return label; }
}
