#!/bin/bash

: ${FIO_TARGET_PATH:=/target}
: ${FIO_CONFIG_PATH:=/config}
: ${FIO_SIZE:=4G}
: ${FIO_TEMPLATE:=template.fio}

: ${SYSBENCH_SIZE:=10G}

umask 0002
chmod -R a+rX .

run_sysbench() {
	sysbench_args=(
		--file-total-size=${SYSBENCH_SIZE}
		--file-test-mode=rndrw
		--time=300
		--max-requests=0
	)
	sysbench fileio "${sysbench_args[@]}" prepare
	sysbench fileio "${sysbench_args[@]}" run
	sysbench fileio "${sysbench_args[@]}" cleanup
}

run_fio() {
	sed \
		-e "s|\$TARGET_PATH|$path|g" \
		-e "s|\$SIZE|$FIO_SIZE|g" \
		${FIO_SECTION:+--section $FIO_SECTION} \
		${FIO_CONFIG_PATH}/${FIO_TEMPLATE} > job.fio
	fio --output output.json --output-format json job.fio
}

echo "$(date) starting" > state.txt
for path in $FIO_TARGET_PATH/*; do
	target=${path##*/}
	mkdir -p $target

	echo "$(date) running sysbench on $target" >> state.txt
	(
	cd $target
	run_sysbench > sysbench.out 2> sysbench.err
)

	echo "$(date) running fio on $target" >> state.txt
	(
	cd $target
	run_fio > fio.out 2> fio.err
	)
done

echo "$(date) finished" >> state.txt
