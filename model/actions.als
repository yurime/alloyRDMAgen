open util/integer

/* Machine with one or more Threads */
sig Node {}

/* Thread */
sig Thr {
	host: one Node // host node
}

/* Variables */
sig MemoryLocation {
  host: one Node
}

abstract sig Action {

	/* destination and origin thread of the action */	
	d, o : one Thr
}

abstract sig LocalCPUaction extends Action{
	/* program order, consistency order */
	po : lone LocalCPUaction
}
fact { all a: LocalCPUaction| o[a] = d[a] and not (a in a.^po)}
fact { all disj a,b: LocalCPUaction| 
(o[a] = o[b])
iff
(
  (a in b.^po) or
  (b in a.^po) 
)
}

/* start NIC action (start external)*/
abstract sig Sx extends LocalCPUaction{
	instr: one Instruction,
	instr_sw: one nA
}
fact {all sx: Sx| not (sx in Reader) and not (sx in Writer)}
fact{all disj s1,s2:Sx | not instr_sw[s1]=instr_sw[s2] }

/*CPU read*/
sig R extends LocalCPUaction{}
fact {all r:R| r in Reader and not(r in Writer)}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}

/*c-atomics*/
sig U extends LocalCPUaction {}
fact {all u:U| u in Writer and u in Reader}

/*NIC action*/
abstract sig nA extends Action{
	instr: one Instruction,
    instr_sw: lone nA, 
    nic_ord_sw: lone nA,
    poll_cq_sw: lone poll_cq 
}
//fact{all na:nA | not na in na.^nic_ord_sw}
//fact {nA in sw[nA] + sw[Sx] }//YM: all nA are connected by some sw (at the very least instr_sw) (is this forall exists?)
//fact {poll_cq in sw[nA] } // YM: every poll_cq is connected by sw from some relation.
//fact {all na:nA | not na in sw[na]}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}
fact { all a: nRpq| not host[o[a]] = host[d[a]]}

/*NIC local read*/
sig nRp extends nR{}
fact { all a: nRp| o[a] = d[a]}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer and not(w in Reader)}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| not host[o[a]] = host[d[a]]}

/*NIC local write*/
sig nWp extends nW{}
fact { all a: nWp| o[a] = d[a]}

/*NIC read-write*/
sig nRWpq extends nA{}
fact {all rw:nRWpq| rw in Writer and rw in Reader}
fact { all a: nRWpq| not host[o[a]] = host[d[a]]}


/*RDMA Fence*/
sig nFpq extends nA {}
fact {all f:nFpq| not(f in Writer) and not (f in Reader)}
fact { all a: nFpq| not host[o[a]] = host[d[a]]}

/*poll_cq*/
sig poll_cq extends LocalCPUaction {}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}

abstract sig Instruction {
	actions: set Action
}{
  all disj a1,a2:actions | o[a1]=o[a2]
}

fact {all i: Instruction, sx: Sx| sx in actions[i] iff instr[sx] = i}
fact {all i: Instruction, a: nA| a in actions[i] iff instr[a] = i}

sig Put extends Instruction {}{ 
  #actions = 3 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1 and 
  let sx=actions & Sx_put, 
      nrp=actions & nRp,
      nwpq=actions & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

sig Get extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_get, 
      nrpq=actions & nRpq,
      nwp=actions & nWp{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

sig Rga extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_rga, 
      nrwpq=actions & nRWpq,
      nwp=actions & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

sig Cas extends Instruction {}{
  #actions = 3 and 
  #(actions & Sx_cas) = 1 and 
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_cas, 
      nrwpq=actions & nRWpq,
      nwp=actions & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

// instructions with a nic fence
sig PutF extends Instruction {}{ 
  #actions = 4 and 
  #(actions & Sx_put) = 1 and 
  #(actions & nFpq) = 1 and 
  #(actions & nRp) = 1 and 
  #(actions & nWpq) = 1 and 
  let sx=actions & Sx_put, 
      nfpq=actions & nFpq,
      nrp=actions & nRp,
      nwpq=actions & nWpq{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}
sig GetF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_get) = 1 and 
  #(actions & nFpq) = 1 and  
  #(actions & nRpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_get, 
      nfpq=actions & nFpq,
      nrpq=actions & nRpq,
      nwp=actions & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}
sig RgaF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_rga) = 1 and 
  #(actions & nFpq) = 1 and  
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_rga, 
      nfpq=actions & nFpq, 
      nrwpq=actions & nRWpq,
      nwp=actions & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

sig CasF extends Instruction {}{
  #actions = 4 and 
  #(actions & Sx_cas) = 1 and
  #(actions & nFpq) = 1 and   
  #(actions & nRWpq) = 1 and 
  #(actions & nWp) = 1 and 
  let sx=actions & Sx_cas, 
      nfpq=actions & nFpq, 
      nrwpq=actions & nRWpq,
      nwp=actions & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

sig Sx_put extends Sx {}

sig Sx_get extends Sx {}

sig Sx_rga extends Sx {}

sig Sx_cas extends Sx {}

sig Reader in Action {
	rl: one MemoryLocation,
	rV: one Int 
}


sig Writer in Action {
	wl: one MemoryLocation,
	wV: one Int,
	rf: set Reader
}


fact{Reader in rf[Writer]}
fact{all w:Writer| not w in rf[w]}
fact{all w:Writer, r:Reader| r in rf[w] implies (rl[r]=wl[w] and rV[r]=wV[w]) }
fact{all w:nRWpq+U | rl[w]=wl[w] }
fact{all r:Reader | host[rl[r]]=host[d[r]] }
fact{all w:Writer | host[wl[w]]=host[d[w]] }

fact {Writer=W+U+nW+nRWpq} // YM:More succinct, but for some reason removing per each sig
fact {Reader=R+U+nR+nRWpq} //       was slower.

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
           #PutF = 1 and
            #Sx_cas = 1 and
            #Thr = 2}

run p for 8
