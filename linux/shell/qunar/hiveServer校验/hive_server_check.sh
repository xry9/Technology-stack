#!/bin/sh
set -e

_ids=$(mysql -hl-dw1.f.cn5 -uf_qmd_w -pdmF8GK0HxYoR3I5t -D f_check --default-character-set=utf8 -N -e"select id from hive_server_check where valid=1")

for _id in ${_ids}
do
  python hive_server_check.py ${_id} &
done

wait
echo "hiveserver校验完成"
