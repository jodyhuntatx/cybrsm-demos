USE petclinic;

INSERT INTO types (name)
VALUES
("dog"),
("cat"),
("bird")
;
INSERT INTO owners (first_name, last_name, address, city, telephone, covid_vaccinated)
VALUES
("Sally", "Fields", "3 Sunset Blvd.", "Los Angeles", "713-555-1212", "Y"),
("Joe", "Montana", "123 Sandhill Rd.", "San Francisco", "999-555-1212", "N"),
("Bob", "Ross", "123 Happy Valley Dr.", "San Francisco", "999-555-1212", "N")
;
INSERT INTO pets (name, birth_date, type_id, owner_id)
VALUES
("Anya", '2014-01-01', 1, 1),
("Mischa", '2013-01-01', 2, 2),
("Lev", '2020-10-25', 3, 3)
;
