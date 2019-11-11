open base_sw_rules as b
open rdma_execution as e
/** General test requirement or optimizations**/

// eliminate unused nodes 
fact {Node = host[Thr]}

// read from all variables 
fact { loc[Reader] = MemoryLocation }

// eliminate unused threads 
fact {Thr = o[Action]}

// try to avoid Initialization threads
fact{all i:Init |host[o[i]] in host[o[Action-Init]] => #i.po_tc>0}


/* There should be at least one local read from each writer (except initial values)*/
fact {Writer - Init in corf[R]}

// each write has an effect (costly in instance finding)
//fact{all w1,w2:Writer | w1 = w2.(RDMAExecution.mo_next)  => not (wV[w1]=wV[w2])}


// /* Values written by local writes are increasing with CO */
// fact { all disj w1, w2: Write| (co[w1, w2, mlast]) implies wV[w2] > wV[w1]}

/* Generate distinct write values for initial values and local writes */
fact { all disj w1, w2: W+Init| not (wV[w1] = wV[w2])}

/* Values written by writes are between [0 .. #Write]*/
fact { all w: Writer| 0 <=  wV[w] and wV[w] < #W}


/** Specific test requirement or optimizations**/

// Prevent writing of the same value to have an observalble effect
fact{wV[nA1Pivot]=0 and 1=wV[nA2Pivot]}
fact{loc[nA1Pivot]=loc[nA2Pivot]}
fact{not nA2Pivot in Init}


/*
//The Witness op2: Theoreticaly should be possible
fact {Witness in nA1Pivot.rf and 
        nA1Pivot in Witness.(RDMAExecution_prime.hbs)
}
*/
/*
//The Witness op3:  faster solving (7716ms vs 62789ms) less generic
fact {Witness in nA1Pivot.rf and 
        Witness in nA2Pivot.hbs and
        Witness in Witness2.po_tc
}
*/



// preventing the put to read from after the sx (legitimate but bad programming practice)
// is value undefined?
fact{all nrp:nRp| not(corf[nrp] in nrp.instr.sx.po_tc )}


/*
//avoid unrelated actions -- a lot slower
fact{all a:Action| let e=RDMAExecution |
							(a in Witness.sw) or (Witness in a.(e.hb))
							or (a in nA1Pivot.sw) or (nA1Pivot in a.(e.hb))
							or (a in nA2Pivot.sw) or (nA2Pivot in a.(e.hb))
							or(0<#(R & a.po)) 
}
*/
/* removes Univ objects */
sig Dummy {}
fact { no Dummy }

fact{RDMAExecution_prime.Consistent=True}

pred oneThread { #Thr = 1 }
pred twoThreads { #Thr = 2 }
pred threeThreads { #Thr = 2 }

/* Properties of the test */
pred consist_lw_lw {
            (nA1Pivot in W) and
           (nA2Pivot in W) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_lw_nwp {
            (nA1Pivot in W) and
           (nA2Pivot in nWp) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_lw_nwpq {
            (nA1Pivot in W) and
           (nA2Pivot in nWpq) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

pred consist_nwp_lw {
            (nA1Pivot in nWp) and
           (nA2Pivot in W) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_nwp_nwp {
            (nA1Pivot in nWp) and
           (nA2Pivot in nWp) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_nwp_nwpq {
            (nA1Pivot in nWp) and
           (nA2Pivot in nWpq) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_nwpq_lw {
            (nA1Pivot in nWpq) and
           (nA2Pivot in W) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_nwpq_nwp {
            (nA1Pivot in nWpq) and
           (nA2Pivot in nWp) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }
pred consist_nwpq_nwpq {
            (nA1Pivot in nWpq) and
           (nA2Pivot in nWpq) and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

