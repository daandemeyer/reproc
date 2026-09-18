#include <errno.h>
#include <string.h>
#include <unistd.h>

#include <reproc/drain.h>
#include <reproc/reproc.h>

#include "assert.h"

#define MESSAGE "reproc stands for REdirected PROCess"
#define PREFIX "setup:"

static int write_prefix(void *context)
{
  const char *prefix = context;
  size_t size = strlen(prefix);
  ssize_t n = write(STDOUT_FILENO, prefix, size);
  return n == (ssize_t) size ? 0 : -errno;
}

static int fail_eperm(void *context)
{
  (void) context;
  return -EPERM;
}

static void success(void)
{
  int r = -1;

  reproc_t *process = reproc_new();
  ASSERT(process);

  const char *argv[] = { RESOURCE_DIRECTORY "/io", NULL };

  r = reproc_start(process, argv,
                   (reproc_options){
                       .redirect.err.type = REPROC_REDIRECT_DISCARD,
                       .setup = { .function = write_prefix,
                                  .context = (void *) PREFIX } });
  ASSERT_OK(r);

  // The extra exit handle must still be open in the child after `setup` and
  // `exec`. `reproc_wait(0)` would block forever if `setup` had closed it.
  r = reproc_wait(process, 0);
  ASSERT_EQ_INT(r, REPROC_ETIMEDOUT);

  r = reproc_write(process, (uint8_t *) MESSAGE, strlen(MESSAGE));
  ASSERT_OK(r);
  ASSERT_EQ_INT(r, (int) strlen(MESSAGE));

  r = reproc_close(process, REPROC_STREAM_IN);
  ASSERT_OK(r);

  char *out = NULL;
  r = reproc_drain(process, reproc_sink_string(&out), REPROC_SINK_NULL);
  ASSERT_OK(r);

  ASSERT(out != NULL);
  ASSERT_EQ_STR(out, PREFIX MESSAGE);

  r = reproc_wait(process, REPROC_INFINITE);
  ASSERT_OK(r);

  reproc_destroy(process);
  reproc_free(out);
}

static void failure(void)
{
  reproc_t *process = reproc_new();
  ASSERT(process);

  const char *argv[] = { RESOURCE_DIRECTORY "/io", NULL };

  int r = reproc_start(process, argv,
                       (reproc_options){ .setup = { .function = fail_eperm } });
  ASSERT_EQ_INT(r, -EPERM);

  reproc_destroy(process);
}

static void fork_incompatible(void)
{
  reproc_t *process = reproc_new();
  ASSERT(process);

  int r = reproc_start(process, NULL,
                       (reproc_options){ .fork = true,
                                         .setup = { .function = write_prefix,
                                                    .context =
                                                        (void *) PREFIX } });
  ASSERT_EQ_INT(r, REPROC_EINVAL);

  reproc_destroy(process);
}

int main(void)
{
  success();
  failure();
  fork_incompatible();
}
