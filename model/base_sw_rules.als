open execution as e

//TODO: change the pvito names below to A1Pivot, A2Pivot
one sig nA1Pivot in Writer{}
one sig nA2Pivot in Writer{}

/* Witness */
one sig Witness in Reader {}

sig nA_prime in nA {
	nic_ord_sw_prime: set nA
}
fact{nA in nA_prime}

sig RDMAaction_prime in RDMAaction {
	sw_prime: set Action
}


/* Witness2 */
//one sig Witness2 in Reader {}

one sig RDMAExecution_prime extends Execution{}
