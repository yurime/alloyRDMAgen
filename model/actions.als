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

fact{all r:Register| #(~reg[r])=1
                 and  o[r] = o[~reg[r]] }

abstract sig Action {
	/* destination and origin thread of the action */	
	d, o : one Thr
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }

sig MemoryAction in Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Reader in MemoryAction {
	rV: one Int,
	corf: one Writer
}


sig Writer in MemoryAction {
	wV: one Int,
	rf: set Reader
}

fact{~rf=corf}

sig Init extends W{}

sig RDMAaction in Action {
	instr : one Instruction,
	instr_sw: lone nA,
    sw : set Action//,
    //sw_s : set Action
}

abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
	copo : set LocalCPUaction
}

//fact{all a: LocalCPUaction | a.po = a.po_tc - a.po_tc.po_tc} // for displaying po. 

fact{po_tc=^po_tc
         and(po_tc=~copo) // for displaying po. 
        and(po=po_tc-po_tc.po_tc)
		and not cyclic[po_tc]
}

/* start NIC action (start external)*/
sig Sx extends LocalCPUaction{}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)
		and (sx in RDMAaction)
		and remoteMachineAction[sx]
}
/*CPU read*/
sig R extends LocalCPUaction{
   reg : one Register
}
fact {all r:R| r in Reader and not(r in Writer)
				and not(r in RDMAaction)
				and localMachineAction[r]}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)
				and not(w in RDMAaction)
				and localMachineAction[w]}

/*c-atomics*/
sig U extends LocalCPUaction {}
fact {all u:U| u in Writer and u in Reader
				and not(u in RDMAaction)
				and localMachineAction[u]}
/*NIC action*/
abstract sig nA extends Action{
    nic_ord_sw: set nA,
//    nic_ord_sw_s: set nA,
//    poll_cq_sw_s: lone poll_cq,
	ipo: set nA
}
fact {all a:nA| (a in RDMAaction)}
fact {all a1,a2:nA| 
			(a2 in a1.ipo) iff (
				(a2.instr.sx) 
                       in (a1.instr.sx.po_tc)
			)
}

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
fact {all rw:nRWpq| rw in Writer and rw in Reader
                       and remoteMachineAction[rw]}


/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)
                       and  localMachineAction[f]}


sig nEx extends nA {
    poll_cq_sw: lone poll_cq
}
fact {all a:nEx| not(a in Writer) and not (a in Reader)
                       and localMachineAction[a]}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {
  co_poll_cq_sw:one nEx
}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)
                             and not (p in RDMAaction)
                             and remoteMachineAction[p]}
/* RDMA instructions and the actions that compose them*/
abstract sig Instruction {
	actions: set RDMAaction,
    sx:one Sx,
    ex:one nEx
}{
  (one o[actions])
  and (ex in actions) 
  and (sx in actions) 
}

/*fact {all disj i1,i2: Instruction | 
                   and (0=#(i1.actions & i2.actions))
        }
*/
fact{all a:RDMAaction|
    remoteMachineAction[a] => (sameOandD[a,a.instr.sx])
}
fact {all a:RDMAaction| all i: Instruction | instr[a] = i iff a in i.actions}

abstract sig NFInstruction extends Instruction{}{
  #actions = 4
}
abstract sig FInstruction extends Instruction{
    nf:one nF
}{
(nf in actions) and
(#actions = 5)
}

sig Put extends NFInstruction {
	nrp: one nRp,
	nwpq: one nWpq
}{  
  (nrp in actions) and 
  (nwpq in actions)
}

sig Get extends NFInstruction {
	nrpq: one nRpq,
	nwp: one nWp
}{
  (nrpq in actions) and 
  (nwp in actions) 
}

sig Rga extends NFInstruction {
	nrwpq: one nRWpq,
	nwp: one nWp
}{
  (nrwpq in actions) and 
  (nwp in actions)  
}

sig Cas extends NFInstruction {
	nrwpq: one nRWpq,
	nwp: one nWp
}{
  (nrwpq in actions) and 
  (nwp in actions) 
}

// instructions with a nic fence
sig PutF extends FInstruction {
	nrp: one nRp,
	nwpq: one nWpq
}{ 
  (nrp in actions) and 
  (nwpq in actions) 
}
sig GetF extends FInstruction {	
    nrpq: one nRpq,
	nwp: one nWp
}{
  (nrpq in actions) and 
  (nwp in actions)
}
sig RgaF extends FInstruction {
	nrwpq: one nRWpq,
	nwp: one nWp
}{
  (nrwpq in actions) and 
  (nwp in actions)
}

sig CasF extends FInstruction {
	nrwpq: one nRWpq,
	nwp: one nWp
}{
  (nrwpq in actions) and 
  (nwp in actions)
}



//--- Reader/Writer rules

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | loc[r]=loc[w] and rV[r]=wV[w]}

// atomic actions non recursive and atomic to one location
fact{all w:Writer&Reader | not w.rf=w}



//---- Init rules
// All memory locations must be initialized
fact{Init.loc=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not loc[i1]=loc[i2]}

//--- Local CPUAction Rules

fact{not cyclic[po_tc+rf]}
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

pred getThenPutF {  // needs at least 12
            #Get > 0 and
            #PutF > 0 and
            #poll_cq = 2  and
			 #(Get.sx.po_tc) > 0 and
			 #(poll_cq & Get.sx.po_tc) > 0 and
            #Thr = 2}

pred putAfterPut { 
            #Put >1 and
            #poll_cq >1   and
			 #(Put.sx & Put.sx.po_tc) > 0 and
            #Thr = 2}


pred putAndCas { 
           #Put = 1 and
            #Cas = 1 and
            #Thr = 2}

run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 10

run p for 10
