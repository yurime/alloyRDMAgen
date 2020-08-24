open base_sw_rules as bsr

//-------------
/**nic-ord-sw**/
//-----------
fact{all a:nA | not a in nic_ord_sw[a]}

// predicates to define when nic_ord_sw is legal
pred putOrRDMAatomic [na1:nA,na2:nA] {
  let sx1=actions[instr[na1]]&Sx,
       sx2=actions[instr[na2]]&Sx {
           (sameOandD[na1,na2]) and//forcing same queuepair and starting thread
           (sx2 in sx1.po_tc)  and 
  	       (remoteMachine[na1]) and   // sx1----->nWpq
	       (remoteMachine[na2]) and   // ↓po         ↓nic_ord_sw
	       (not na1 in nRpq)          // sx2----->na2 
  }//end of let 
}

pred putLocalPart [na1:nA,na2:nA]{
  let sx1=actions[instr[na1]]&Sx,
       sx2=actions[instr[na2]]&Sx,
       na1r=actions[instr[na1]]&nWpq,
       na2r=actions[instr[na2]]&nWpq      { 
           (sameOandD[na1r,na2r]) and//forcing same queuepair and starting thread
           (sx2 in sx1.po_tc)  and                // sx1----->nRp
	       instr[na1]+instr[na2] in Put and  // ↓po         ↓nic_ord_sw
	      (na2+na1 in nRp)                         // sx2----->nRp 
  }//end of let 
}


pred nicFence [na1:nA,na2:nA] {
  let sx1=actions[instr[na1]]&Sx,
       sx2=actions[instr[na2]]&Sx {
           (sameOandD[na1,na2]) and//forcing same queuepair and starting thread
           (sx2 in sx1.po_tc)  and                   // sx1-->nRpq-->nWp
	       (na2 in nF) and (na1 in nWp) and  // ↓po                  ↓nic_ord_sw
	       (instr[sx1] in Get)                           // sx2-------------->nF
   }                                                              
}

// (na1,na2) in nic_ord_sw definition (3 cases)
fact{all disj na1,na2:nA |
  (na2 in nic_ord_sw[na1]) 
  iff
  (  putOrRDMAatomic[na1,na2] 
	  or 
      putLocalPart[na1,na2]
	  or 
	  nicFence[na1,na2]
  )//end iff
}
