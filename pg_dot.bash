#!/bin/bash

function pg() {
	psql -t -A -q -c "$1"
}

(
	echo 'digraph urano { graph [rankdir = "LR" concentrate = true ratio = auto];'
	echo 'node [shape = record fontsize = "10"];'
	for namespace in 2200; do
		for t in $(pg "select relname from pg_class where relnamespace = $namespace and relkind = 'r'"); do
			echo -n "$t [shape = record label = \"$t|"
			X=( $(pg "select distinct '<' || attname || '>' || attname || ' ' || typname || '|' from pg_class join pg_attribute on attrelid = pg_class.oid join pg_type on atttypid = pg_type.oid where relname = '$t' and attnum > 0") )
			echo -n ${X[*]}
			echo "\"];"
		done
	done
	pg "select distinct c1.relname || ':' || a1.attname || ' -> ' || c2.relname || ':' || a2.attname || ';' from pg_constraint join pg_class c1 on c1.oid = conrelid join pg_class c2 on c2.oid = confrelid join pg_attribute a1 on (a1.attnum = any(conkey) and a1.attrelid = conrelid) join pg_attribute a2 on (a2.attnum = any(confkey) and a2.attrelid = confrelid)"
	echo 'node [shape=circle label=""];'
	pg "select distinct '\"' || inhparent || '\" [shape=circle label=\"\"]; ' || c.relname || ' -> \"' || inhparent || '\" [arrowhead=none];' from pg_inherits join pg_class c on inhparent = c.oid"
	echo 'edge [arrowhead=vee];'
	pg "select distinct '\"' || inhparent || '\" -> ' || c.relname || ';' from pg_inherits join pg_class c on inhrelid = c.oid"
	echo '}'
) | dot -Tpng -o sch.png
