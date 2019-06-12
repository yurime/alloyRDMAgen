open execution as a

fact {all e:Execution|
// definition of hb and hbs

 //mo;hbs is irreflexive
{all a,b:Action | a in e.hbs[b] => not b in (e.mo)[a]} 


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
