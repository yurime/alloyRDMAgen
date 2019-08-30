// VPI_verbs server code
// inspired by https://thegeekinthecorner.wordpress.com/2010/09/28/rdma-read-and-write-with-ib-verbs/
#include "rdma-common.h"

const enum mode proc = TWO_PROCS;

static int on_connect_request(struct rdma_cm_id *id);
static int on_connection(struct rdma_cm_id *id);
static int on_disconnect(struct rdma_cm_id *id);
static int on_event(struct rdma_cm_event *event);
static void usage(const char *argv0);

int main(int argc, char **argv) {
  struct sockaddr_in addr;
  struct rdma_cm_event *event = NULL;
  struct rdma_cm_id *listener = NULL;
  struct rdma_event_channel *ec = NULL;

  if (argc != 1)
    usage(argv[0]);

  set_app(SERVER);

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;

  TEST_Z(ec = rdma_create_event_channel());
  TEST_NZ(rdma_create_id(ec, &listener, NULL, RDMA_PS_TCP));
  TEST_NZ(rdma_bind_addr(listener, (struct sockaddr *)&addr));
  TEST_NZ(rdma_listen(listener, 10)); /* backlog=10 is arbitrary */

  uint16_t port = ntohs(rdma_get_src_port(listener));

  fprintf(stdout, "listening on port %d.\n", port);
  fflush(stdout);

  for (int i = 0; i < NUM_ITERATIONS; i++) {
    while (rdma_get_cm_event(ec, &event) == 0) {
      struct rdma_cm_event event_copy;
      
      memcpy(&event_copy, event, sizeof(*event));
      rdma_ack_cm_event(event);
      
      if (on_event(&event_copy))
	break;
    }
  }

  rdma_destroy_id(listener);
  rdma_destroy_event_channel(ec);

  return 0;
}

int on_connect_request(struct rdma_cm_id *id) {
  struct rdma_conn_param cm_params;

  build_connection(SERVER, id);
  build_params(&cm_params);
  TEST_NZ(rdma_accept(id, &cm_params));

  return 0;
}

int on_connection(struct rdma_cm_id *id) {
  on_connect(id->context);
  return 0;
}

int on_disconnect(struct rdma_cm_id *id) {
  destroy_connection(id->context);
  return 1;
}

int on_event(struct rdma_cm_event *event) {
  int r = 0;

  if (event->event == RDMA_CM_EVENT_CONNECT_REQUEST)
    r = on_connect_request(event->id);
  else if (event->event == RDMA_CM_EVENT_ESTABLISHED)
    r = on_connection(event->id);
  else if (event->event == RDMA_CM_EVENT_DISCONNECTED)
    r = on_disconnect(event->id);
  else
    die("on_event: unknown event.");

  return r;
}

void usage(const char *argv0) {
  fprintf(stderr, "usage: %s\n", argv0);
  exit(1);
}
