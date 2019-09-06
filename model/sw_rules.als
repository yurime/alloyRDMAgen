open actions as a

/* construction of sw */

fact{all a:Sx |
	a.sw = a.instr_sw
}

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.poll_cq_sw+a.instr_sw
}
//-----------
/**instr-sw**/
//-----------
fact{all put:Put | // sx->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}


fact{all get:Get | // sx->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:Rga | // sx->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:Cas | // sx->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}
fact{all put:PutF |// sx->nf->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nf=actions[put] & nF,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

fact{all get:GetF | // sx->nf->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nf=actions[get] & nF,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:RgaF | // sx->nf->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nf=actions[rga] & nF,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:CasF | // sx->nf->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nf=actions[cas] & nF,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

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
  	       (remoteMachineAction[na1]) and   // sx1----->nWpq
	       (remoteMachineAction[na2]) and   // ↓po         ↓nic_ord_sw
	       (not na1 in nRpq)                // sx2----->na2 
  }//end of let 
}

pred putLocalPart [na1:nA,na2:nA]{
  let sx1=actions[instr[na1]]&Sx,
       sx2=actions[instr[na2]]&Sx,
       na1r=actions[instr[na1]]&nWpq,
       na2r=actions[instr[na2]]&nWpq      { 
           (sameOandD[na1r,na2r]) and//forcing same queuepair and starting thread
           (sx2 in sx1.po_tc)  and                        // sx1----->nRp
	       instr[na1]+instr[na2] in Put+PutF and  // ↓po         ↓nic_ord_sw
	      (na2+na1 in nRp)                                 // sx2----->nRp 
  }//end of let 
}


pred nicFence [na1:nA,na2:nA] {
  let sx1=actions[instr[na1]]&Sx,
       sx2=actions[instr[na2]]&Sx {
           (sameOandD[na1,na2]) and//forcing same queuepair and starting thread
           (sx2 in sx1.po_tc)  and                   // sx1-->nRpq-->nWp
	       (na2 in nF) and (na1 in nWp) and  // ↓po                  ↓nic_ord_sw
	       (instr[sx1] in Get+GetF)                 // sx2-------------->nF
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

//------------
/** poll_cq_sw **/
//------------
fact{poll_cq_sw=~co_poll_cq_sw}


fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx { //sx->na1->na2 ---pol_cq_sw---> pcq
      (na2 in instr_sw[na1] ) and 
      (na1 in instr_sw[sx] ) and
      (pcq in sx.po_tc) and
          (// num act submitted = num actions acknowledged
           #(sx.^~po_tc & Sx) = #(pcq.^~po_tc & poll_cq)
           )
  }//end of some na1,sx
  )
}

fact {all nr:(nA&Reader),nw:(nA&Writer) | nw in nr.instr_sw => wV[nw]=rV[nr]}

/*pred p1 { 
           #PutF = 1 and
            #Sx_cas = 1 and
            #Thr = 2}

run p1 for 8
*/

check{not cyclic[sw]} for 10 expect 0

pred getThenPutF {  // needs at least 12
            #Get > 0 and
            #PutF > 0 and
            #poll_cq = 2  and
			 #(Sx & Sx_get.po_tc) > 0 and
			 #(poll_cq & Sx_get.po_tc) > 0 and
            #Thr = 2}

pred putAfterPut { 
            #Put >1 and
            #poll_cq >1   and
			 #(Sx & Sx_put.po_tc) > 0 and
			 #(poll_cq & Sx_put.po_tc) > 0 and
            #Thr = 2}


pred putAndCas { 
           #Put = 1 and
            #Cas = 1 and
            #Thr = 2}

run getThenPutF for 12
run putAfterPut for 10
run putAndCas for 8


