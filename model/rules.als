open actions as a
open sw_rules as swr
//fact {all disj r: Reader, w: Writer| (w = corf[r]) iff (r in rf[w]) }

//fact {all disj pq: poll_cq, na: nA| (na = cosw[pq]) iff (pq in sw[na]) }

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Sx_put = 1 and
            #Thr = 2}

run p for 4
