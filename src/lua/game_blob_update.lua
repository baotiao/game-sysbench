#!/usr/bin/env sysbench

-- This test is designed for testing MariaDB's key_cache_segments for MyISAM,
-- and should work with other storage engines as well.
--
-- For details about key_cache_segments please refer to:
-- http://kb.askmonty.org/v/segmented-key-cache
--
-- require("oltp_common")
-- Override standard prepare/cleanup OLTP functions, as this benchmark does not
-- support multiple tables
-- oltp_prepare = prepare
-- oltp_cleanup = cleanup
sysbench.cmdline.options = {
    table_size = {"Number of rows per table", 10000},
    tables = {"Number of tables", 1},
    --default blob size is 100kb
    blob_length = {"blob column length", 102400},
    selects = {"select data", 0},
    updates = {"update data", 0},
    inserts = {"insert data", 0}
}

function create_table(drv, con, table_num)
    local id_def = "bigint(20) unsigned not null auto_increment"
    local engine_def = "engine = InnoDB"
    local extra_table_options = "default charset=utf8mb4"
    local query
    local uid_val
    local data_val

    query = string.format([[
    CREATE TABLE IF NOT EXISTS `user_data%d`(
    `uid` %s,
    `data` mediumblob NOT NULL,
     PRIMARY KEY (`uid`)
    ) %s %s]], table_num, id_def, engine_def, extra_table_options)

    print(string.format("Creating table 'user_data%d'", table_num))
    con:query(query)
    print(string.format("Inserting %d records into 'user_data%d'",
                        sysbench.opt.table_size, table_num))
    query = "INSERT INTO user_data" .. table_num .. "(`uid`, `data`) VALUES"
    con:bulk_insert_init(query)

    -- prepare data
    for i = 1, sysbench.opt.table_size do
        uid_val = i
        data_val = string.format("concat(repeat(md5(rand()), %d/32), left(md5(rand()), %d%%32))", sysbench.opt.blob_length, sysbench.opt.blob_length)
        query = string.format("(%d, %s)", uid_val, data_val)
        con:bulk_insert_next(query)
    end
    con:bulk_insert_done()
end

function cmd_prepare()
    local drv = sysbench.sql.driver()
    local con = drv:connect()
    for i = sysbench.tid % sysbench.opt.threads + 1, sysbench.opt.tables, sysbench.opt.threads do
        create_table(drv, con, i)
    end
end

-- Implement parallel prepare and prewarm commands
sysbench.cmdline.commands = {
    prepare = {cmd_prepare, sysbench.cmdline.PARALLEL_COMMAND}
}

function cleanup()
    local drv = sysbench.sql.driver()
    local con = drv:connect()
    for i = 1, sysbench.opt.tables do
        print("Dropping table user_data" .. i)
        con:query("DROP TABLE IF EXISTS user_data" .. i)
    end
end

local function get_table_num()
    return sysbench.rand.uniform(1, sysbench.opt.tables)
end

function execute_user_data_select()
    local i = sysbench.rand.uniform(1, sysbench.opt.table_size)
    local table_name = string.format("user_data%d", get_table_num())
    con:query(string.format("select length(data) from %s where uid= %d",
                            table_name, i))
end

function execute_user_data_update()
    -- todo 数据分布
    local uid_val = sysbench.rand.uniform(1, sysbench.opt.table_size)
    local data_val = string.format(
                         "concat(repeat(md5(rand()), %d/32), left(md5(rand()), %d%%32))",
                         sysbench.opt.blob_length, sysbench.opt.blob_length)
    local query = string.format(
                      "UPDATE user_data%d SET `data` = %s WHERE `uid` = %d",
                      get_table_num(), data_val, uid_val)
    con:query(query);
end

function execute_user_data_insert()
    local table_num = get_table_num()
    local query1 = "INSERT INTO user_data" .. table_num ..
                       "(`uid`, `data`) VALUES"
    local uid_val = 0
    local data_val = string.format(
                         "concat(repeat(md5(rand()), %d/32), left(md5(rand()), %d%%32))",
                         sysbench.opt.blob_length, sysbench.opt.blob_length)
    local query = string.format("%s (%d, %s)", query1, uid_val, data_val)
    con:query(query);
end

function thread_init(thread_id)
    drv = sysbench.sql.driver()
    con = drv:connect()
end

function thread_done() con:disconnect() end

function event()
    local uid = sysbench.rand.default(1, sysbench.opt.table_size)
    if sysbench.opt.selects == 1 then execute_user_data_select() end
    if sysbench.opt.updates == 1 then execute_user_data_update() end
    if sysbench.opt.inserts == 1 then execute_user_data_insert() end
end
