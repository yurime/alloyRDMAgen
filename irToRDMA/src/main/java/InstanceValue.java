// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

public class InstanceValue {
    List<Node> nodes;
    List<Proc> processes;
    Map<Integer, List<Integer>> nodeProcesses;
    Map<Integer, List<String>> processContents;
    Map<Integer, Integer> processRemoteOpCounts;
//    Map<Integer, Integer> mdEventCounts;
  //  Map<Integer, Integer> leEventCounts;
    List<TLParser.SimpleExpressionContext> assertions;
    Map<TLParser.SimpleExpressionContext, Integer> owningProcess;//for assertions
    Map<String, Integer> varNameToIndex = new HashMap<>();
    List<String> outputs;

    public InstanceValue() {
        this.nodes = new ArrayList<>();
        this.processes = new ArrayList<>();
        this.nodeProcesses = new HashMap<>();
        this.processContents = new HashMap<>();
        this.processRemoteOpCounts = new HashMap<>();
//        this.mdEventCounts = new HashMap<>();
        //this.leEventCounts = new HashMap<>();
        this.assertions = new ArrayList<>();
        this.owningProcess = new HashMap<>();
        this.varNameToIndex = new HashMap<>();
        this.outputs = new ArrayList<>();
    }
}
