#include <igraph.h>
#include "common.h"

static void dump (igraph_t *);
static void add_random_vertices (igraph_t *, int);
static void del_random_vertices (igraph_t *, int);
static void add_random_edges (igraph_t *, int);
static void del_random_edges (igraph_t *, int);
static void search_random_edges (igraph_t *, int);
static void write_dot (igraph_t *);
static void write_graphml (igraph_t *);

int
main (int argc, char **argv)
{
  igraph_t g;

  parse_options (argc, argv);

  g_assert (igraph_empty (&g, NUM_V, TRUE) == IGRAPH_SUCCESS);
  add_random_edges (&g, NUM_E);
  add_random_vertices (&g, NUM_V * X);
  add_random_edges (&g, NUM_E * X);

  if (DEBUG)
    {
      g_print ("\nInitial graph:\n");
      dump (&g);
    }

  search_random_edges (&g, NUM_E * X);
  del_random_edges (&g, NUM_E * X);

  if (DEBUG)
    {
      g_print ("\nFinal graph:\n");
      dump (&g);
    }

  if (WRITE)
    {
      g_print ("\n");
      write_dot (&g);
      write_graphml (&g);
    }

  g_assert (igraph_destroy (&g) == IGRAPH_SUCCESS);

  exit (EXIT_SUCCESS);
}

static void G_GNUC_UNUSED
dump (igraph_t *g)
{
  igraph_vector_t v;
  size_t i;

  g_print ("graph %p: %d vertices, %d edges\n",
           g, igraph_vcount (g), igraph_ecount (g));

  g_assert (igraph_vector_init (&v, 0) == IGRAPH_SUCCESS);
  g_assert (igraph_get_edgelist (g, &v, 0) == IGRAPH_SUCCESS);

  for (i = 0; i < igraph_vector_size (&v); i+=2)
    {
      g_print ("  (%li,%li)\n",
               (long) VECTOR (v)[i],
               (long) VECTOR (v)[i + 1]);
    }
  igraph_vector_destroy (&v);
}

static void G_GNUC_UNUSED
add_random_vertices (igraph_t *g, int n)
{
  g_assert (igraph_add_vertices (g, n, 0) == IGRAPH_SUCCESS);
}

static void G_GNUC_UNUSED
del_random_vertices (igraph_t *g, int n)
{
  size_t i;
  for (i = 0; i < n; i++)
    {
      int v = g_random_int_range (0, igraph_vcount (g) - 1);
      g_assert (igraph_delete_vertices (g, igraph_vss_1 (v))
                == IGRAPH_SUCCESS);
    }
}

static void G_GNUC_UNUSED
add_random_edges (igraph_t *g, int n)
{
  igraph_vector_t v;
  int vcount;
  size_t i;

  vcount = igraph_vcount (g);
  g_assert (igraph_vector_init (&v, n * 2) == IGRAPH_SUCCESS);
  for (i = 0; i < n; i++)
    {
      int from = g_random_int_range (0, vcount - 1);
      int to = g_random_int_range (0, vcount - 1);
      VECTOR (v)[i * 2] = from;
      VECTOR (v)[i * 2 + 1] = to;

    }
  g_assert (igraph_add_edges (g, &v, 0) == IGRAPH_SUCCESS);
  igraph_vector_destroy (&v);
}

static void G_GNUC_UNUSED
del_random_edges (igraph_t *g, int n)
{
  igraph_vector_t v;
  int ecount;
  size_t i;

  ecount = igraph_ecount (g);
  g_assert (igraph_vector_init (&v, n) == IGRAPH_SUCCESS);
  for (i = 0; i < n; i++)
    {
      int e = g_random_int_range (0, ecount - 1);
      VECTOR (v)[i] = e;
      if (DEBUG)
        {
          int from, to;
          g_assert (igraph_edge (g, e, &from, &to) == IGRAPH_SUCCESS);
          g_print ("--> delete %d:(%d,%d)\n", e, from, to);
        }
    }
  g_assert (igraph_delete_edges (g, igraph_ess_vector (&v))
            == IGRAPH_SUCCESS);
  igraph_vector_destroy (&v);
}

static void G_GNUC_UNUSED
search_random_edges (igraph_t *g, int n)
{
  size_t i;
  for (i = 0; i < n; i++)
    {
      int vcount = igraph_vcount (g);
      int from = g_random_int_range (0, vcount - 1);
      int to = g_random_int_range (0, vcount - 1);
      int e;
      g_assert (igraph_get_eid (g, &e, from, to, TRUE, FALSE)
                == IGRAPH_SUCCESS);
      if (DEBUG)
        {
          if (e > 0)
            g_print ("--> found %d:(%d,%d)\n", e, from, to);
          else
            g_print ("--> not found (%d,%d)\n", from, to);
        }
    }
}

static void G_GNUC_UNUSED
write_dot (igraph_t *g)
{
  FILE *fp;
  char *name;

  name = g_strdup_printf ("%s.dot", g_get_prgname ());
  g_assert_nonnull (name);

  fp = fopen (name, "w");
  g_assert_nonnull (fp);

  g_assert (igraph_write_graph_dot (g, fp) == IGRAPH_SUCCESS);
  fclose (fp);

  g_print ("Wrote %s\n", name);
  g_free (name);
}

static void G_GNUC_UNUSED
write_graphml (igraph_t *g)
{
  FILE *fp;
  char *name;

  name = g_strdup_printf ("%s.graphml", g_get_prgname ());
  fp = fopen (name, "w");
  g_assert_nonnull (fp);

  g_assert (igraph_write_graph_graphml (g, fp, FALSE) == IGRAPH_SUCCESS);
  fclose (fp);

  g_print ("Wrote %s\n", name);
  g_free (name);
}
