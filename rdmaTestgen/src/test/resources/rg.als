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
fact {po_tc=^po_tc}
fact {po_tc=~copo}
fact{not cyclic[po_tc]}
fact{all a,b:Action| b in a.po iff ((b in a.po_tc) and #(a.po_tc - b.po_tc)=1)} // for displaying po. 
fact {all a: LocalCPUaction| localMachineAction[a]}
fact {all disj a,b: LocalCPUaction| 
                                      (o[a] = o[b])
                                      iff
                                      (
                                        (a in b.po_tc) or
                                        (a in b.copo) 
                                      )
}


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

//--- Reader/Writer rules
fact{~rf=corf}

//rf implies shared location and value
fact{all w:Writer, r:rf[w] | rl[r]=wl[w] and rV[r]=wV[w]}

// read/write from the same machine as the action destination
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }

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


sig Sx_get extends Sx {}

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
/*NIC remote read*/
sig nRpq extends nR{}
fact {all a: nRpq| remoteMachineAction[a]}


/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| localMachineAction[a]}

/* =============== */
/* Remote Get statement */
/* =============== */

sig Get extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1   and 
  (let nrpq=actions & nRpq,
      nwp=actions & nWp{
       rV[nrpq] = wV[nwp]
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
fact{all get:Get | // sx->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}
fact {all a:W| not(a in RDMAaction)}

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

fact { #MemoryLocation = 2 and #Thr = 2 and #Init = 2 and #Writer = 3 and #Get = 1}

pred show {}

run show for 5
