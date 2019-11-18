open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
/*
//-----------
pred missPrevWrite3[e:Execution,a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 3
    a3 in a2.(e.hb) and 
	a2 not in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in nWpq} 
//fact{nA2Pivot in nWpq}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | missPrevWrite3[e_t,nA1Pivot, nA2Pivot, Witness]}
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
//and (e_f.hbs=^(po_tc+rf +sw_s+e_f.mos))
}
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run show for 10
// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

/*
run consist_lw_lw for 4 //works for 4 not for (79ms)
run consist_lw_nwp for 8 //works for 8 not for 6 (1280ms)
run consist_nwp_lw for 10//works for 10 not for 8 (32336ms)
run consist_nwpq_lw for 10  //works for 10 not for 8 (12043ms.)

-------------------------------------------------------------------------------
run consist_nwpq_nwp for 12 //runs for too long for 12 fails for 10 (fail 108289ms)
run consist_nwp_nwpq for 16 //works for ?? not for 14(very long time)
run consist_nwpq_nwpq for 4 expect 0//order-sw prevents it
run consist_nwp_nwp for 4 expect 0//order-sw prevents it

*/
