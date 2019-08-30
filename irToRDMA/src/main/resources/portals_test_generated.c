/* compile with: mpicc -lportals portals_test_generated.c */
/* to use MPI and not libtest: mpicc -DUSE_MPI -lportals portals_test_generated.c */

#include <portals4.h>

#include <assert.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <sched.h>
#include <string.h>
#include <stdbool.h>

#define NUM_ITERATIONS 1000

/* IR code:
$1
*/


/* -------------------- from .h files [portals4] -------------------- */
/* test/basic/testing.h: */

#ifdef USE_MPI
 #include <mpi.h>
 #define BARRIER MPI_Barrier(MPI_COMM_WORLD)
#else
 #include <pmi.h>
 #define BARRIER libtest_barrier()
 ptl_process_t* libtest_get_mapping(ptl_handle_ni_t ni_h);
 void libtest_barrier(void);
#endif

#define CHECK_RETURNVAL(x) do { int ret; \
  switch (ret = x) { \
    case PTL_IGNORED:  \
    case PTL_OK: break;							\
    case PTL_FAIL: printf("=> %s returned PTL_FAIL (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    case PTL_NO_SPACE: printf("=> %s returned PTL_NO_SPACE (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    case PTL_ARG_INVALID: printf("=> %s returned PTL_ARG_INVALID (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    case PTL_NO_INIT: printf("=> %s returned PTL_NO_INIT (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    case PTL_PT_IN_USE: printf("=> %s returned PTL_PT_IN_USE (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    case PTL_IN_USE: printf("=> %s returned PTL_IN_USE (line %u)\n", #x, (unsigned int)__LINE__); abort(); break; \
    default: printf("=> %s returned failcode %i (line %u)\n", #x, ret, (unsigned int)__LINE__); abort(); break; \
  } } while (0)

/* -------------------- end of included includes -------------------- */


int main(int   argc,
         char *argv[])
{
    ptl_handle_ni_t ni_h;
    ptl_pt_index_t  pt_index;

    // declare shared vars
    uint64_t        vars[{2}];
    ptl_md_t        vars_md;
    ptl_handle_md_t vars_md_handle;
    ptl_le_t        vars_le;
    ptl_handle_le_t vars_le_handle;

    // initialize shared variables' list entries
    vars_le.start   = &vars;
    vars_le.length  = {2} * sizeof(uint64_t);
    vars_le.uid     = PTL_UID_ANY;
    vars_le.options = PTL_LE_OP_PUT | PTL_LE_OP_GET | PTL_LE_EVENT_CT_COMM;

    // initialize shared variables' memory descriptors
    vars_md.start     = &vars;
    vars_md.length    = {2} * sizeof(uint64_t);
    vars_md.options   = PTL_MD_EVENT_CT_SEND | PTL_MD_EVENT_CT_REPLY | PTL_MD_EVENT_CT_ACK;
    vars_md.eq_handle = PTL_EQ_NONE;

    // initialize shared variable pointers
    $2

    // declare local vars
    $3
    
    int             num_procs;
    ptl_ct_event_t  ctc;
    int             rank;
    ptl_process_t  *procs;

    CHECK_RETURNVAL(PtlInit());

#ifdef USE_MPI
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &num_procs);
#else
    CHECK_RETURNVAL(libtest_init());
    rank = libtest_get_rank();
    num_procs = libtest_get_size();
#endif

    /* This test only succeeds if we have enough ranks */
    if (num_procs < {1}) return 77;

    CHECK_RETURNVAL(PtlNIInit(PTL_IFACE_DEFAULT, PTL_NI_NO_MATCHING | PTL_NI_LOGICAL,
			      PTL_PID_ANY, NULL, NULL, &ni_h));

#ifdef USE_MPI
    {
        ptl_process_t myid;
        PtlGetPhysId(ni_h, &myid);
        uint32_t sndbuff[2] = {myid.phys.pid, myid.phys.nid};
        uint32_t * rcvbuff = (uint32_t *) malloc(sizeof(uint32_t)*num_procs*2);
        MPI_Allgather(sndbuff, 2, MPI_UNSIGNED, rcvbuff, 2, MPI_UNSIGNED, MPI_COMM_WORLD);

        ptl_process_t * mymap = (ptl_process_t *) malloc(sizeof(ptl_process_t)*num_procs);
        int j=0, i=0;
        for (i=0; i<num_procs; i++) {
            mymap[i].phys.pid = rcvbuff[j++];
            mymap[i].phys.nid = rcvbuff[j++];
        }

        CHECK_RETURNVAL(PtlSetMap(ni_h, num_procs, mymap));
    }
#else
    procs = libtest_get_mapping(ni_h);
    CHECK_RETURNVAL(PtlSetMap(ni_h, num_procs, procs));
#endif

    CHECK_RETURNVAL(PtlPTAlloc(ni_h, 0, PTL_EQ_NONE, PTL_PT_ANY,
                               &pt_index));
    assert(pt_index == 0);

    // initialize LE and MD CT handles and add the LE/bind the MD
    CHECK_RETURNVAL(PtlCTAlloc(ni_h, &vars_le.ct_handle));
    CHECK_RETURNVAL(PtlLEAppend(ni_h, 0, &vars_le, PTL_PRIORITY_LIST, NULL,
                                 &vars_le_handle));

    CHECK_RETURNVAL(PtlCTAlloc(ni_h, &vars_md.ct_handle));
    CHECK_RETURNVAL(PtlMDBind(ni_h, &vars_md, &vars_md_handle));

    int i;
    for(i = 0; i < NUM_ITERATIONS; i++) {
        ptl_ct_event_t ct = { .success = 0, .failure = 0 };
        ptl_ct_event_t ctt;
        PtlCTSet(vars_md.ct_handle, ct);
        PtlCTSet(vars_le.ct_handle, ct);

        $4

        BARRIER;

        $5

#if 0
	CHECK_RETURNVAL(PtlCTGet(vars_md.ct_handle, &ctt));
	printf("rank %d after test got md %d %d\n", rank, ctt.success, ctt.failure);
	CHECK_RETURNVAL(PtlCTGet(vars_le.ct_handle, &ctt));
	printf("rank %d after test got le %d %d\n", rank, ctt.success, ctt.failure);
#endif

        BARRIER;

        PtlCTSet(vars_md.ct_handle, ct);
        // 1. Put local variables in corresponding *_sender shared variables.
        // 2. For all processes except rank 0, send *_sender variables to 
        // corresponding *_receiver variable on rank 0 
        // 3. Load all *_receiver shared variables in the local variables 
        // 4. Increment the counter corresponding to the observed output 
        $6
    }

    $7

    BARRIER;

#ifdef USE_MPI
    MPI_Finalize();
#endif

    CHECK_RETURNVAL(PtlLEUnlink(vars_le_handle));
    CHECK_RETURNVAL(PtlCTFree(vars_le.ct_handle));

    CHECK_RETURNVAL(PtlMDRelease(vars_md_handle));
    CHECK_RETURNVAL(PtlCTFree(vars_md.ct_handle));

    CHECK_RETURNVAL(PtlPTFree(ni_h, pt_index));
    CHECK_RETURNVAL(PtlNIFini(ni_h));
#ifndef USE_MPI
    CHECK_RETURNVAL(libtest_fini());
#endif
    PtlFini();

    return 0;
}

/* -------------------- end of core code -------------------- */

#ifndef USE_MPI
/* -------------------- test lib follows -------------------- */

/* originally from test/support.h: */
#define LIBTEST_CHECK(rc, fun)                                         \
  if (rc != PTL_OK && rc != PTL_IGNORED)   {                                                  \
    printf("%s() failed (%s)\n", fun, libtest_StrPtlError(rc)); \
    exit(1);                                                       \
  }

/* from pmi.c: */
struct map_t {
    ptl_handle_ni_t handle;
    ptl_process_t *mapping;
};

static int rank = -1;
static int size = 0;
struct map_t maps[4] = { { PTL_INVALID_HANDLE, NULL },
                         { PTL_INVALID_HANDLE, NULL },
                         { PTL_INVALID_HANDLE, NULL },
                         { PTL_INVALID_HANDLE, NULL } };

static int
encode(const void *inval, int invallen, char *outval, int outvallen)
{
    static unsigned char encodings[] = {
        '0','1','2','3','4','5','6','7', \
        '8','9','a','b','c','d','e','f' };
    int i;

    if (invallen * 2 + 1 > outvallen) {
        return 1;
    }

    for (i = 0; i < invallen; i++) {
        outval[2 * i] = encodings[((unsigned char *)inval)[i] & 0xf];
        outval[2 * i + 1] = encodings[((unsigned char *)inval)[i] >> 4];
    }

    outval[invallen * 2] = '\0';

    return 0;
}


static int
decode(const char *inval, void *outval, int outvallen)
{
    int i;
    char *ret = (char*) outval;

    if (outvallen != strlen(inval) / 2) {
        return 1;
    }

    for (i = 0 ; i < outvallen ; ++i) {
        if (*inval >= '0' && *inval <= '9') {
            ret[i] = *inval - '0';
        } else {
            ret[i] = *inval - 'a' + 10;
        }
        inval++;
        if (*inval >= '0' && *inval <= '9') {
            ret[i] |= ((*inval - '0') << 4);
        } else {
            ret[i] |= ((*inval - 'a' + 10) << 4);
        }
        inval++;
    }

    return 0;
}



int
libtest_init(void)
{
    int initialized;

    if (PMI_SUCCESS != PMI_Initialized(&initialized)) {
        return 1;
    }

    if (0 == initialized) {
        if (PMI_SUCCESS != PMI_Init(&initialized)) {
            return 2;
        }
    }

    if (PMI_SUCCESS != PMI_Get_rank(&rank)) {
        return 3;
    }

    if (PMI_SUCCESS != PMI_Get_size(&size)) {
        return 4;
    }

    return 0;
}

int
libtest_fini(void)
{
    int i;

    for (i = 0 ; i < 4 ; ++i) {
        if (NULL != maps[i].mapping) {
            free(maps[i].mapping);
        }
    }

    PMI_Finalize();

    return 0;
}

ptl_process_t*
libtest_get_mapping(ptl_handle_ni_t ni_h)
{
    int i, ret, max_name_len, max_key_len, max_val_len;
    char *name, *key, *val;
    ptl_process_t my_id;
    struct map_t *map = NULL;
    
    for (i = 0 ; i < 4 ; ++i) {
        if (maps[i].handle == ni_h) {
            return maps[i].mapping;
        }
    }

    for (i = 0 ; i < 4 ; ++i) {
        if (PTL_INVALID_HANDLE == maps[i].handle) {
            map = &maps[i];
            break;
        }
    }

    if (NULL == map) return NULL;

    map->handle = ni_h;

    if (PMI_SUCCESS != PMI_KVS_Get_name_length_max(&max_name_len)) {
        return NULL;
    }
    name = (char*) malloc(max_name_len);
    if (NULL == name) return NULL;

    if (PMI_SUCCESS != PMI_KVS_Get_key_length_max(&max_key_len)) {
        return NULL;
    }
    key = (char*) malloc(max_key_len);
    if (NULL == key) return NULL;

    if (PMI_SUCCESS != PMI_KVS_Get_value_length_max(&max_val_len)) {
        return NULL;
    }
    val = (char*) malloc(max_val_len);
    if (NULL == val) return NULL;

    ret = PtlGetPhysId(ni_h, &my_id);
    if (PTL_OK != ret) return NULL;

    if (PMI_SUCCESS != PMI_KVS_Get_my_name(name, max_name_len)) {
        return NULL;
    }

    /* put my information */
    snprintf(key, max_key_len, "libsupport-%lu-%lu-nid", 
             (long unsigned) ni_h, (long unsigned) rank);
    if (0 != encode(&my_id.phys.nid, sizeof(my_id.phys.nid), val, 
                    max_val_len)) {
        return NULL;
    }
    if (PMI_SUCCESS != PMI_KVS_Put(name, key, val)) {
        return NULL;
    }

    snprintf(key, max_key_len, "libsupport-%lu-%lu-pid",
             (long unsigned) ni_h, (long unsigned) rank);
    if (0 != encode(&my_id.phys.pid, sizeof(my_id.phys.pid), val, 
                    max_val_len)) {
        return NULL;
    }
    if (PMI_SUCCESS != PMI_KVS_Put(name, key, val)) {
        return NULL;
    }

    if (PMI_SUCCESS != PMI_KVS_Commit(name)) {
        return NULL;
    }

    if (PMI_SUCCESS != PMI_Barrier()) {
        return NULL;
    }

    /* get everyone's information */
    map->mapping = malloc(sizeof(ptl_process_t) * size);
    if (NULL == map->mapping) return NULL;

    for (i = 0 ; i < size ; ++i) {
        snprintf(key, max_key_len, "libsupport-%lu-%lu-nid",
                 (long unsigned) ni_h, (long unsigned) i);
        if (PMI_SUCCESS != PMI_KVS_Get(name, key, val, max_val_len)) {
            return NULL;
        }
        if (0 != decode(val, &(map->mapping)[i].phys.nid, 
                        sizeof((map->mapping)[i].phys.nid))) {
            return NULL;
        }

        snprintf(key, max_key_len, "libsupport-%lu-%lu-pid",
                 (long unsigned) ni_h, (long unsigned) i);
        if (PMI_SUCCESS != PMI_KVS_Get(name, key, val, max_val_len)) {
            return NULL;
        }
        if (0 != decode(val, &(map->mapping)[i].phys.pid,
                        sizeof((map->mapping)[i].phys.pid))) {
            return NULL;
        }
    }

    return map->mapping;
}


int
libtest_get_rank(void)
{
    return rank;
}


int
libtest_get_size(void)
{
    return size;
}


void
libtest_barrier(void)
{
    PMI_Barrier();
}

/* from support.c: */
/* -*- C -*-
 *
 * Copyright 2010 Sandia Corporation. Under the terms of Contract
 * DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government
 * retains certain rights in this software.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

/* Return Portals error return codes as strings */
char *libtest_StrPtlError(int error_code)
{                                      /*{{{ */
    switch (error_code) {
        case PTL_OK:
            return "PTL_OK";

        case PTL_ARG_INVALID:
            return "PTL_ARG_INVALID";

        case PTL_CT_NONE_REACHED:
            return "PTL_CT_NONE_REACHED";

        case PTL_EQ_DROPPED:
            return "PTL_EQ_DROPPED";

        case PTL_EQ_EMPTY:
            return "PTL_EQ_EMPTY";

        case PTL_FAIL:
            return "PTL_FAIL";

        case PTL_IN_USE:
            return "PTL_IN_USE";

        case PTL_IGNORED:
            return "PTL_IGNORED";

        case PTL_INTERRUPTED:
            return "PTL_INTERRUPTED";

        case PTL_LIST_TOO_LONG:
            return "PTL_LIST_TOO_LONG";

        case PTL_NO_INIT:
            return "PTL_NO_INIT";

        case PTL_NO_SPACE:
            return "PTL_NO_SPACE";

        case PTL_PID_IN_USE:
            return "PTL_PID_IN_USE";

        case PTL_PT_FULL:
            return "PTL_PT_FULL";

        case PTL_PT_EQ_NEEDED:
            return "PTL_PT_EQ_NEEDED";

        case PTL_PT_IN_USE:
            return "PTL_PT_IN_USE";

        default:
            return "Unknown Portals return code";
    }
}                                      /* end of strPTLerror() *//*}}} */

/*
** Create an MD
*/
ptl_handle_md_t libtest_CreateMD(ptl_handle_ni_t ni,
                              void           *start,
                              ptl_size_t      length)
{                                      /*{{{ */
    int             rc;
    ptl_md_t        md;
    ptl_handle_md_t md_handle;

    /* Setup the MD */
    md.start     = start;
    md.length    = length;
    md.options   = PTL_MD_UNORDERED;
    md.eq_handle = PTL_EQ_NONE;
    md.ct_handle = PTL_CT_NONE;

    rc = PtlMDBind(ni, &md, &md_handle);
    LIBTEST_CHECK(rc, "Error in libtest_CreateMD(): PtlMDBind");

    return md_handle;
}                                      /* end of libtest_CreateMD() *//*}}} */

/*
** Create an MD with a event counter attached to it
*/
void libtest_CreateMDCT(ptl_handle_ni_t  ni,
                     void            *start,
                     ptl_size_t       length,
                     ptl_handle_md_t *mh,
                     ptl_handle_ct_t *ch)
{                                      /*{{{ */
    int      rc;
    ptl_md_t md;

    /*
    ** Create a counter
    ** If a user wants to resue a CT handle, it will not be PTL_INVALID_HANDLE
    */
    if (*ch == PTL_INVALID_HANDLE) {
        rc = PtlCTAlloc(ni, ch);
        LIBTEST_CHECK(rc, "Error in libtest_CreateMDCT(): PtlCTAlloc");
    }

    /* Setup the MD */
    md.start     = start;
    md.length    = length;
    md.options   = PTL_MD_EVENT_CT_SEND | PTL_MD_UNORDERED;
    md.eq_handle = PTL_EQ_NONE;
    md.ct_handle = *ch;

    rc = PtlMDBind(ni, &md, mh);
    LIBTEST_CHECK(rc, "Error in libtest_CreateMDCT(): PtlMDBind");
}                                      /* end of libtest_CreateMDCT() *//*}}} */

/*
** Create a (persistent) LE with a counter attached to it
** Right now used for puts only...
*/
void libtest_CreateLECT(ptl_handle_ni_t  ni,
                     ptl_pt_index_t   index,
                     void            *start,
                     ptl_size_t       length,
                     ptl_handle_le_t *lh,
                     ptl_handle_ct_t *ch)
{                                      /*{{{ */
    int      rc;
    ptl_le_t le;

    /* If a user wants to reuse a CT handle, it will not be PTL_INVALID_HANDLE */
    if (*ch == PTL_INVALID_HANDLE) {
        rc = PtlCTAlloc(ni, ch);
        LIBTEST_CHECK(rc, "Error in libtest_CreateLECT(): PtlCTAlloc");
    }

    le.start     = start;
    le.length    = length;
    le.uid       = PTL_UID_ANY;
    le.options   = PTL_LE_OP_PUT | PTL_LE_ACK_DISABLE | PTL_LE_EVENT_CT_COMM | PTL_ME_EVENT_LINK_DISABLE;
    le.ct_handle = *ch;
    rc           = PtlLEAppend(ni, index, &le, PTL_PRIORITY_LIST, NULL, lh);
    LIBTEST_CHECK(rc, "Error in libtest_CreateLECT(): PtlLEAppend");
}                                      /* end of libtest_CreateLECT () *//*}}} */

/*
** Create a Portal table entry. Use PTL_PT_ANY if you don't need
** a specific table entry.
*/
ptl_pt_index_t libtest_PTAlloc(ptl_handle_ni_t ni,
                            ptl_pt_index_t  request,
                            ptl_handle_eq_t eq)
{                                      /*{{{ */
    int            rc;
    ptl_pt_index_t index;

    rc = PtlPTAlloc(ni, 0, eq, request, &index);
    LIBTEST_CHECK(rc, "Error in libtest_PTAlloc(): PtlPTAlloc");
    if ((index != request) && (request != PTL_PT_ANY)) {
        printf("Did not get the Ptl index I requested!\n");
        exit(1);
    }

    return index;
}                                      /* end of libtest_PTAlloc() *//*}}} */

/*
** Simple barrier
** Arrange processes around a ring. Send a message to the right indicating that
** this process has entered the barrier. Wait for a message from the left, indicating
** that the left neighbor has also entered. Then, send another message to the right
** indicating that this process is ready to leave the barrier, and then wait for the
** left neighbor to send the same message.
**
** libtest_Barrier_init() sets up the send-side MD, and the receive side LE and counter.
** libtest_Barrier() performs the above simple barrier on a ring.
*/
#define libtest_BarrierIndex (14)

static int             __my_rank = -1;
static ptl_rank_t      __nproc   = 1;
static ptl_handle_md_t __md_handle_barrier;
static ptl_handle_ct_t __ct_handle_barrier;
static ptl_size_t      __barrier_cnt;

void libtest_BarrierInit(ptl_handle_ni_t ni,
                      int             rank,
                      int             nproc)
{                                      /*{{{ */
    ptl_pt_index_t  index;
    ptl_handle_le_t le_handle;

    __my_rank           = rank;
    __nproc             = nproc;
    __barrier_cnt       = 1;
    __ct_handle_barrier = PTL_INVALID_HANDLE;

    /* Create the send side MD */
    __md_handle_barrier = libtest_CreateMD(ni, NULL, 0);

    /* We want a specific Portals table entry */
    index = libtest_PTAlloc(ni, libtest_BarrierIndex, PTL_EQ_NONE);
    assert(index == libtest_BarrierIndex);

    /* Create a counter and attach an LE to the Portal table */
    libtest_CreateLECT(ni, index, NULL, 0, &le_handle, &__ct_handle_barrier);
}                                      /* end of libtest_Barrier_init() *//*}}} */

/* Use this libtest_Put() if no ACKs, user data, etc. */
#define libtest_Put(handle, size, dest, index)                          \
  PtlPut(handle, 0, size, PTL_NO_ACK_REQ, dest, index, 0, 0, NULL, 0)

void libtest_Barrier(void)
{                                      /*{{{ */
    int            rc;
    ptl_process_t  parent, leftchild, rightchild;
    ptl_size_t     test;
    ptl_ct_event_t cnt_value;

    parent.rank     = ((__my_rank + 1) >> 1) - 1;
    leftchild.rank  = ((__my_rank + 1) << 1) - 1;
    rightchild.rank = leftchild.rank + 1;

    if (leftchild.rank < __nproc) {
        /* Wait for my children to enter the barrier */
        test = __barrier_cnt++;
        if (rightchild.rank < __nproc) {
            test = __barrier_cnt++;
        }
        rc = PtlCTWait(__ct_handle_barrier, test, &cnt_value);
        LIBTEST_CHECK(rc, "1st PtlCTWait in libtest_Barrier");
    }

    if (__my_rank > 0) {
        /* Tell my parent that I have entered the barrier */
        rc = libtest_Put(__md_handle_barrier, 0, parent, libtest_BarrierIndex);
        LIBTEST_CHECK(rc, "1st PtlPut in libtest_Barrier");

        /* Wait for my parent to wake me up */
        test = __barrier_cnt++;
        rc   = PtlCTWait(__ct_handle_barrier, test, &cnt_value);
        LIBTEST_CHECK(rc, "2nd PtlCTWait in libtest_Barrier");
    }

    /* Wake my children */
    if (leftchild.rank < __nproc) {
        rc = libtest_Put(__md_handle_barrier, 0, leftchild, libtest_BarrierIndex);
        LIBTEST_CHECK(rc, "2nd PtlPut in libtest_Barrier");
        if (rightchild.rank < __nproc) {
            rc = libtest_Put(__md_handle_barrier, 0, rightchild, libtest_BarrierIndex);
            LIBTEST_CHECK(rc, "3rd PtlPut in libtest_Barrier");
        }
    }
}                                      /* end of libtest_Barrier() *//*}}} */
#endif

/* vim:set expandtab: */
/* -*-  indent-tabs-mode:nil; c-basic-offset:4; -*- */
