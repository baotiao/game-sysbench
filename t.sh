#!/bin/sh
set -x

bench_type=oltp_read_write;
threads=256
tables=25
port=2260
user=replicator
run_time=120
# table_size=40000000
table_size=100
mysql_host=""
mybench="sysbench"

usage()
{
  echo "Usage: $0 [-b bench_type] [-t threads] [-ta tables] [-p port] [-u user]"
  echo "Note: this script is intended for running sysbench"
  echo "Example: sh t.sh -mh 127.0.0.1 -t 128"
}
get_key_value()
{
  echo "$1" | sed 's/^--[a-zA-Z_-]*=//'
}
parse_options()
{
  while test $# -gt 0
  do
    case "$1" in
    -b)
      shift
      bench_type=`get_key_value "$1"`;;
    -t)
      shift
      threads=`get_key_value "$1"`;;
    -ta)
      shift
      tables=`get_key_value "$1"`;;
    -p)
      shift
      port=`get_key_value "$1"`;;
    -u)
      shift
      user=`get_key_value "$1"`;;
    -rt)
      shift
      run_time=`get_key_value "$1"`;;
    -ts)
      shift
      table_size=`get_key_value "$1"`;;
    -mh)
      shift
      mysql_host=`get_key_value "$1"`;;
    -h | --help)
      usage
      exit 0;;
    *)
      echo "Unknown option '$1'"
      exit 1;;
    esac
    shift
  done
}

echo_commands()
{
echo "build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads --report-interval=1 --rand-type=uniform prepare"
echo "build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads  --max-time=$run_time --report-interval=1 --rand-type=uniform run"
echo "build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads --rand-type=uniform --report-interval=1 cleanup"
}

parse_options "$@"
echo_commands

# origin bench
# build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=table_size --threads=$threads --rand-type=uniform --report-interval=1 cleanup
# build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads --report-interval=1 --rand-type=uniform prepare
# build/bin/sysbench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads  --max-time=$run_time --report-interval=1 --rand-type=uniform run

# game bench
$mybench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=table_size --threads=$threads --rand-type=uniform --report-interval=1 cleanup
$mybench  $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads --report-interval=1 --rand-type=uniform prepare
$mybench $bench_type --mysql-host=$mysql_host --mysql-port=$port --mysql-password=22192219 --mysql-user=$user --tables=$tables --table_size=$table_size --threads=$threads --report-interval=1 --rand-type=uniform --inserts=1 --blob_length=1024000 run
