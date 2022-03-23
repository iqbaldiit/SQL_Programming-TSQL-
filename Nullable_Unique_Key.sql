
CREATE UNIQUE NONCLUSTERED INDEX <index_name>
ON <schema.table_name(unique_column_id)>
WHERE <unique_column_id> IS NOT NULL AND <unique_column_id>!='';

--example for national ID
CREATE UNIQUE NONCLUSTERED INDEX UC_national_id
ON Auth.Users(national_id)
WHERE national_id IS NOT NULL AND national_id!='';

