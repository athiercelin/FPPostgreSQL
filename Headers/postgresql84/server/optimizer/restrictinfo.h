/*-------------------------------------------------------------------------
 *
 * restrictinfo.h
 *	  prototypes for restrictinfo.c.
 *
 *
 * Portions Copyright (c) 1996-2009, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * $PostgreSQL: pgsql/src/include/optimizer/restrictinfo.h,v 1.44 2009/05/09 22:51:41 tgl Exp $
 *
 *-------------------------------------------------------------------------
 */
#ifndef RESTRICTINFO_H
#define RESTRICTINFO_H

#include "nodes/relation.h"


/* Convenience macro for the common case of a valid-everywhere qual */
#define make_simple_restrictinfo(clause)  \
	make_restrictinfo(clause, true, false, false, NULL, NULL)

extern RestrictInfo *make_restrictinfo(Expr *clause,
				  bool is_pushed_down,
				  bool outerjoin_delayed,
				  bool pseudoconstant,
				  Relids required_relids,
				  Relids nullable_relids);
extern List *make_restrictinfo_from_bitmapqual(Path *bitmapqual,
								  bool is_pushed_down,
								  bool include_predicates);
extern bool restriction_is_or_clause(RestrictInfo *restrictinfo);
extern List *get_actual_clauses(List *restrictinfo_list);
extern List *extract_actual_clauses(List *restrictinfo_list,
					   bool pseudoconstant);
extern void extract_actual_join_clauses(List *restrictinfo_list,
							List **joinquals,
							List **otherquals);
extern List *select_nonredundant_join_clauses(PlannerInfo *root,
								 List *restrictinfo_list,
								 Path *inner_path);

#endif   /* RESTRICTINFO_H */
