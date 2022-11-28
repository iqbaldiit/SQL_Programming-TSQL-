DECLARE 
@param_schema_name as varchar (100)
,@param_table_name as varchar(100)
,@param_unique_fields as varchar (500)
,@param_foreign_key_fields as varchar (500)

SET @param_schema_name='Administrative'
SET @param_table_name='Ownership_Type'
SET @param_unique_fields='ownership_type_name'



DECLARE
@pav_unique_constraint_name as varchar(500)
,@pv_sql as varchar(max)


SET @pav_unique_constraint_name='UC_'+@param_unique_fields

--SELECT @pav_unique_constraint_name

SET @pv_sql=
'ALTER TABLE '+@param_schema_name+'.'+@param_table_name+'
ADD CONSTRAINT '+@pav_unique_constraint_name+' UNIQUE ('+@param_unique_fields+');'

EXEC (@pv_sql)
--SELECT @pv_sql

--ALTER TABLE Orders
--ADD CONSTRAINT FK_PersonOrder
--FOREIGN KEY (PersonID) REFERENCES Persons(PersonID);