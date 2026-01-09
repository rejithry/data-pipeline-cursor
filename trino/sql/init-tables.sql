 CREATE TABLE iceberg.default.weather (   
    city varchar,                         
    temperature varchar,                  
    ts timestamp with time zone                            
 )                                        
 WITH (                                   
    compression_codec = 'ZSTD',           
    format = 'PARQUET',                   
    format_version = 2,                   
    location = 's3a://warehouse//weather' ,
    partitioning = ARRAY['hour(ts)']
 ) ;