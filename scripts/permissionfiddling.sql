
----------------------------------------------------------------------------------------------
-- AUTHOR: William Bratz
-- Date: 03/08/16
----------------------------------------------------------------------------------------------


--for database (updated for newer versions)
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Updateability')

--for tables.
SELECT
   *
FROM
   sys.tables t
   LEFT JOIN
   sys.database_permissions dp2 ON dp2.major_id = t.object_id AND dp2.permission_name = 'SELECT'
WHERE t.name
   NOT IN (SELECT t.name FROM 
         sys.database_permissions dp
	    JOIN SYS.tables t
	  ON  dp.major_id = t.object_id
         AND
         dp.permission_name IN ('INSERT', 'DELETE', 'UPDATE'))


SELECT  *
FROM
   sys.tables t
   JOIN
   sys.database_permissions dp2 ON dp2.major_id = t.object_id AND dp2.permission_name = 'SELECT'
WHERE
   dp2.grantee_principal_id = USER_ID()
   AND
   dp2.permission_name IN ('INSERT', 'DELETE', 'UPDATE')


   SELECT name, is_read_only 
FROM sys.databases 

--CHECK IF YOU'RE IN A GROUP
SELECT IS_MEMBER('IT')

--FIND LIST OF USERS
EXEC xp_logininfo 
@acctname = 'IT',
@option = 'members'