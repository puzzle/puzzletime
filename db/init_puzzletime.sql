INSERT INTO masterdatas	(musthours_day, vacations_year)
VALUES (8.0, 20);

INSERT INTO employees (firstname, lastname, shortname, passwd, email, phone, management)
VALUES ('Mark', 'Waber', 'mw', '99c15d92ebc0e182e5c4df7c7e9e30ce96a863df', 'waber@puzzle.ch', '031 370 22 00', TRUE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, phone, management)
VALUES ('Lucien', 'Weller', 'lw', 'b1e2e3ae26f1849f6f819475f53ed1fe23965c50', 'weller@puzzle.ch', '031 370 22 00', FALSE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, phone, management)
VALUES ('Pascal', 'Zumkehr', 'pz', '5ffaa7bd95eb19342dcbb20cc58fc75e712c5847', 'zumkehr@puzzle.ch', '031 370 22 42', FALSE);

INSERT INTO absences (name, payed)
VALUES ('Ferien', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Krankheit', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Militär', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Zivildienst', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Artzbesuch', FALSE);
INSERT INTO absences (name, payed)
VALUES ('Heirat', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Todesfall', TRUE);
