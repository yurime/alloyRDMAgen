open util/integer
sig Node {}

sig Thr { 
  host: one Node // host node
}
sig MemoryLocation { host: one Node }

abstract sig Action {
    o, d: one Thr
}
abstract sig LocalCPUaction extends Action{
  /* program order */
  po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
  copo : set LocalCPUaction
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }

fact{po_tc=^po_tc
         and(po_tc=~copo) // for displaying po. 
        and(po=po_tc-po_tc.po_tc)
		and not cyclic[po_tc]
}



sig MemoryAction in Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Writer in  MemoryAction {
  wV: one Int,
  rf: set Reader
}

fact{~rf=corf}

sig Reader in  MemoryAction {
  rV: one Int,
  corf: one Writer
}

//--- Reader/Writer rules

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | loc[r]=loc[w] and rV[r]=wV[w]}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}


sig nEx extends nA {
   // poll_cq_sw: lone poll_cq
}
fact {all a:nEx| not(a in Writer) and not (a in Reader)
                       and remoteMachineAction[a]}


sig RDMAaction in Action {
	instr : one Instruction,
	instr_sw: lone nA,
    sw : set Action
}

fact{all a:RDMAaction|
    remoteMachineAction[a] => (sameOandD[a,a.instr.sx]
                                             and sameOandD[a,a.instr.ex])
}
fact {all a:RDMAaction| all i: Instruction | instr[a] = i iff a in i.actions}

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
abstract sig FInstruction extends Instruction{
    nf:one nF
}{
(nf in actions) and
(#actions = 5)
}

/* start NIC action (start external)*/
sig Sx extends LocalCPUaction{}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)
		and (sx in RDMAaction)
		and remoteMachineAction[sx]
}


/*NIC action*/
abstract sig nA extends Action{
    nic_ord_sw: set nA,
    nic_ord_sw_s: set nA,
 //   poll_cq_sw_s: lone poll_cq,
	ipo: set nA
}
fact {all a:nA| (a in RDMAaction)}
fact {all disj a1,a2:nA| 
			(a2 in a1.ipo) iff (
				(a2.instr.sx) 
                       in (a1.instr.sx.po_tc)
			)
}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}


/*NIC remote read*/
sig nRpq extends nR{}
fact {all a: nRpq| remoteMachineAction[a]}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| localMachineAction[a]}

/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| localMachineAction[a]}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| remoteMachineAction[a]}

/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}
fact {all a: nF| localMachineAction[a]}

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

//-------------
/**nic-ord-sw**/
//-----------

fact{all a:nA | not a in nic_ord_sw[a]}

// predicates to define when nic_ord_sw is legal
fact{all put:Put | // sx->nrp->nwpq
          instr_sw[put.sx] = put.nrp and
          instr_sw[put.nrp] = put.nwpq and
		  instr_sw[put.nwpq]=put.ex   and
          instr_sw[put.ex]=none  
}


// predicates to define when nic_ord_sw is legal
pred putOrRDMAatomic [na1:nA,na2:nA] {
           (na2 in na1.ipo) and//forcing same queuepair and starting thread
  	       (remoteMachineAction[na1]) and   // sx1----->nWpq
	       (remoteMachineAction[na2]) and   // ↓po         ↓nic_ord_sw
	       (not na1 in nRpq)                         // sx2----->na2 
}

pred putLocalPart [na1:nA,na2:nA]{
           (na2 in na1.ipo) and//forcing same queuepair and starting thread
	      (na2+na1 in nRp)		// sx1----->nRp
											// ↓po         ↓nic_ord_sw
									        // sx2----->nRp 
}


// (na1,na2) in nic_ord_sw definition (3 cases)
fact{all disj na1,na2:nA |
  (na2 in nic_ord_sw[na1]) 
  iff
  (  putOrRDMAatomic[na1,na2] 
	  or 
      putLocalPart[na1,na2]
	  //or 
	  //nicFence[na1,na2]
  )//end iff
}

//-----------
/**instr-sw**/
//-----------



fact {all nr:(nA&Reader),nw:(nA&Writer) | nw in nr.instr_sw => wV[nw]=rV[nr]}

fact{all a:Sx |
  a.sw = a.instr_sw
}

fact{all a:nA |
  a.sw = a.nic_ord_sw+a.instr_sw//+a.poll_cq_sw
}

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

fact {#(Node)=2 and #(Thr)=2
        and #(Put.sx & Put.sx.po_tc) =1}

pred show {}


run show for 10
