open test_rules_nic_ord_swPutOrRDMAAtomic  as trswr

/* read from all variables */
fact { rl[Reader] = MemoryLocation }

/* eliminate unused threads */
fact {Thr = o[Action]}


fact {Witness2 in nA1Pivot.rf and 
        Witness in nA2Pivot.rf and
        Witness2 in Witness.po
}

fact {RDMAExecution_prime.Robust=True} 
fact {RDMAExecution.Robust=False} 

/* Properties of the test */
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

/* removes Univ objects */
sig Dummy {}
fact { no Dummy }

run {} for 10
