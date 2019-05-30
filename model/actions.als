/* Threads */
sig Thr {}

abstract sig Action {
	/* program order, consistency order */
	po : set Action, 

	/* destination and origin thread of the action */	
	d, o : one Thr
}

abstract sig Sx extends Action{}

abstract sig LocalAction extends Action{}
fact { all a: LocalAction| o[a] = d[a]}

/*CPU read*/
sig R extends LocalAction{}
fact {all r:R| r in Reader and not(r in Writer)}

/*CPU write*/
sig W extends LocalAction{}
fact {all w:W| w in Writer and not(w in Reader)}

/*NIC action*/
abstract sig nA extends Action{}

/*NIC Read*/
abstract sig nR extends nA{}
fact {all r:nR| r in Reader and not(r in Writer)}

/*NIC remote read*/
sig nRpq extends nR{}

/*NIC local read*/
sig nRp extends nR{}

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

/*c-atomics*/
sig U extends LocalAction {}
fact {all u:U| u in Writer and u in Reader}

/*RDMA Fence*/
sig nFpq extends Action {}
fact {all f:nFpq| not(f in Writer) and not (f in Reader)}

/*poll_cq*/
sig poll_cq extends Action {}
fact {all p:poll_cq| not(p in Writer) and not (p in Reader)}

sig Sx_put extends Sx {}

sig Sx_cas extends Sx {}

sig Reader in Action {}

sig Writer in Action {}

pred show { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2}

run show for 10
