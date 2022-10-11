-- This file must be executed with the MSSQLserver CLI (sqlcmd)
-- The double-braced placeholders must be replace with correct values, e.g. with sed.

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'{{ USERNAME }}')
BEGIN
CREATE LOGIN {{ USERNAME }} WITH PASSWORD = '{{ PASSWORD }}'
    CREATE USER {{ USERNAME }} FOR LOGIN {{ USERNAME }}
    EXEC sp_addrolemember N'db_owner', N'{{ USERNAME }}'
END;
GO

ALTER AUTHORIZATION ON DATABASE::{{ DATABASE }} TO {{ USERNAME }}
GO

