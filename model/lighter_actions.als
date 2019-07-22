open util/integer
// removing one to one po, used for display, and copo (which doesn't seem to help?)
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

	/* destination and origin thread of the action */	
	d, o : one Thr
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachine [a:Action] { not host[o[a]]=host[d[a]] }

sig Reader in Action {
	rl: one MemoryLocation,
	rV: one Int,
	corf: one Writer
}


sig Writer in Action {
	wl: one MemoryLocation,
	wV: one Int,
	rf: set Reader
}

sig Init extends W{}
fact{Init.wl=MemoryLocation}
fact{Init.~po_tc=none}
//rf implies shared location and value
fact{all w:Writer, r:rf[w] | rl[r]=wl[w] and rV[r]=wV[w]}

// atomic actions non recursive and atomic to one location
fact{not cyclic[rf]}
fact{all w:Writer&Reader | rl[w]=wl[w] }

fact{~rf=corf}

// read/write from the same machine as the action destination
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }


sig RDMAaction in Action {
    sw : set Action
}

abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction
}
fact {po_tc=^po_tc}
fact{not cyclic[po_tc]}
fact {all a: LocalCPUaction| o[a] = d[a]}
fact {all disj a,b: LocalCPUaction| 
                                      (o[a] = o[b])
                                      iff
                                      (
                                        (a in b.po_tc) or
                                        (a in b.~po_tc) 
                                      )
}

/* start NIC action (start external)*/
abstract sig Sx extends LocalCPUaction{
	instr: one Instruction,
	instr_sw: one nA
}

sig Sx_put extends Sx {}
sig Sx_get extends Sx {}
sig Sx_cas extends Sx {}
sig Sx_rga extends Sx {}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}

/*CPU read*/
sig R extends LocalCPUaction{}
fact {all r:R| r in Reader and not(r in Writer)}
fact {all a:R| not(a in RDMAaction)}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}

/*c-atomics*/
sig U extends LocalCPUaction {}
fact {all u:U| u in Writer and u in Reader}
fact {all a:U| not(a in RDMAaction)}

/*NIC action*/
abstract sig nA extends Action{
	instr: one Instruction,
    instr_sw: lone nA,
    co_instr_sw: lone nA+Sx,  
    nic_ord_sw: set nA,
    poll_cq_sw: lone poll_cq 
}
fact {all a:nA| (a in RDMAaction)}

fact{all a:nA, b:nA | (a in b.instr_sw) iff (b in a.co_instr_sw)}
fact{all a:nA, b:Sx | (a in b.instr_sw) iff (b in a.co_instr_sw)}

//fact {nA in sw[nA] + sw[Sx] }//YM: all nA are connected by some sw (at the very least instr_sw) (is this forall exists?)
//fact {poll_cq in sw[nA] } // YM: every poll_cq is connected by sw from some relation.
//fact {all na:nA | not na in sw[na]}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}
fact {all a: nRpq| not host[o[a]] = host[d[a]]}

/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| o[a] = d[a]}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| not host[o[a]] = host[d[a]]}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| o[a] = d[a]}

/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}
fact { all a: nRWpq| not host[o[a]] = host[d[a]]}


/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}
fact { all a: nF| o[a] = d[a]}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {
  co_poll_cq_sw:one nA
}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}
fact {all a:poll_cq| not (a in RDMAaction)}

/* RDMA instructions and the actions that compose them*/
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
  #(actions & nWpq) = 1  
}

sig Get extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1
}

sig Rga extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1
}

sig Cas extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_cas) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1
}

// instructions with a nic fence
sig PutF extends Instruction {}{ 
  #actions = 4 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nF) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1
}
sig GetF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nF) = 1 and  
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1 
}
sig RgaF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nF) = 1 and  
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1
}

sig CasF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_cas) = 1 and
  #(actions & nF) = 1 and   
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1
}

// should break here and hold with sw_rules. but it holds here. Why?
//check{all disj i1,i2:Instruction | #(actions[i1]&actions[i2])=0} for 8
//alternative formulation 
//run{some disj i1,i2:Instruction | #(actions[i1]&actions[i2])>0} for 8

pred p { 
           #Put = 1 and
            #Sx_cas = 1 and
            #Thr = 2}


run p for 8
