open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------

/* Constructs tests where the mo edge between two Writes is removed*/
/* Violating lW_x --- mo --->Writes2_x */
/* Violating       /\                    |     */
/* Violating        \_____hb____/    */
/* Violating                                   */

/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in Writer} 
//fact{nA2Pivot in Writer}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | nA2Pivot in nA1Pivot.(e_t.mo_next)
											and  nA1Pivot in W
											and  nA2Pivot in nA1Pivot.(e_t.hbs)}

/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}

one sig Witness2 in R {}
fact{Witness2  in Witness.po}
fact{Witness2  in nA1Pivot.rf}
fact{Witness  in nA2Pivot.rf}
------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
       (e_f.hb = e_t.hb)
//and (e_f.hbqp = e_t.hbqp)
and (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
//and (e_f.hbs=^(po_tc+rf +sw_s+e_f.mos))
}

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules


------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
  (e_f.hbs) = (^(po_tc+rf +sw+e_f.mos)) and 
   (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
}




// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run show for 10

/*run consist_lw_lw for 4//78ms.
run consist_lw_nwp for 8//3241ms.
run consist_nwp_lw for 10//10241ms
run consist_nwpq_lw for 10 //6903ms.
run consist_nwpq_nwp for 14 //works for 14 not for 12 (226302ms.)
-------------------------------------------------------------------------------
run consist_nwpq_nwpq for 10//order-sw prevents it
run consist_nwp_nwp for 12//order-sw prevents it
run consist_lw_nwpq for 10 // loops for 10 may try 3 threads
run consist_nwp_nwpq for 14 //runs very long
*/
