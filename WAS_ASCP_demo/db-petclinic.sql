-- Taken from:
-- https://github.com/spring-petclinic/spring-petclinic-microservices/blob/master/spring-petclinic-customers-service/src/main/resources/db/mysql/schema.sql
-- Adapted for MSSQLserver

-- If database exists, drop and create anew
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'petclinic')
BEGIN
    DROP DATABASE petclinic;  
END;

CREATE DATABASE petclinic;
GO

USE petclinic;
GO

CREATE TABLE types (
  id INT IDENTITY (1, 1) NOT NULL PRIMARY KEY,
  name VARCHAR (80)
);

CREATE TABLE owners (
  id INT IDENTITY (1, 1) NOT NULL PRIMARY KEY,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  address VARCHAR(255),
  city VARCHAR(80),
  telephone VARCHAR(20)
);

CREATE TABLE pets (
  id INT IDENTITY (1, 1) NOT NULL PRIMARY KEY,
  name VARCHAR(30),
  birth_date DATE,
  type_id INT NOT NULL,
  owner_id INT NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES owners(id),
  FOREIGN KEY (type_id) REFERENCES types(id)
);
GO

INSERT INTO types (name)
VALUES
("dog"),
("cat"),
("bird")
;

INSERT INTO owners (first_name, last_name, address, city, telephone)
VALUES
("Sally", "Fields", "3 Sunset Blvd.", "Los Angeles", "713-555-1212"),
("Joe", "Montana", "123 Sandhill Rd.", "San Francisco", "999-555-1212"),
("Bob", "Ross", "123 Happy Valley Dr.", "San Francisco", "999-555-1212")
;

INSERT INTO pets (name, birth_date, type_id, owner_id)
VALUES
("Uri", '2014-01-01', 1, 1),
("Lilah", '2013-01-01', 2, 2),
("Max", '2019-01-01', 3, 3)
;
