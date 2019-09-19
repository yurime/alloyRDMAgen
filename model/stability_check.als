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

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }
pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
//pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }

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

sig RDMAaction in Action {
    sw : set Action
}

abstract sig LocalCPUaction extends Action{
	/* program order */
    po: lone LocalCPUaction
}

/* start NIC action (start external)*/
abstract sig Sx extends LocalCPUaction{}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}

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
fact{all w:Writer, r:Reader | corf[r]=w iff (rl[r]=wl[w] and rV[r]=wV[w])}



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
//mo_next: Writer->lone Writer,
 mos: Writer->set Writer,
 hb: Action-> set Action,
 hbqp: Action->set Action,
 hbs: Action->set Action,
 Consistent: Boolean
}{
  {
   (hb_cyclic  or cyclic_MoThenHbs or readAndMissPrevWriteInHbs
   or tsoBufferCoherence1of3 or tsoBufferCoherence2of3  
   or tsoBufferCoherence3of3  or tsoFenceViolation)
   implies Consistent=False else Consistent=True
  }
{all i:Init, a:Writer-Init| not i in mo[a]}
//{all w1,w2:Writer | w1 in w2.mo_next <=> (w1 in w2.mo and #(w2.mo-w1.mo)=1)}
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

pred cyclic_MoThenHbs[e:Execution] {
      cyclic[(e.mo).(e.hbs)]
}

pred readAndMissPrevWriteInHbs [e:Execution] {
    some a,b,c:Action | a in c.corf and c in b.(e.hbs) and wl[a]=wl[b] and b in a.(e.mo)
}

pred tsoBufferCoherence1of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.((e.mo) & (Action->(Action-nWpq))).sw.(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoBufferCoherence2of3[e:Execution] {some a,b,c:Action | 
    c in a.rf and 
    (some d1,e1:Action |
        d1 in b.(e.mo) and
        e1 in d1.((e.hbs) & (nWpq->(nRpq+nRWpq))) and
        sameOandD[e1,d1] and
        c in e1.(e.hbs)
    ) and
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoBufferCoherence3of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.(e.mo).(rf-^po).(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoFenceViolation [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.(e.mos).(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}


one sig RDMAExecution extends Execution{

}{
  hb = ^(po+rf+sw)

//mo basic definition
  {all disj w1,w2:Writer | 
                 (host[wl[w1]]=host[wl[w2]]) 
                 <=> 
                ((w1 in w2.mo) or (w2 in w1.mo))
   }
   {mo=^mo}
   {not cyclic[mo]}

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

//mo_s definition
   mos in mo
  {all w1:Writer| all w2:w1.mo| w2 in w1.mos iff w1 in nRWpq+U+nWp}

//hbs definition 
  hbs=^(hbqp+mos)

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
 and wl[iv0] = X
 and wV[iv0] = 0
}

run Test1 for 5

