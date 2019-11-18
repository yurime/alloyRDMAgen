open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------
/*
pred missPrevWrite4[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer|
    a3 in a1.rf and // consistency 4
    a4 in a2.(e.mo) and
	a3 in a4.po.(^instr_sw).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}

/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in nWpq} 
//fact{nA2Pivot in nWpq}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | missPrevWrite4[e_t,nA1Pivot, nA2Pivot, Witness]}
/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}


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
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run show for 10
//run consist_u_lw for 10
/*
run consist_lw_lw for 12  //works for 12 not for 10 (104045ms.)
run consist_lw_nwp for 10 //works for 10 not for 8 (9376ms.)
run consist_nwp_lw for 12 // works for 12  not for 10 (84603ms)
/*-------------------------------------------------------------------------------
run consist_nwpq_nwp for 14 //not for 12 (3330275ms) runs too long for 14 for 
run consist_nwpq_lw for 14 // not for 12 (151159ms.)
run consist_lw_nwpq for 12 //  not for 12 (407903ms)
run consist_nwpq_nwpq for 4 expect 0//order-sw prevents it
run consist_nwp_nwp for 4 expect 0//order-sw prevents it
*/
