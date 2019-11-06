open driver as d
//-------------
/**nic-ord-sw**/
//-----------

/* Constructs tests where the sw edge between two nWpq on the same queue pair is removed*/
/* Checks if RDMA actualy generates that edge*/ 
/* In this test the nA1Pivot --mo-->nA2Pivot si created in the other dirrection*/ 

/* Pivots for rule putOrRDMAatomic */
//fact{nA1Pivot in nWpq} 
//fact{nA2Pivot in nWpq}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | nA1Pivot in nA2Pivot.(e_t.mo)
											and  nA2Pivot in nA1Pivot.(e_t.hbs)}


------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
  (e_f.hbs) = (e_t.hbs - (nA1Pivot->nA2Pivot))
and (e_f.mo=e_t.mo)
}


pred oneThread { #Thr = 1 }
pred twoThreads { #Thr = 2 }

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

/* Properties of the test */
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run {show} for 10
