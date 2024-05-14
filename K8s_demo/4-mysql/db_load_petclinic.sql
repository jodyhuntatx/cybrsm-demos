USE petclinic;

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
("Elsie", '2020-10-25', 3, 3)
;
