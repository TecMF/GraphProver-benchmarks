#include <stdlib.h>
#include <glib.h>
#include <glib/gstdio.h>

static int NUM_V;               /* number of vertices */
static int NUM_E;               /* number of edges */
static double X;                /* test size (percentage) */
static gboolean DEBUG = FALSE;
static gboolean WRITE = FALSE;

static void G_GNUC_UNUSED
parse_options (int argc, char **argv)
{
  GOptionContext *ctx;
  gboolean status;
  GError *error = NULL;
  static GOptionEntry options[] =
    {
     {"debug", 'd', 0, G_OPTION_ARG_NONE, &DEBUG,
      "Enable debugging messages", NULL},
     {"write", 'w', 0, G_OPTION_ARG_NONE, &WRITE,
      "Write final graph to file", NULL},
     {NULL, 0, 0, G_OPTION_ARG_NONE, NULL, NULL, NULL},
    };

  g_set_prgname (g_path_get_basename (argv[0]));
  ctx = g_option_context_new ("NUM_V NUM_E X");
  g_assert_nonnull (ctx);
  g_option_context_add_main_entries (ctx, options, NULL);
  status = g_option_context_parse (ctx, &argc, &argv, &error);
  g_option_context_free (ctx);

  if (!status)
    {
      g_assert_nonnull (error);
      g_fprintf (stderr, "error: %s", error->message);
      g_error_free (error);
      exit (EXIT_FAILURE);
    }

  if (argc < 4)
    {
      g_fprintf (stderr, "error: missing %s operand\n",
                 (argc < 2) ? "NUM_V" : (argc < 3) ? "NUM_E" : "X");
      g_fprintf (stderr, "Try '%s --help' for more information.\n",
                 g_get_prgname ());
      exit (EXIT_FAILURE);
    }

  NUM_V = g_ascii_strtoll (argv[1], NULL, 10);
  g_assert (NUM_V > 0);

  NUM_E = g_ascii_strtoll (argv[2], NULL, 10);
  g_assert (NUM_E > 0);

  X = g_strtod (argv[3], NULL);
  g_assert (X >= 0. && X <= 1.);

  g_random_set_seed ((guint32) g_get_monotonic_time ());
}
