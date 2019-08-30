#ifndef RDMA_TEST_H
#define RDMA_TEST_H

#include "rdma-common.h"

// shared vars:
long long * vars;

// registers:
extern
$5

void test_init(struct connection *conn);
void test_result(struct ibv_cq *cq, struct connection *conn);
void collate_results(struct ibv_cq *cq, struct connection *conn);
void test(struct ibv_cq *cq, struct connection *conn);
void print_results();

void initialize_mr_vars(struct connection *conn);
void register_shared_vars(enum app_type acting_as, struct connection *conn);
void destroy_shared_vars(struct connection *conn);
void send_mr(void * context);

extern struct context *s_ctx;

#endif
