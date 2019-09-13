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

fact {po_tc=^po_tc}
fact {po_tc=~copo}
fact{not cyclic[po_tc]}
fact{all a,b:Action| b in a.po iff ((b in a.po_tc) and #(a.po_tc - b.po_tc)=1)} // for displaying po. 
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

sig Reader in Action {
  rl: one MemoryLocation,
  rV: one Int,
  corf: one Writer
}

//--- Reader/Writer rules

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | rl[r]=wl[w] and rV[r]=wV[w]}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}
fact {all a: W| localMachineAction[a]}

sig RDMAaction in Action {
    sw : set Action
}

/* RDMA instructions and the actions that compose them*/
abstract sig Instruction {
  actions: set Action
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}

fact {all a: Sx| all i: Instruction | instr[a] = i iff a in i.actions}
fact {all a: nA| all i: Instruction | instr[a] = i iff a in i.actions}

abstract sig Sx extends LocalCPUaction{
  instr: one Instruction,
  instr_sw: one nA
}
fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact {all sx: Sx| (sx in RDMAaction)}
fact {all a: Sx| remoteMachineAction[a]}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {
  co_poll_cq_sw:one nA
}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}
fact {all a:poll_cq| not (a in RDMAaction)}
fact {all a:poll_cq| remoteMachineAction[a]}


sig Sx_put extends Sx {}


/*NIC action*/
abstract sig nA extends Action{
	instr : one Instruction,
	instr_sw: lone nA,
    nic_ord_sw: set nA,
    poll_cq_sw: lone poll_cq
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
fact {all a: nRp| localMachineAction[a]}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| remoteMachineAction[a]}

/* =============== */
/* Remote Put statement */
/* =============== */


sig Put extends Instruction {}{ 
  #actions = 3 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1    and 
  (let sx= actions&Sx,
   nrp=actions & nRp,
      nwpq=actions & nWpq{
       rV[nrp] = wV[nwpq] and
		sameOandD[sx,nwpq]
   })
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


//------------
/** poll_cq_sw **/
//------------
fact{poll_cq_sw=~co_poll_cq_sw}


fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx { //sx->na1->na2 ---pol_cq_sw---> pcq
      (na2 in instr_sw[na1] ) and 
      (na1 in instr_sw[sx] ) and
      sameOandD[pcq,sx] and
      (pcq in sx.po_tc) and
          (// num act submitted = num actions acknowledged
           #(sx.^~po_tc & {a:Sx | sameOandD[a,sx]}) 
                = #(pcq.^~po_tc & {a:poll_cq | sameOandD[a,pcq]})
           )
  }//end of some na1,sx
  )
}

fact {all nr:(nA&Reader),nw:(nA&Writer) | nw in nr.instr_sw => wV[nw]=rV[nr]}

fact{all a:Sx |
  a.sw = a.instr_sw
}

fact{all a:nA |
  a.sw = a.nic_ord_sw+a.instr_sw+a.poll_cq_sw
}

sig Init extends W{}

//---- Init rules
// All memory locations must be initialized
fact{Init.wl=MemoryLocation}

// Init or a sequence of it is the first instruction
fact{Init.~po_tc in Init}

// one Init per one location
fact  {all disj i1,i2:Init| not wl[i1]=wl[i2]}

// assign some initial value
fact { all w:Writer | w.wV = 4 }



// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation > 1 and #Thr = 2 and #Node = 2 and #Init > 0 
		and #(poll_cq & Sx_put.po_tc) > 0 and #poll_cq = 1 }

pred oneThread { #Thr = 1 }
pred twoThreads { #Thr = 2 }


pred show {}

run show for 8
