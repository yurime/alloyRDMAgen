open actions as a

fact {all disj r: Reader, w: Writer| (w = rf[r]) iff (r in corf[w]) }

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2}

run p for 10
