/*
We find so many hyerarcy type (Parent/Child) information around us. Such as We have a Planet, In the Planet we have 7 Continent,
In The continent we have many countries, In each country we have many cities and so on. 
So We need to save this data with hierarchy.
Example:
Earth->Asia, Africa, Europe, South America, North America, Antartica,Oceania
Asia-> Bangladesh, Chaina, Japan
Europe-> UK, Germany
Bangladesh-> Dhaka

Now we are going to create a table and save all the informations using HierarcyID dataType
*/

DECLARE @tbl_Planet as TABLE (nGeoID hierarchyid NOT NULL, sGeoName nvarchar(30),sGeoType nvarchar(9))

-- root
INSERT INTO @tbl_Planet VALUES ('/', 'Earth', 'Planet')  

-- first Hierarchy
INSERT INTO @tbl_Planet VALUES
('/1/','Asia','Continent')
,('/2/','Africa','Continent')
,('/3/','Oceania','Continent')

-- second Hierarchy
INSERT INTO @tbl_Planet VALUES
 ('/1/1/','China','Country')
,('/1/2/','Japan','Country')
,('/1/3/','South Korea','Country')
,('/2/1/','South Africa','Country')
,('/2/2/','Egypt','Country')
,('/3/1/','Australia','Country')

-- third level data
INSERT INTO @tbl_Planet VALUES
('/1/1/1/','Beijing','City')
,('/1/2/1/','Tokyo','City')
,('/1/3/1/','Seoul','City')
,('/2/1/1/','Pretoria','City')
,('/2/2/1/','Cairo','City')
,('/3/1/1/','Canberra','City')

--SELECT * FROm @tbl_Planet
SELECT pt.nGeoID.ToString() AS [Geo_Text]
,pt.nGeoID.GetLevel() AS [Geo_Level]
,pt.sGeoName,pt.sGeoType
FROm @tbl_Planet as Pt
