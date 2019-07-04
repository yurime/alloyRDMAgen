open actions as a

/* construction of sw */

//instr-sw
//defined per instruction in action file

fact{all a:Sx |
	a.sw = a.instr_sw
}
fact{all disj a1,a2:Sx | not instr_sw[a1]=instr_sw[a2] }

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.poll_cq_sw+a.instr_sw
}
//check{all disj a1,a2:nA | not instr_sw[a1]=instr_sw[a2] } --- implied from the rules below

fact{all put:Put |
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

fact{all get:Get |
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:Rga | 
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:Cas | 
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}
fact{all put:PutF |
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nfpq=actions[put] & nFpq,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

fact{all get:GetF |
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nfpq=actions[get] & nFpq,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:RgaF | 
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nfpq=actions[rga] & nFpq,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:CasF | 
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nfpq=actions[cas] & nFpq,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nfpq and
          instr_sw[nfpq] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}
//------------
//nic-ord-sw :
//-------------
fact{all a,b:nA | (a in b.nic_ord_sw) implies (not b in a.^nic_ord_sw)}

fact{all disj na1,na2:nA | 
(na2 in nic_ord_sw[na1])
iff 
  (some sx1,sx2:Sx {
	(instr[sx1]=instr[na1])and 
	(instr[sx2]=instr[na2])and 
	(d[na1]=d[na2]) and //forcing the same queue pair
	(o[na1]=o[na2])and 
   (sx2 in sx1.^po)  and 
	(//breaking into cases
	  (//RDMA Write or RDMA atomic (with successor, on remote machine) 
	      (not o[na1]=d[na1]) and //forcing nA^{p-->q}
	      (not o[na2]=d[na2]) and 
	    (not na1 in nRpq+nFpq)
	  )//end RDMA Write or RDMA atomic (with successor, on remote machine) 
	  or 
	  (//RDMA Write (local read part)
	  some  nwpq1,nwpq2:nWpq {
	    (na2 in nRp) and (na1 in nRp) and
	    (instr[sx1]=instr[nwpq1])and 
	    (instr[sx2]=instr[nwpq2])
	  }
	  )//end RDMA Write (local read part)
	  or 
	  (//RDMA Fence
	  some nrpq:nRpq {
	    (na2 in nFpq) and (na1 in nWp) and
	    (instr[sx1]=instr[nrpq])
	  }
	  )//end RDMA Fence
	)//end  breaking into cases
  }//end some sx1,sx2
)//end iff
}

//------------
//poll-cq-sw
//------------
fact{all pcq:poll_cq | pcq=poll_cq_sw[co_poll_cq_sw[pcq]]}
/*//first version --- recursive
fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx {
      (na2 in instr_sw[na1] ) and
      (na1 in instr_sw[sx] ) and
      (pcq in sx.^po) and
          (all sx2:Sx,na3,na4:nA {
             ( (na4 in instr_sw[na3] ) and
                (na3 in instr_sw[sx2] ) and
                (sx in sx2.^po)
              )
              =>
             (  some pcq2:poll_cq {
                    pcq2 in poll_cq_sw[na4] and
                    pcq in pcq2.^po and
                    pcq2 in sx2.^po
                 }          
             )
            }            
          )
  }//end of some na1,sx
  )
}
*/

fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx {
      (na2 in instr_sw[na1] ) and
      (na1 in instr_sw[sx] ) and
      (pcq in sx.^po) and
          (
           #(sx.^copo & Sx) = #(pcq.^copo & poll_cq)
           )
  }//end of some na1,sx
  )
}


pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Put = 2 and
            #poll_cq = 2  and
			 #(Sx & Sx.po) > 0 and
			 #(poll_cq & Sx_put.po) > 0 and
            #Thr = 2}

run p for 10
