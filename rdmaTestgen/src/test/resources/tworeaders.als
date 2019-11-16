open util/integer

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}
pred localMachineAction [a:Action] { host[o[a]]=host[d[a]] }

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
abstract sig LocalCPUaction extends Action{
	/* program order */
	po_tc : set LocalCPUaction,
    po: lone LocalCPUaction, // for displaying po.
	copo : set LocalCPUaction
}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}

/*CPU read*/
sig R extends LocalCPUaction{
   // reg : one Register
}
fact{po_tc=^po_tc
         and(po_tc=~copo) // for displaying po. 
        and(po=po_tc-po_tc.po_tc)
		and not cyclic[po_tc]
}


fact {all r:R| r in Reader and not(r in Writer)
	//			and not(r in RDMAaction)
				and localMachineAction[r]}

sig Init extends W{}

fact { all r:Reader | r.rV = 4 }

fact { #MemoryLocation = 2 and #Thr = 2 and #R = 2 }

pred show {}

run show for 4
