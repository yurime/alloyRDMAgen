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
    sw : set Action
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
}

/* start NIC action (start external)*/
sig Sx extends LocalCPUaction{}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)
		and (sx in RDMAaction)
		and remoteMachineAction[sx]
}


/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)
				and not(w in RDMAaction)
				and localMachineAction[w]}


/*NIC action*/
abstract sig nA extends Action{
 //   nic_ord_sw: set nA,
	ipo: set nA
}
fact {all a:nA| (a in RDMAaction)}
fact {all a1,a2:nA| 
			(a2 in a1.ipo) iff (
				(a2.instr.sx) 
                       in (a1.instr.sx.po_tc)
			)
}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| localMachineAction[a]}


/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| remoteMachineAction[a]}


sig nEx extends nA {
}
fact {all a:nEx| not(a in Writer) and not (a in Reader)
                       and remoteMachineAction[a]}

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
fact{all a:RDMAaction|
    remoteMachineAction[a] => (sameOandD[a,a.instr.sx]
                                             and sameOandD[a,a.instr.ex])
}
fact {all a:RDMAaction| all i: Instruction | instr[a] = i iff a in i.actions}

abstract sig NFInstruction extends Instruction{}{
  #actions = 4
}
/* =============== */
/* Remote Put statement */
/* =============== */

sig Put extends NFInstruction {
	nrp: one nRp,
	nwpq: one nWpq
}{  
  (nrp in actions) and 
  (nwpq in actions)
}

//-----------
/**instr-sw**/
//-----------
fact{all put:Put | // sx->nrp->nwpq
          instr_sw[put.sx] = put.nrp and
          instr_sw[put.nrp] = put.nwpq and
		  instr_sw[put.nwpq]=put.ex  
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


//--------------------------------------------



fact{all a:Sx |
	a.sw = a.instr_sw
}

fact{all a:nA |
	a.sw = a.instr_sw//+ a.nic_ord_sw+a.poll_cq_sw
}
//small optimization
//fact{all a:nA | a.nic_ord_sw=none }

// assign some initial value
fact { all w:Writer | w.wV = 4 }
/*

// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:Writer | w.loc = ml }
// ... and one initial value
fact { all ml:MemoryLocation | some iv:InitialValue | iv.loc = ml }

// a writer succeeds initial value
fact { all iv : InitialValue | one w:Writer | w in po[iv] }

// initial value is indeed initial
fact { all iv : InitialValue | no w:Writer | iv in po[w] }

// partial order doesn't have cycles
fact { no a: Action | a in a.^po }

// po doesn't cross threads
fact { all x,y : Action | x in po[y] => x.o = y.o }

*/
// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation = 2 and #Thr = 2 and #Init >= 2 and #Put = 1}

pred show {}

run show for 7
