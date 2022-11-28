Declare @YourTable Table (id int,[EQUATION] varchar(150))
Insert Into @YourTable Values 
 (1,'2+5')
,(2,'6+8')
,(3,'6+9')  


Declare @SQL varchar(max) = Stuff((Select ',' + concat('(',ID,',',[EQUATION],')')
                                     From @YourTable  A
                                     For XML Path (''))
                                 ,1,1,'')
Exec('Select * from (values ' + @SQL + ')A([ID],[Value])')