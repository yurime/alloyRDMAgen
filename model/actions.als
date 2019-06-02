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
	instr_sw: one nA
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
    instr_sw: lone nA, //YM
//	host: one Node // host machine
}
//fact {all a: nA| host[a] = host[o[a]]}
//fact {nA in sw[nA] + sw[Sx] }//YM: all nA are connected by some sw (at the very least instr_sw) (is this forall exists?)
//fact {poll_cq in sw[nA] } // YM: every poll_cq is connected by sw from some relation.
//fact {all na:nA | not na in sw[na]}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}

/*NIC local read*/
sig nRp extends nR{}
fact { all a: nRp| o[a] = d[a]}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| o[a] = d[a]}

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
sig poll_cq extends Action {}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}

abstract sig Instruction {
	actions: set Action
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}

fact {all i: Instruction, sx: Sx| sx in actions[i] iff instr[sx] = i}
fact {all i: Instruction, a: nA| a in actions[i] iff instr[a] = i}

sig Put extends Instruction {}{ 
  #actions = 3 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1 and 
  all sx: actions & Sx_put, 
      nrp: actions & nRp,
      nwpq: actions & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
          (not host[d[nwpq]] = host[o[nrp]])
     }
}

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

fact{all disj s1,s2:Sx | not instr_sw[s1]=instr_sw[s2] }

sig Reader in Action {
	rl: one MemoryLocation,
	rV: one Int 
}


sig Writer in Action {
	wl: one MemoryLocation,
	wV: one Int,
	rf: set Reader
}


fact{Reader in rf[Writer]}
fact{all w:Writer| not w in rf[w]}
fact{all w:Writer, r:Reader| r in rf[w] implies (rl[r]=wl[w] and rV[r]=wV[w]) }
fact{all w:nRWpq+U | rl[w]=wl[w] }
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }

fact {Writer=W+U+nW+nRWpq} //YM: better defintion than for each of the Actions? Does this mean equality or subseteq?
fact {Reader=R+U+nR+nRWpq} //YM: maybe delete if the other is better for some reason

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Sx_put = 1 and
            #Thr = 2}

run p for 4
