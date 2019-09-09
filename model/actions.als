open util/integer

/* Machine with one or more Threads */
sig Node {}

/* Thread */
sig Thr {
	host: one Node // host node
}

/* Shared Variables */
sig MemoryLocation {
  host: one Node
}

///* Local Variables*/
sig Register{
  o: one Thr
}

fact { all r: Register| o[r] = o[~reg[r]] }

abstract sig Action {

	/* destination and origin thread of the action */	
	d, o : one Thr
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }

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

fact{~rf=corf}

sig Init extends W{}

sig RDMAaction in Action {
    sw : set Action
}

abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
	copo : set LocalCPUaction
}

/* start NIC action (start external)*/
abstract sig Sx extends LocalCPUaction{
	instr : one Instruction,
	instr_sw: one nA
}

sig Sx_put extends Sx {}
sig Sx_get extends Sx {}
sig Sx_cas extends Sx {}
sig Sx_rga extends Sx {}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}

/*CPU read*/
sig R extends LocalCPUaction{
   reg : one Register
}
fact {all r:R| r in Reader and not(r in Writer)}
fact {all a:R| not(a in RDMAaction)}
//fact {all disj a, b: R|
//				not (reg[a] = reg[b])}
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
	instr : one Instruction,
	instr_sw: lone nA,
    nic_ord_sw: set nA,
    poll_cq_sw: lone poll_cq
}
fact {all a:nA| (a in RDMAaction)}

//fact{all na:nA | not na in na.^nic_ord_sw}
//fact {nA in sw[nA] + sw[Sx] }//YM: all nA are connected by some sw (at the very least instr_sw) (is this forall exists?)
//fact {poll_cq in sw[nA] } // YM: every poll_cq is connected by sw from some relation.
//fact {all na:nA | not na in sw[na]}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}
fact {all a: nRpq| remoteMachineAction[a]}

/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| localMachineAction[a]}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| remoteMachineAction[a]}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| localMachineAction[a]}

/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}
fact { all a: nRWpq| remoteMachineAction[a]}


/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}
fact {all a: nF| localMachineAction[a]}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {
  co_poll_cq_sw:one nA
}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}
fact {all a:poll_cq| not (a in RDMAaction)}

/* RDMA instructions and the actions that compose them*/
abstract sig Instruction {
	actions: set Sx+nA
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}

fact {all a: Sx| all i: Instruction | instr[a] = i iff a in i.actions}
fact {all a: nA| all i: Instruction | instr[a] = i iff a in i.actions}

sig Put extends Instruction {}{ 
  #actions = 3 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1    and 
  (let nrp=actions & nRp,
      nwpq=actions & nWpq{
       rV[nrp] = wV[nwpq]
   })
}

sig Get extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1   and 
  (let nrpq=actions & nRpq,
      nwp=actions & nWp{
       rV[nrpq] = wV[nwp]
   })
}

sig Rga extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1  and 
  (let nrwpq=actions & nRWpq,
      nwp=actions & nWp{
       rV[nrwpq] = wV[nwp]
   })
}

sig Cas extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_cas) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1   and 
  (let nrwpq=actions & nRWpq,
      nwp=actions & nWp{
       rV[nrwpq] = wV[nwp]
   })
}

// instructions with a nic fence
sig PutF extends Instruction {}{ 
  #actions = 4 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nF) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1   and 
  (let nrp=actions & nRp,
      nwpq=actions & nWpq{
       rV[nrp] = wV[nwpq]
   })
}
sig GetF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nF) = 1 and  
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1 and 
  (let nrqp=actions & nRpq,
        nwp=actions & nWp{
    rV[nrqp] = wV[nwp]
   })
}
sig RgaF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nF) = 1 and  
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1   and 
  (let nrwpq=actions & nRWpq,
      nwp=actions & nWp{
       rV[nrwpq] = wV[nwp]
   })
}

sig CasF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_cas) = 1 and
  #(actions & nF) = 1 and   
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1  and 
  (let nrwpq=actions & nRWpq,
      nwp=actions & nWp{
       rV[nrwpq] = wV[nwp]
   })
}



//--- Reader/Writer rules

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | rl[r]=wl[w] and rV[r]=wV[w]}

// atomic actions non recursive and atomic to one location
fact{all a:Action | not a.rf=a}
fact{all w:Writer&Reader | rl[w]=wl[w] }


// read/write from the same machine as the action destination
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }

//---- Init rules
// All memory locations must be initialized
fact{Init.wl=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not wl[i1]=wl[i2]}

//--- Local CPUAction Rules
fact {po_tc=^po_tc}
fact {po_tc=~copo}
fact{not cyclic[po_tc]}
fact{all a,b:Action| b in a.po iff ((b in a.po_tc) and #(a.po_tc - b.po_tc)=1)} // for displaying po. 
fact {all a: LocalCPUaction| localMachineAction[a]}
fact {all disj a,b: LocalCPUaction| 
                                      (o[a] = o[b])
                                      iff
                                      (
                                        (a in b.po_tc) or
                                        (a in b.copo) 
                                      )
}

// holds here because of explicit def of actions, one shared -> all shared -> equal
//check{all disj i1,i2:Instruction | #(actions[i1]&actions[i2])=0} for 8 expect 0
//alternative formulation 
//run{some disj i1,i2:Instruction | #(actions[i1]&actions[i2])>0} for 8

pred p { 
           #Put = 1 and
            #Thr = 2}


run p for 8
