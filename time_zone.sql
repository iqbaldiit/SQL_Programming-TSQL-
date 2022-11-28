--DECLARE @TimeZone VARCHAR(50)
--EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE',
--'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
--'TimeZoneKeyName',@TimeZone OUT
--SELECT @TimeZone
--SELECT CURRENT_TIMEZONE();
--SELECT CURRENT_TIMEZONE_ID()
----
select * from sys.time_zone_info as tm WHERE name like '%India%'

--get current datetime by each timezone
SELECT tm.*
,CONVERT(DATETIME, SYSDATETIMEOFFSET() AT TIME ZONE tm.name) AS current_datetime
FROM sys.time_zone_info as tm 
WHERE name like '%New Zealand Standard Time%'


-- data migration to local table
SELECT * FROM Auth.Time_Zone WHERE short_name='BST'
---INSERT INTO Auth.Time_Zone
select tm.name,
CASE WHEN tm.name not like '%UTC%' THEN dbo.[fn_get_first_letter_from_line](REPLACE(tm.name,'(',''))
	ELSE tm.name END
,tm.is_currently_dst,tm.current_utc_offset from sys.time_zone_info tm 
--WHERE name like '%UTC%'

--insert into time_zone_country

SELECT * FROM Auth.Time_Zone_Country
--INSERT INTO Auth.Time_Zone_Country
--SELECT 1,97,18,NULL,NULL,7,GETDATE()
SELECT * FROM Administrative.Country WHERE country_name='Bangladesh'


SELECT * FROM Calendar_TimeZones



