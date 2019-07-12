open test_rules_nic_ord_swPutOrRDMAAtomic  as trswr

/* read from all variables */
//fact { rl[Reader] = MemoryLocation }

/* eliminate unused threads */
//fact {Thr = o[Action]}


fact {nA1Pivot in (RDMAExecution.hbs)[Witness] and 
        Witness in nA2Pivot.rf
}

/* Properties of the test */
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

/* removes Univ objects */
//sig Dummy {}
//fact { no Dummy }

run {} for 12
