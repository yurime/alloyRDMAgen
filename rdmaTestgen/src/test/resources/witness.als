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

fact { all r: Register| host[r] = o[~reg[r]] }

abstract sig Action {

	/* destination and origin thread of the action */	
	d, o : one Thr
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred sameOandD [a,b:Action] {o[a]=o[b] and  d[a]=d[b] }

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

sig RDMAaction in Action {
    sw : set Action
}

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | rl[r]=wl[w] and rV[r]=wV[w]}

// read/write from the same machine as the action destination
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }

sig Init extends W{}

//---- Init rules
// All memory locations must be initialized
fact{Init.wl=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not wl[i1]=wl[i2]}


abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
	copo : set LocalCPUaction
}
fact {po_tc=^po_tc}
fact {po_tc=~copo}
fact{not cyclic[po_tc]}
fact{all a,b:Action| b in a.po iff ((b in a.po_tc) and #(a.po_tc - b.po_tc)=1)} // for displaying po. 
fact {all a: LocalCPUaction| o[a] = d[a]}
fact {all disj a,b: LocalCPUaction| 
                                      (o[a] = o[b])
                                      iff
                                      (
                                        (a in b.po_tc) or
                                        (a in b.copo) 
                                      )
}


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

/* start NIC action (start external)*/
abstract sig Sx extends LocalCPUaction{
	instr: one Instruction,
	instr_sw: one nA
}

fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}

sig Sx_put extends Sx {}


/*NIC action*/
abstract sig nA extends Action{
	instr: one Instruction,
    instr_sw: lone nA, 
    nic_ord_sw: set nA//,
    //poll_cq_sw: lone poll_cq 
}
fact {all a:nA| (a in RDMAaction)}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}


/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}


/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| not host[o[a]] = host[d[a]]}


/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| o[a] = d[a]}



/* RDMA instructions and the actions that compose them*/
abstract sig Instruction {
	actions: set Sx+nA
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}

fact {all i: Instruction |all a:i.actions&Sx | instr[a] = i}
fact {all i: Instruction |all a:i.actions&nA | instr[a] = i}

/* =============== */
/* Remote Put statement */
/* =============== */

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



/* construction of sw */

//defined per instruction in action file

fact{all a:Sx |
	a.sw = a.instr_sw
}

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.instr_sw//+a.poll_cq_sw
}
//-----------
/**instr-sw**/
//-----------

fact{all put:Put | // sx->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}



/* Witness */
one sig Witness in Reader {
}

fact {#Witness = 1}

// assign some initial value
fact { all w:Writer | w.wV = 4 }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation = 2 and #Thr = 2 and #Init >= 2 and #Put= 1}

pred show {}

run show for 6
