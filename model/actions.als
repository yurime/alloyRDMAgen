open util/integer

/* Machine with one or more Threads */
sig Node {}

/* Thread */
sig Thr {
	host: one Node // host node
}

/* Variables */
sig MemoryLocation {
  host: one Node
}

abstract sig Action {
	/* program order, consistency order */
	po : set Action, 

	/* destination and origin thread of the action */	
	d, o : one Thr
}

abstract sig Sx extends LocalAction{
	instr: one Instruction,
	sw: one nA
}
fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}

abstract sig LocalAction extends Action{}
fact { all a: LocalAction| o[a] = d[a]}

/*CPU read*/
sig R extends LocalAction{}
fact {all r:R| r in Reader and not(r in Writer)}

/*CPU write*/
sig W extends LocalAction{}
fact {all w:W| w in Writer and not(w in Reader)}

/*NIC action*/
abstract sig nA extends Action{
	instr: one Instruction,
    sw: set Action, //YM
    cosw: set Action //YM
//	host: one Node // host machine
}
// fact {all a: nA| host[a] = host[o[a]]}
fact {all na:nA, a :sw[na]| a in nA+poll_cq}//YM: subsetequal, sw connects to nA or to poll_cq
//fact {all na:nA | na in sw[nA] + sw[Sx] }//YM: all nA are connected by some sw (at the very least instr_sw) (is this forall exists?)
//fact {all pq:poll_cq | pq in sw[nA] } // YM: every poll_cq is connected by sw from some relation.
//fact {all na:nA | not na in sw[na]}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}

/*NIC local read*/
sig nRp extends nR{}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}

/*NIC local write*/
sig nWp extends nW{}

/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}

/*c-atomics*/
sig U extends LocalAction {}
fact {all u:U| u in Writer and u in Reader}

/*RDMA Fence*/
sig nFpq extends Action {}
fact {all f:nFpq| not(f in Writer) and not (f in Reader)}

/*poll_cq*/
sig poll_cq extends Action {
  cosw: one nA
}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}

abstract sig Instruction {
	actions: set Action
}
fact {all i: Instruction, sx: Sx| sx in actions[i] iff instr[sx] = i}
fact {all i: Instruction, a: nA| a in actions[i] iff instr[a] = i}

sig Put extends Instruction {}
fact {all p: Put| #actions[p] = 3 and #(actions[p] & Sx_put) = 1 and #(actions[p] & nRp) = 1 and #(actions[p] & nWpq) = 1}

sig Get extends Instruction {}
fact {all g: Get| #actions[g] = 3 and #(actions[g] & Sx_get) = 1 and #(actions[g] & nRpq) = 1 and #(actions[g] & nWp) = 1}

sig Rga extends Instruction {}
fact {all rga: Rga| #actions[rga] = 3 and #(actions[rga] & Sx_rga) = 1 and #(actions[rga] & nRWpq) = 1 and #(actions[rga] & nWp) = 1}

sig Cas extends Instruction {}
fact {all cas: Cas| #actions[cas] = 3 and #(actions[cas] & Sx_cas) = 1 and #(actions[cas] & nRWpq) = 1 and #(actions[cas] & nWp) = 1}

sig Sx_put extends Sx {}

sig Sx_get extends Sx {}

sig Sx_rga extends Sx {}

sig Sx_cas extends Sx {}

sig Reader in Action {
	rl: one MemoryLocation,
	corf: one Writer,
	rV: one Int 
}

sig Writer in Action {
	wl: one MemoryLocation,
	wV: one Int,
	rf: set Reader
}


fact {Writer=W+U+nW+nRWpq} //YM: better defintion than for each of the Actions? Does this mean equality or subseteq?
fact {Reader=R+U+nR+nRWpq} //YM: maybe delete if the other is better for some reason

pred show { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
	  #Cas = 1 and
            #Rga = 1}

run show for 10
