#!/usr/bin/env bash

file_as_string=$(cat params.json)
n=$(echo "$file_as_string" | cut -d "\"" -f 4)
t=$(echo "$file_as_string" | cut -d "\"" -f 8)

rm -f bin/bs23/*.store
killall sm_manager bs23_keygen_client bs23_presign_client bs23_sign_client bs23_compile_sig 2>/dev/null

if [[ ! -d ./bin/bs23 ]]; then
	if [[ ! -d ./bin ]]; then
		mkdir "./bin"
	fi
	mkdir "./bin/bs23"
fi
if [[ ! -d ./bin/message ]]; then
	echo "Testing non-interactive threshold ECDSA signing" >./bin/message
fi

echo -e "\nSM Manager:"
./target/release/examples/sm_manager &
sleep 2

echo -e "\n##################\n# Key generation #\n##################\n"
key_gen_start_time=$(date +%Y%m%d-%H:%M:%S)
key_gen_start_time_s=$(date +%s)

for i in $(seq 1 $n); do
	echo "Key-gen for client $i out of $n"
	./target/release/examples/bs23_keygen_client http://127.0.0.1:8001 bin/bs23/keys$i.store bin/public_key &
	sleep 3
done

key_gen_end_time=$(date +%Y%m%d-%H:%M:%S)
key_gen_end_time_s=$(date +%s)
key_gen_time=$(($key_gen_end_time_s - $key_gen_start_time_s))
sleep 7

echo -e "\n###############\n# Pre-signing #\n###############\n"
pre_sign_start_time=$(date +%Y%m%d-%H:%M:%S)
pre_sign_start_time_s=$(date +%s)

for i in $(seq 1 $n); do
	echo "Pre-signing for client $i out of $n"
	./target/release/examples/bs23_presign_client http://127.0.0.1:8001 bin/bs23/keys$i.store bin/bs23/presign$i.store &
	sleep 3
done

pre_sign_end_time=$(date +%Y%m%d-%H:%M:%S)
pre_sign_end_time_s=$(date +%s)
pre_sign_time=$(($pre_sign_end_time_s - $pre_sign_start_time_s))
sleep 7

echo -e "\n###########\n# Signing #\n###########\n"
sign_start_time=$(date +%Y%m%d-%H:%M:%S)
sign_start_time_s=$(date +%s)

for i in $(seq 1 $((t + 1))); do
	echo "Signing locally for client $i out of $((t + 1))"
	./target/release/examples/bs23_sign_client bin/bs23/presign$i.store bin/bs23/localsig$i.store bin/message &
	sleep 3
done

sign_end_time=$(date +%Y%m%d-%H:%M:%S)
sign_end_time_s=$(date +%s)
sign_time=$(($sign_end_time_s - $sign_start_time_s))

echo -e "\n#######################\n# Compiling Signature #\n#######################\n"
complile_sig_start_time=$(date +%Y%m%d-%H:%M:%S)
complile_sig_start_time_s=$(date +%s)

for i in $(seq 1 $((t + 1))); do
	echo "Compiling signature $i out of $((t + 1))"
	./target/release/examples/bs23_compile_sig http://127.0.0.1:8001 bin/bs23/localsig$i.store bin/signature &
	sleep 3
done

complile_sig_end_time=$(date +%Y%m%d-%H:%M:%S)
complile_sig_end_time_s=$(date +%s)
complile_sig_time=$(($complile_sig_end_time_s - $complile_sig_start_time_s))
sleep 7

killall sm_manager 2>/dev/null
