open driver as d
//-------------
/**nic-ord-sw**/
//-----------

/* Constructs tests where the sw edge between two nWpq on the same queue pair is removed*/
/* Checks if RDMA actualy generates that edge*/ 
/* In this test the nA1Pivot --mo-->nA2Pivot si created in the other dirrection*/ 

/* Pivots rules from driver.base_sw_rules*/
//fact{nA1Pivot in Write} 
//fact{nA2Pivot in Write}

/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}


/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | nA2Pivot in nA1Pivot.(e_t.mo)
                                            and Witness in nA2Pivot.(e_t.hbs)
											and Witness in nA1Pivot.rf}


------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
  (e_f.hb = e_t.hb)
and (e_f.hbqp = e_t.hbqp)
and (e_f.mo=e_t.mo -(nA1Pivot->nA2Pivot))
and (e_f.hbs=e_t.hbs)
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
