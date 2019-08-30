// VPI_verbs client code
// inspired by https://thegeekinthecorner.wordpress.com/2010/09/28/rdma-read-and-write-with-ib-verbs/
#include "rdma-common.h"
#include "rdma-test.h"

const int TIMEOUT_IN_MS = 500; /* ms */
const enum mode proc = TWO_PROCS;

static int on_addr_resolved(struct rdma_cm_id *id);
static int on_connection(struct rdma_cm_id *id);
static int on_disconnect(struct rdma_cm_id *id);
static int on_event(struct rdma_cm_event *event);
static int on_route_resolved(struct rdma_cm_id *id);
static void usage(const char *argv0);

int main(int argc, char **argv) {
  if (argc != 3)
    usage(argv[0]);
	
  set_app(CLIENT);

  for(int i=0; i<NUM_ITERATIONS; i++) {
    if (i % 500 == 0) { printf("iteration %d\n", i); fflush(stdout); }
    struct rdma_cm_event *event = NULL;
    struct rdma_cm_id *conn= NULL;
    struct rdma_event_channel *ec = NULL;
    struct addrinfo hints;
    struct addrinfo *addr;

    // our server only listens on IPv4 so we better try to connect to it there
    memset(&hints, 0, sizeof(hints));
    hints.ai_family=AF_INET;

    TEST_NZ(getaddrinfo(argv[1], argv[2], &hints, &addr));

    TEST_Z(ec = rdma_create_event_channel());

    TEST_NZ(rdma_create_id(ec, &conn, NULL, RDMA_PS_TCP));
    TEST_NZ(rdma_resolve_addr(conn, NULL, addr->ai_addr, TIMEOUT_IN_MS));

    freeaddrinfo(addr);

    while (rdma_get_cm_event(ec, &event) == 0) {
      struct rdma_cm_event event_copy;

      memcpy(&event_copy, event, sizeof(*event));
      rdma_ack_cm_event(event);

      if (on_event(&event_copy))
	break;
    }

    rdma_destroy_event_channel(ec);
  }
  print_results();

  return 0;
}

int on_addr_resolved(struct rdma_cm_id *id) {
  build_connection(CLIENT, id);
  TEST_NZ(rdma_resolve_route(id, TIMEOUT_IN_MS));

  return 0;
}

int on_connection(struct rdma_cm_id *id) {
  on_connect(id->context);
  send_mr(id->context);

  return 0;
}

int on_disconnect(struct rdma_cm_id *id) {
  destroy_connection(id->context);
  return 1; /* exit event loop */
}

int on_event(struct rdma_cm_event *event) {
  int r = 0;

  if (event->event == RDMA_CM_EVENT_ADDR_RESOLVED)
    r = on_addr_resolved(event->id);
  else if (event->event == RDMA_CM_EVENT_ROUTE_RESOLVED)
    r = on_route_resolved(event->id);
  else if (event->event == RDMA_CM_EVENT_ESTABLISHED)
    r = on_connection(event->id);
  else if (event->event == RDMA_CM_EVENT_DISCONNECTED)
    r = on_disconnect(event->id);
  else if (event->event == RDMA_CM_EVENT_REJECTED)
    die("on_event: RDMA_CM_EVENT_REJECTED.");
  else {
    char error_msg[80];
    snprintf(error_msg, sizeof(error_msg), "on_event: unknown event %d", event->event);
    die(error_msg);
  }

  return r;
}

int on_route_resolved(struct rdma_cm_id *id) {
  struct rdma_conn_param cm_params;

  build_params(&cm_params);
  TEST_NZ(rdma_connect(id, &cm_params));

  return 0;
}

void usage(const char *argv0) {
  fprintf(stderr, "usage: %s <server-address> <server-port>\n", argv0);
  exit(1);
}
