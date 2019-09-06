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

sig Writer in Action {
  wl: one MemoryLocation,
  wV: one Int,
  rf: set Reader
}

fact{~rf=corf}

/* RDMA instructions and the actions that compose them*/
abstract sig Instruction {
  actions: set Action
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}


abstract sig Sx extends LocalCPUaction{
  instr: one Instruction,
  instr_sw: one nA
}
fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}


sig Sx_cas extends Sx {}

sig RDMAaction in Action {
    sw : set Action
}

fact { all l: LocalCPUaction| o[l] = d[l]}

/*NIC action*/
abstract sig nA extends Action{
  instr: one Instruction,
    instr_sw: lone nA, 
    nic_ord_sw: set nA
}
fact {all a:nA| (a in RDMAaction)}


/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}
fact { all a: nRWpq| not host[o[a]] = host[d[a]]}

/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}
fact {all a: nF| localMachineAction[a]}


/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| o[a] = d[a]}


sig Reader in Action {
  rl: one MemoryLocation,
  rV: one Int,
  corf: one Writer
}


// read/write from the same machine as the action destination
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }


/* =============== */
/* Remote Cas Instruction */
/* =============== */
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


/* construction of sw */

//defined per instruction in action file

fact{all a:Sx |
  a.sw = a.instr_sw
}

fact{all a:nA |
  a.sw = a.nic_ord_sw+a.instr_sw//+a.poll_cq_sw
}
//small optimization
fact{all a:nA | a.nic_ord_sw=none }

//-----------
/**instr-sw**/
//-----------

fact{all cas:CasF | // sx->nf->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nf=actions[cas] & nF,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
       #(instr_sw[nwp])=0
     }
}



sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}

sig Init extends W{}

// All memory locations must be initialized
fact{Init.wl=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not wl[i1]=wl[i2]}



// assign some initial value
fact { all w:Writer | w.wV = 4 }
/*
// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:Writer | w.wl = ml }
// ... and one initial value
fact { all ml:MemoryLocation | some iv:InitialValue | iv.wl = ml }

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

fact { #MemoryLocation = 2 and #Thr = 2 and #Init = 2 and #CasF = 1}

pred show {}

run show for 8
