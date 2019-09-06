open util/integer
sig Node {}

sig Thr { 
  host: one Node // host node
}
sig MemoryLocation { host: one Node }

abstract sig Action {
    o, d: one Thr
}

pred remoteMachineAction [a:Action] { not host[o[a]]=host[d[a]] }
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }


abstract sig LocalCPUaction extends Action{
  /* program order */
  po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
  copo : set LocalCPUaction
}

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}

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


sig RDMAaction in Action {
    sw : set Action
}

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


sig Sx_put extends Sx {}

fact { all l: LocalCPUaction| o[l] = d[l]}

/*NIC action*/
abstract sig nA extends Action{
  instr: one Instruction,
    instr_sw: lone nA, 
    nic_ord_sw: set nA
}
fact {all a:nA| (a in RDMAaction)}


/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}


/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC local read*/
sig nRp extends nR{}
fact {all a: nRp| o[a] = d[a]}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| not host[o[a]] = host[d[a]]}


/*RDMA Fence*/
sig nF extends nA {}
fact {all f:nF| not(f in Writer) and not (f in Reader)}
fact {all a: nF| localMachineAction[a]}


sig Reader in Action {
  rl: one MemoryLocation,
  rV: one Int,
  corf: one Writer
}

/* =============== */
/* Remote Put statement */
/* =============== */


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
//-----------
/**instr-sw**/
//-----------
fact{all put:PutF |// sx->nf->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nf=actions[put] & nF,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrp and
          instr_sw[nrp] = nwpq and
       #(instr_sw[nwpq])=0
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


fact{all a:Sx |
  a.sw = a.instr_sw
}

fact{all a:nA |
  a.sw = a.nic_ord_sw+a.instr_sw//+a.poll_cq_sw
}
//small optimization
fact{all a:nA | a.nic_ord_sw=none }

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

fact { #MemoryLocation = 2 and #Thr = 2 and #Init >= 2 and #PutF = 1}

pred show {}

run show for 7
