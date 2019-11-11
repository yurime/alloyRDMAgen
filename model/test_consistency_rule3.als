open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------

/* Constructs tests where the mo edge between two Writes is removed*/
/* Violating W_x --- mo --->W2_x --mo-->W_y */
/* Violating    \                           po?sw_s  |     */
/* Violating     \ _--rf-->  R<---hbs---Action */
/* Violating                                   */

/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in nWpq} 
//fact{nA2Pivot in nWpq}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | nA2Pivot in nA1Pivot.(e_t.mo_next)
                                            and Witness in nA2Pivot.(iden+po_tc).sw.(e_t.hbs)
											and Witness in nA1Pivot.rf}
/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}

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

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
  (e_f.hbs) = (^(po_tc+rf +sw+e_f.mos))
and (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
}




// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules


run consist_lw_lw for 10 //works for 10 not for (1899ms)
run consist_lw_nwp for 10 //works for 10 not for 8 (25561ms)
run consist_nwp_lw for 10 //works for 10 not for 8 (4712ms)
run consist_lw_nwpq for 12//works for 12 not for 10 (48159ms)
run consist_nwpq_nwp for 14 //works for 14 not for 12 (30000ms)
run consist_nwpq_lw for 14 //works for 14 not for 12 (163229ms.)
run consist_nwp_nwpq for 16 //works for ?? not for 14(very long time)
-------------------------------------------------------------------------------
run consist_nwpq_nwpq for 4 expect 0//order-sw prevents it
run consist_nwp_nwp for 4 expect 0//order-sw prevents it
