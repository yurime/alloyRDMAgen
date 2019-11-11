open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------

/* Constructs tests where the mo edge between two Writes is removed*/
/* Violating W_x --- mo --->W2_x */
/* Violating       \             hbs  |     */
/* Violating        \                   \/     */
/* Violating          rf----------->R_x  */

/* Pivots rules from driver.base_sw_rules*/

/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}


/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | nA2Pivot in nA1Pivot.(e_t.mo_next)
                                            and Witness in nA2Pivot.(e_t.hbs)
											and Witness in nA1Pivot.rf}


------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
       (e_f.hb = e_t.hb)
//and (e_f.hbqp = e_t.hbqp)
and (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
and (e_f.hbs=^(po_tc+rf +sw_s+e_f.mos))
}

pred oneThread { #Thr = 1 }
pred twoThreads { #Thr = 2 }
pred threeThreads { #Thr = 2 }

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

//consist rules from driver.als

run consist_lw_lw for 6
run consist_lw_nwp for 8
run consist_lw_nwpq for 8
run consist_nwp_lw for 10
run consist_nwpq_lw for 10
run consist_nwpq_nwp for 14 //works for 14 not for 12
run consist_nwp_nwpq for 14 //works for 14 not for 12
-------------------------------------------------------------------------------
run consist_nwpq_nwpq for 12//order-sw prevents it
run consist_nwp_nwp for 12//order-sw prevents it
