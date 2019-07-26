open test_rules_nic_ord_swPutOrRDMAAtomic  as t

/** Genereal test requirement or optimizations**/

// eliminate unused nodes 
fact {Node = host[Thr]}

// read from all variables 
fact { rl[Reader] = MemoryLocation }

// eliminate unused threads 
fact {Thr = o[Action]}

// try to avoid Initialization threads
fact{all i:Init |host[o[i]] in host[o[Action-Init]] => #i.po_tc>0}

// try to minimize the number of values
fact{Writer.wV in {1+2}}

// each write has an effect (costly in instance finding)
//fact{all w1,w2:Writer | w1 = w2.(RDMAExecution.mo_next)  => not (wV[w1]=wV[w2])}

//let us be positive
fact{all w:Writer | wV[w]>0}


/** Specific test requirement or optimizations**/

// Prevent writing of the same value to have an observalble effect
fact{not wV[nA1Pivot]=wV[nA2Pivot]}

//The Witness definition
fact {Witness in nA1Pivot.rf and 
        Witness in nA2Pivot.(RDMAExecution_prime.hbs)
}

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
fact{all i:Instruction, nrp:i.actions&nRp, sx:i.actions&Sx | not( corf[nrp] in sx.po_tc )}

// preventing the reader to read from after the sx (legitimate but bad programming practice)
// is value undefined?
fact{all i:Instruction, nrp:i.actions&nRp, sx:i.actions&Sx | not( corf[nrp] in sx.po_tc )}


// preventing the RDMA action local memory accessed  by following instructions
fact{all i:Instruction,  
		nrp:nRp, sx:Sx, w:Writer| 
          (nrp in i.actions and sx in i.actions and w in sx.po_tc)
           => not( rl[nrp] = wl[w] )}


/* removes Univ objects */
sig Dummy {}
fact { no Dummy }

fact{RDMAExecution_prime.Robust=True}

// sanity
//check {RDMAExecution.Robust=False} expect 0

/* Properties of the test */
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run {show} for 11
