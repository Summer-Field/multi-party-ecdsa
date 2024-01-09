#!/usr/bin/env bash
cargo +nightly build --examples --release

file_as_string=$(cat params.json)

n=$(echo "$file_as_string" | cut -d "\"" -f 4)
t=$(echo "$file_as_string" | cut -d "\"" -f 8)

echo "Multi-party ECDSA parties:$n threshold:$t"
#clean
sleep 1

if [[ ! -d ./bin/gg18 ]]; then
	if [[ ! -d ./bin ]]; then
		mkdir "./bin"
	fi
	mkdir "./bin/gg18"
fi

rm bin/gg18/keys?.store
killall sm_manager gg18_keygen_client gg18_sign_client 2>/dev/null

./target/release/examples/sm_manager &

sleep 2

echo "keygen part"
key_gen_start_time=$(date +%Y%m%d-%H:%M:%S)
key_gen_start_time_s=$(date +%s)

for i in $(seq 1 $n); do
	echo "key gen for client $i out of $n"
	./target/release/examples/gg18_keygen_client http://127.0.0.1:8001 bin/gg18/keys$i.store &
	sleep 3
done

key_gen_end_time=$(date +%Y%m%d-%H:%M:%S)
key_gen_end_time_s=$(date +%s)
key_gen_time=$(($key_gen_end_time_s - $key_gen_start_time_s))

sleep 5
echo "sign"
sign_start_time=$(date +%Y%m%d-%H:%M:%S)
sign_start_time_s=$(date +%s)

for i in $(seq 1 $((t + 1))); do
	echo "signing for client $i out of $((t + 1))"
	./target/release/examples/gg18_sign_client http://127.0.0.1:8001 bin/gg18/keys$i.store "KZen Networks" &
	sleep 3
done

sign_end_time=$(date +%Y%m%d-%H:%M:%S)
sign_end_time_s=$(date +%s)
sign_time=$(($sign_end_time_s - $sign_start_time_s))

echo "-------------------"
echo "-- Time Analysis --"
echo "-------------------"

echo "Ket Gen Time($key_gen_start_time --> $key_gen_end_time): $key_gen_time"
echo "Sign Time($sign_start_time --> $sign_end_time): $sign_time"

killall sm_manager 2>/dev/null
