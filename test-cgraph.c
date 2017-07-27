/**
 * CONS:
 * - It is not possible to get edge by name.
 */
#include <graphviz/cgraph.h>
#include "common.h"

static Agedge_t **EDGES;
static int EDGES_LAST;

static void dump (Agraph_t *);
static void add_random_vertices (Agraph_t *, int);
static void del_random_vertices (Agraph_t *, int);
static void add_random_edges (Agraph_t *, int);
static void del_random_edges (Agraph_t *, int);
static void search_random_edges (Agraph_t *, int);

int
main (int argc, char **argv)
{
  Agraph_t *g;

  parse_options (argc, argv);

  g = agopen ("G", Agdirected, NULL);
  g_assert_nonnull (g);

  EDGES = malloc (sizeof (Agedge_t *) * (NUM_E + NUM_E * X));
  g_assert_nonnull (EDGES);
  memset (EDGES, 0, NUM_E + NUM_E * X);
  EDGES_LAST = -1;

  add_random_vertices (g, NUM_V);
  add_random_edges (g, NUM_E);
  add_random_vertices (g, NUM_V * X);
  add_random_edges (g, NUM_E * X);

  if (DEBUG)
    {
      g_print ("\nInitial graph:\n");
      dump (g);
    }

  search_random_edges (g, NUM_E * X);
  del_random_edges (g, NUM_E * X);

  if (DEBUG)
    {
      g_print ("\nFinal graph:\n");
      dump (g);
    }

  if (WRITE)
    {
      g_print ("\n");
      /* write_dot (&g); */
      /* write_graphml (&g); */
    }

  free (EDGES);
  agclose (g);

  return 0;
}

static void G_GNUC_UNUSED
dump (Agraph_t *g)
{
  Agnode_t *v;
  Agedge_t *e;

  g_print ("graph %p: %d vertices, %d edges\n",
           g, agnnodes (g), agnedges (g));

  for (v = agfstnode (g); v != NULL; v = agnxtnode (g, v))
    for (e = agfstout (g, v); e != NULL; e = agnxtout (g, e))
      g_print ("  (%s,%s)\n", agnameof (aghead (e)), agnameof (agtail (e)));
}

static void G_GNUC_UNUSED
add_random_vertices (Agraph_t *g, int n)
{
  size_t i;
  for (i = 0; i < n; i++)
    {
      char *name;
      Agnode_t *v;

      name = g_strdup_printf ("%lu", i);
      v = agnode (g, name, TRUE);
      g_assert_nonnull (v);
      g_free (name);
      if (DEBUG)
        g_print ("--> adding vertex %s\n", agnameof (v));
    }
}

static void G_GNUC_UNUSED
del_random_vertices (Agraph_t *g, int n)
{
  size_t i;
  int vcount;

  for (i = 0; i < n; i++)
    {
      char *name;
      Agnode_t *v;

      vcount = agnnodes (g);
      do
        {
          name = g_strdup_printf ("%d", g_random_int_range (0, vcount - 1));
          v = agnode (g, name, FALSE);
          g_free (name);
        }
      while (v == NULL);
      if (DEBUG)
        g_print ("--> delete vertex %s\n", agnameof (v));
      g_assert (agdelnode (g, v) == 0);
    }
}

static void G_GNUC_UNUSED
add_random_edges (Agraph_t *g, int n)
{
  size_t i;
  int vcount;

  vcount = agnnodes (g);
  for (i = 0; i < n; i++)
    {
      char *name;
      Agnode_t *u, *v;
      Agedge_t *e;

      do
        {
          name = g_strdup_printf ("%d", g_random_int_range (0, vcount - 1));
          u = agnode (g, name, FALSE);
          g_free (name);
        }
      while (u == NULL);
      do
        {
          name = g_strdup_printf ("%d", g_random_int_range (0, vcount - 1));
          v = agnode (g, name, FALSE);
          g_free (name);
        }
      while (v == NULL);

      name = g_strdup_printf ("%lu", i);
      e = agedge (g, u, v, name, TRUE);
      g_assert_nonnull (e);
      g_free (name);
      EDGES[++EDGES_LAST] = e;
      if (DEBUG)
        g_print ("--> adding edge %s:(%s,%s)\n", agnameof (e),
                 agnameof (aghead (e)), agnameof (agtail (e)));
    }
}

static void G_GNUC_UNUSED
del_random_edges (Agraph_t *g, int n)
{
  size_t i;
  for (i = 0; i < n; i++)
    {
      Agedge_t *e;
      int idx;
      do
        {
          idx = g_random_int_range (0, EDGES_LAST);
          e = EDGES[idx];
        }
      while (e == NULL);

      if (DEBUG)
        g_print ("--> delete %s:(%s,%s)\n", agnameof (e),
                 agnameof (aghead (e)), agnameof (agtail (e)));

      g_assert (agdeledge (g, e) == 0);
      EDGES[idx] = NULL;
    }
}

static void G_GNUC_UNUSED
search_random_edges (Agraph_t *g, int n)
{
  int vcount;
  size_t i;

  vcount = agnnodes (g);
  for (i = 0; i < n; i++)
    {
      char *name;
      Agnode_t *u, *v;
      Agedge_t *e;

      do
        {
          name = g_strdup_printf ("%d", g_random_int_range (0, vcount - 1));
          u = agnode (g, name, FALSE);
          g_free (name);
        }
      while (u == NULL);
      do
        {
          name = g_strdup_printf ("%d", g_random_int_range (0, vcount - 1));
          v = agnode (g, name, FALSE);
          g_free (name);
        }
      while (v == NULL);

      e = agedge (g, u, v, NULL, FALSE);
      if (DEBUG)
        {
          if (e != NULL)
            g_print ("--> found %s:(%s,%s)\n", agnameof (e),
                     agnameof (aghead (e)), agnameof (agtail (e)));
          else
            g_print ("--> not found (%s,%s)\n", agnameof (u), agnameof (v));
        }
    }
}
