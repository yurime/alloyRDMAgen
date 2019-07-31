// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
package ch.ethz.srl;

import java.util.List;

class TGNode {
    String label;
    int id;
    List<TGMemoryLocation> memoryLocations;
    List<TGThread> threads;

    public TGNode(A4CodeGen.State s,
                    String label,
                    List<TGMemoryLocation> memoryLocations,
                    List<TGThread> threads
                    ) {
        this.label = label;
        this.memoryLocations = memoryLocations;
        this.threads = threads;

        this.id = Integer.parseInt(label.substring(label.indexOf("$")+1));
    }

    public String toString() { return label; }
}
