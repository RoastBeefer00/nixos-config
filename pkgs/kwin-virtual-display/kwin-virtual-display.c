// kwin-virtual-display: ask KWin for a virtual output and keep it alive.
//
// KWin creates a real compositor output (windows can live on it, kscreen
// lists it, Sunshine's kwin capture can stream it) for as long as a
// zkde_screencast stream_virtual_output request is held open. No GPU
// connector or monitor is involved, so it works with the physical display
// powered off. The output is named "Virtual-<name>" and disappears when this
// process exits.
//
// KWin only lets clients bind zkde_screencast_unstable_v1 if their executable
// is listed in a .desktop file with
//   X-KDE-Wayland-Interfaces=zkde_screencast_unstable_v1

#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/signalfd.h>
#include <unistd.h>

#include <wayland-client.h>

#include "zkde-screencast-unstable-v1-client-protocol.h"

#define POINTER_EMBEDDED 2

static struct zkde_screencast_unstable_v1 *screencast;
static uint32_t screencast_version;
static int stream_state; // 0 = pending, 1 = created, -1 = failed/closed

static void registry_global(void *data, struct wl_registry *registry,
                            uint32_t name, const char *interface,
                            uint32_t version) {
  (void)data;
  if (strcmp(interface, zkde_screencast_unstable_v1_interface.name) == 0) {
    screencast_version = version < 4 ? version : 4;
    screencast = wl_registry_bind(registry, name,
                                  &zkde_screencast_unstable_v1_interface,
                                  screencast_version);
  }
}

static void registry_global_remove(void *data, struct wl_registry *registry,
                                   uint32_t name) {
  (void)data;
  (void)registry;
  (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static void stream_closed(void *data,
                          struct zkde_screencast_stream_unstable_v1 *stream) {
  (void)data;
  (void)stream;
  fprintf(stderr, "kwin-virtual-display: compositor closed the stream\n");
  stream_state = -1;
}

static void stream_created(void *data,
                           struct zkde_screencast_stream_unstable_v1 *stream,
                           uint32_t node) {
  (void)data;
  (void)stream;
  printf("kwin-virtual-display: virtual output created (pipewire node %u)\n",
         node);
  fflush(stdout);
  stream_state = 1;
}

static void stream_failed(void *data,
                          struct zkde_screencast_stream_unstable_v1 *stream,
                          const char *error) {
  (void)data;
  (void)stream;
  fprintf(stderr, "kwin-virtual-display: failed: %s\n", error);
  stream_state = -1;
}

static const struct zkde_screencast_stream_unstable_v1_listener
    stream_listener = {
        .closed = stream_closed,
        .created = stream_created,
        .failed = stream_failed,
};

static void usage(const char *argv0) {
  fprintf(stderr,
          "usage: %s [--name NAME] [--size WIDTHxHEIGHT] [--scale SCALE]\n"
          "  defaults: --name stream --size 2560x1440 --scale 1\n"
          "  The output appears in KWin as Virtual-NAME.\n",
          argv0);
}

int main(int argc, char **argv) {
  const char *name = "stream";
  int width = 2560, height = 1440;
  double scale = 1.0;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--name") == 0 && i + 1 < argc) {
      name = argv[++i];
    } else if (strcmp(argv[i], "--size") == 0 && i + 1 < argc) {
      if (sscanf(argv[++i], "%dx%d", &width, &height) != 2 || width <= 0 ||
          height <= 0) {
        usage(argv[0]);
        return 2;
      }
    } else if (strcmp(argv[i], "--scale") == 0 && i + 1 < argc) {
      scale = strtod(argv[++i], NULL);
      if (scale <= 0) {
        usage(argv[0]);
        return 2;
      }
    } else {
      usage(argv[0]);
      return 2;
    }
  }

  struct wl_display *display = wl_display_connect(NULL);
  if (!display) {
    fprintf(stderr, "kwin-virtual-display: cannot connect to Wayland display\n");
    return 1;
  }

  struct wl_registry *registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &registry_listener, NULL);
  wl_display_roundtrip(display);

  if (!screencast) {
    fprintf(stderr,
            "kwin-virtual-display: zkde_screencast_unstable_v1 not available "
            "(not KWin, or this executable isn't allowed via "
            "X-KDE-Wayland-Interfaces)\n");
    return 1;
  }
  if (screencast_version < 2) {
    fprintf(stderr, "kwin-virtual-display: KWin too old for virtual outputs\n");
    return 1;
  }

  struct zkde_screencast_stream_unstable_v1 *stream;
  if (screencast_version >= 4) {
    char description[128];
    snprintf(description, sizeof description, "Virtual display (%s)", name);
    stream = zkde_screencast_unstable_v1_stream_virtual_output_with_description(
        screencast, name, description, width, height,
        wl_fixed_from_double(scale), POINTER_EMBEDDED);
  } else {
    stream = zkde_screencast_unstable_v1_stream_virtual_output(
        screencast, name, width, height, wl_fixed_from_double(scale),
        POINTER_EMBEDDED);
  }
  zkde_screencast_stream_unstable_v1_add_listener(stream, &stream_listener,
                                                  NULL);

  sigset_t mask;
  sigemptyset(&mask);
  sigaddset(&mask, SIGINT);
  sigaddset(&mask, SIGTERM);
  sigprocmask(SIG_BLOCK, &mask, NULL);
  int sfd = signalfd(-1, &mask, SFD_CLOEXEC);

  int ret = 0;
  while (stream_state >= 0) {
    while (wl_display_prepare_read(display) != 0)
      wl_display_dispatch_pending(display);
    wl_display_flush(display);

    struct pollfd fds[2] = {
        {.fd = wl_display_get_fd(display), .events = POLLIN},
        {.fd = sfd, .events = POLLIN},
    };
    if (poll(fds, 2, -1) < 0 && errno != EINTR) {
      wl_display_cancel_read(display);
      ret = 1;
      break;
    }
    if (fds[0].revents & POLLIN) {
      if (wl_display_read_events(display) < 0) {
        ret = 1;
        break;
      }
    } else {
      wl_display_cancel_read(display);
    }
    if (wl_display_dispatch_pending(display) < 0) {
      ret = 1;
      break;
    }
    if (fds[1].revents & POLLIN)
      break;
  }
  if (stream_state < 0)
    ret = 1;

  zkde_screencast_stream_unstable_v1_close(stream);
  zkde_screencast_unstable_v1_destroy(screencast);
  wl_display_flush(display);
  wl_display_disconnect(display);
  return ret;
}
