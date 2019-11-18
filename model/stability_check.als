open util/integer

abstract sig Boolean {} // Ask Andrei:  why not use pred?
one sig True, False extends Boolean {}

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

/* Local Variables*/
sig Register{
  o: one Thr,
  value: one Int
}

fact { all r: Register| o[r] = o[~reg[r]]  and 
								  value[r] = rV[~reg[r]]}

abstract sig Action {

	/* destination and origin thread of the action */	
	d, o : one Thr
}

sig MemoryAction in Action{
	loc: one MemoryLocation
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }

sig Reader in MemoryAction {
	rV: one Int,
	corf: one Writer
}


sig Writer in MemoryAction{
	wV: one Int,
	rf: set Reader
}

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
abstract sig Sx extends LocalCPUaction{}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}


sig nEx extends nA {
    poll_cq_sw: lone poll_cq
}
fact {all a:nEx| not(a in Writer) and not (a in Reader)
                       and localMachineAction[a]}

/*CPU read*/
sig R extends LocalCPUaction{
   reg : one Register
}
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
abstract sig nA extends Action{}

fact {all a:nA| (a in RDMAaction)}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}
//fact {all a: nRpq| remoteMachineAction[a]}

/*NIC local read*/
sig nRp extends nR{}
//fact {all a: nRp| localMachineAction[a]}

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

/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}
fact {all a:poll_cq| not (a in RDMAaction)}
/* RDMA instructions and the actions that compose them*/



//--- Reader/Writer rules

fact{all w:Writer, r:Reader | corf[r]=w iff r in rf[w]}
//rf implies shared location and value
fact{all w:Writer, r:Reader | corf[r]=w iff (loc[r]=loc[w] and rV[r]=wV[w])}



// holds here because of explicit def of actions, one shared -> all shared -> equal
//check{all disj i1,i2:Instruction | #(actions[i1]&actions[i2])=0} for 8 expect 0
//alternative formulation 
//run{some disj i1,i2:Instruction | #(actions[i1]&actions[i2])>0} for 8




abstract sig Execution {
// actions: set Actions,
// po: Action->Action,
// rf: Action->Action,
// sw: Action->Action,
 mo: Writer->set Writer,
 mo_next: Writer->lone Writer,
 mos: Writer->set Writer,
 hb: Action-> set Action,
 //hbqp: Action->set Action,
 hbs: Action->set Action,
 Consistent: Boolean
}{
//mo_s definition
   mos= (nRWpq+U) <: mo

  {
   ( hb_cyclic or cyclic_MoThenHb 
      or {some a1,a2:Writer,a3:Reader | 
         missPrevWrite3[a1,a2,a3]  
         or missPrevWrite4[a1,a2,a3]
         or missPrevWrite5[a1,a2,a3] 
         or missPrevWrite6[a1,a2,a3]
         or missPrevWrite7[a1,a2,a3] 
         or missPrevWrite8[a1,a2,a3]
         or missPrevWrite9[a1,a2,a3]
    })
   implies Consistent=False else Consistent=True
  }
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

pred cyclic_MoThenHb[e:Execution] {
      cyclic[(W<:(e.hb)).(e.mo)]//consistentcy 2
}


pred missPrevWrite3[e:Execution,a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 3
    a3 in a2.(e.hb) and 
	a2 not in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}

pred missPrevWrite4[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer|
    a3 in a1.rf and // consistency 4
    a4 in a2.(e.mo) and
	a3 in a4.po.(^sw).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite5[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 5
    a4 in a2.(e.mo) and
	a3 in a4.(rf-po_tc).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite6[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer|
    a3 in a1.rf and // consistency 6
    a4 in a2.(e.mos) and
	a3 in a4.(e.hb) and 
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite7[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 7
    a4 in a2.(rf-sw) and
	a3 in a4.(e.hb) and 
	a2 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite8[e:Execution, a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 8
    a3 in a2.sw and
	a2 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite9[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 8
    a4 in a2.(e.mo) and
    a3 in a4.(rf-sw).(e.hb) and
	a4 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}

one sig RDMAExecution extends Execution{

}{
//mo basic definition
   {mo=^mo}
   {not cyclic[mo]}
    {mo_next=mo-mo.mo}

  {all disj w1,w2:Writer | 
                 (host[loc[w1]]=host[loc[w2]]) 
                 <=> 
                ((w1 in w2.mo) or (w2 in w1.mo))
   }
//{all w1,w2:Writer | w1 in w2.mo_next <=> (w1 in w2.mo and #(w2.mo-w1.mo)=1)}
{all i:Init, a:Writer-Init| not i in mo[a]}

  hb = ^(po_tc+rf+sw+mos)
/*
//hbqp definition
  hbqp in hb
  {all a: Action, b:a.hb|  b in a.hbqp
   <=>(
      (not a in nWpq)
       or
      (a + b in nA and sameOandD[a,b])// on the same queue pair
      or
      (b in a.rf)
      )
  }// end hbqp defintion
*/
//hbs definition 
  hbs=^(po_tc+rf +sw+mos)

}// end of sig execution

fact {RDMAExecution.Consistent=True}

pred Test1 [] {
 some disj iv0: Init,
disj X: MemoryLocation,
disj n0: Node, 
disj p0: Thr | 
 //#Action = 13

/* Process 0 */
/* and */host[p0] = n0

 /* X=0 */ 
 and o[iv0] = p0
 and loc[iv0] = X
 and wV[iv0] = 0
}

run Test1 for 5

