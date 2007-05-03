INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Mark', 'Waber', 'MW', '99c15d92ebc0e182e5c4df7c7e9e30ce96a863df', 'waber@puzzle.ch', TRUE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Lucien', 'Weller', 'LW', 'b1e2e3ae26f1849f6f819475f53ed1fe23965c50', 'weller@puzzle.ch', FALSE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Pascal', 'Zumkehr', 'PZ', '5ffaa7bd95eb19342dcbb20cc58fc75e712c5847', 'zumkehr@puzzle.ch', FALSE);

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

INSERT INTO clients (id, name, shortname)
VALUES (1, 'Puzzle ITC', 'PITC');

INSERT INTO projects (id, client_id, name, shortname)
VALUES (8, 1, 'Allgemein', 'ALG');

INSERT INTO projectmemberships (project_id, employee_id)
VALUES (8, 1);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (8, 2);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (8, 3);