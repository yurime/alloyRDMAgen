// code for Cray Aries DMAPP
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "pmi.h"
#include "dmapp.h"

#define NUM_ITERATIONS 10000

/* IR code:
$0
*/

int main(int argc, char **argv) {
    char            *expl = NULL;
    int             pe = -1;
    int             npes = -1;
    int             target_pe = -1;

    $1;
    dmapp_return_t      status;
    dmapp_rma_attrs_t   actual_args = {0}, rma_args = {0};
    dmapp_jobinfo_t     job;
    dmapp_seg_desc_t    *seg = NULL;

    /* Set the RMA parameters. */
    rma_args.put_relaxed_ordering = DMAPP_ROUTING_DETERMINISTIC;
    rma_args.max_outstanding_nb = DMAPP_DEF_OUTSTANDING_NB;
    rma_args.offload_threshold = DMAPP_OFFLOAD_THRESHOLD;
    rma_args.max_concurrency = 1;

    /* Initialize DMAPP resources before executing any other DMAPP calls. */
    status = dmapp_init(&rma_args, &actual_args);
    if(status != DMAPP_RC_SUCCESS) {
        dmapp_explain_error(status, (const char **)&expl);
        fprintf(stderr, " dmapp_init returned %d - %s - %s \n", status, dmapp_err_str[status], expl);
        exit(1);
    }

    /* Retrieve information about job details such as PE id and number of PEs. */
    status = dmapp_get_jobinfo(&job);
    if (status != DMAPP_RC_SUCCESS) {
        dmapp_explain_error(status, (const char **)&expl);
        fprintf(stderr, " dmapp_get_jobinfo FAILED: w/ %d - %s -%s\n", status, dmapp_err_str[status], expl);
        exit(1);
    }
    pe = job.pe;
    npes = job.npes;
    target_pe = npes - pe - 1;



    /* Specify in which segment the remote memory region (the source) lies.
       In this case, it is the heap (see above). */
    seg = &(job.sheap_seg);

    for(int i = 0; i < NUM_ITERATIONS; i++) {

        /* Allocate remotely accessible memory for the source and target buffers.
           Only memory in the data segment or the sheap is remotely accessible.
           Here we allocate from the sheap. */
        $2;

        /* Synchronize to make sure everyone's buffers are initialized before data transfer is started.  */
        PMI_Barrier();

        /* body */
        $3;

        /* Synchronize before verifying the data. */
        dmapp_gsync_wait();
        PMI_Barrier();

        /* Verify the data. */
        $4;

        /* Free buffers allocated from sheap. */
        $5;
    }

    /* Print output stats */
    $6;

    /* Release DMAPP resources. This is a mandatory call. */
    status = dmapp_finalize();
    if (status != DMAPP_RC_SUCCESS) {
        dmapp_explain_error(status, (const char **)&expl);
        fprintf(stderr, " dmapp_finalize FAILED w/ %d - %s -%s\n", status, dmapp_err_str[status], expl);
        exit(1);
    }

    return(0);
}

