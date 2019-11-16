open util/integer
sig Node {}

sig Thr { 
	host: one Node // host node
}
sig MemoryLocation { host: one Node }

abstract sig Action {
    o, d: one Thr
}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }
pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}

abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
	copo : set LocalCPUaction
}
//--- Local CPUAction Rules

fact{po_tc=^po_tc
         and(po_tc=~copo) // for displaying po. 
        and(po=po_tc-po_tc.po_tc)
		and not cyclic[po_tc]
}

sig Reader in MemoryAction {
	rV: one Int,
	corf: one Writer
}
sig MemoryAction in Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Writer in MemoryAction {
	wV: one Int,
	rf: set Reader
}

//--- Reader/Writer rules
fact{~rf=corf}

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | loc[r]=loc[w] and rV[r]=wV[w]}


sig RDMAaction in Action {
	instr : one Instruction,
	instr_sw: lone nA,
    sw : set Action
}
/* RDMA instructions and the actions that compose them*/

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)
		and (sx in RDMAaction)
		and remoteMachineAction[sx]
}


sig nEx extends nA {
    //poll_cq_sw: lone poll_cq
}

fact {all a:nEx| not(a in Writer) and not (a in Reader)
                       and remoteMachineAction[a]}

/*NIC action*/
abstract sig nA extends Action{
    nic_ord_sw: set nA,
    nic_ord_sw_s: set nA,
 //   poll_cq_sw_s: lone poll_cq,
	ipo: set nA
}
fact {all a:nA| (a in RDMAaction)}
fact {all a1,a2:nA| 
			(a2 in a1.ipo) iff (
				(a2.instr.sx) 
                       in (a1.instr.sx.po_tc)
			)
}
/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}


/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}
fact { all a: nRWpq| remoteMachineAction[a]}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| localMachineAction[a]}

/* construction of sw */

sig Sx extends LocalCPUaction{}

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.instr_sw//+a.poll_cq_sw
}
//small optimization
fact{all a:nA | a.nic_ord_sw=none }
                      
//-----------
/**instr-sw**/
//-----------
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

abstract sig NFInstruction extends Instruction{}{
  #actions = 4
}



sig Rga extends NFInstruction {
	nrwpq: one nRWpq,
	nwp: one nWp
}{
  (nrwpq in actions) and 
  (nwp in actions)  
}


//-----------
/**instr-sw**/
//-----------


fact{all rga:Rga | // sx->nrwpq->nwp
          instr_sw[rga.sx] = rga.nrwpq and
          instr_sw[rga.nrwpq] = rga.nwp and
		  instr_sw[rga.nwp]=rga.ex    and
          instr_sw[rga.ex]=none  
}

sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}

sig Init extends W{}

//---- Init rules
// All memory locations must be initialized
fact{Init.loc=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not loc[i1]=loc[i2]}

// assign some initial value
fact { all w:Writer | w.wV = 4 }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation = 2 and #Thr = 2 and #Init = 2 and #Rga = 1}

pred show {}

run show for 8
