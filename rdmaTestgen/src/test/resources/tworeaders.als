open util/integer

pred cyclic [rel:Action->Action] {some a:Action | a in ^rel[a]}

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

sig MemoryAction extends Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Writer extends MemoryAction {
	wV: one Int,
	rf: set Reader
}

sig Reader extends MemoryAction {
	rV: one Int,
	corf: one Writer
}

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


fact {all r:R| r in Reader and not(r in Writer)}


sig Init extends W{}

fact { all r:Reader | r.rV = 4 }

fact { #MemoryLocation = 2 and #Thr = 2 and #R = 2 }

pred show {}

run show for 4
