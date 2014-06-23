-- employee
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Mark', 'Waber', 'MW', '99c15d92ebc0e182e5c4df7c7e9e30ce96a863df', 'waber@puzzle.ch', TRUE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Lucien', 'Weller', 'LW', 'b1e2e3ae26f1849f6f819475f53ed1fe23965c50', 'weller@puzzle.ch', FALSE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Pascal', 'Zumkehr', 'PZ', '5ffaa7bd95eb19342dcbb20cc58fc75e712c5847', 'zumkehr@puzzle.ch', FALSE);
INSERT INTO employees (firstname, lastname, shortname, passwd, email, management)
VALUES ('Simon', 'Fankhauser', 'SF', '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', 'fankhauser@puzzle.ch', FALSE); -- passwd = 'a'

-- employments
INSERT INTO employments (id, employee_id, percent, start_date, end_date)
VALUES (1, 1, 100, '2005/01/01', '2020/12/31');
INSERT INTO employments (id, employee_id, percent, start_date, end_date)
VALUES (2, 2, 80, '2006/01/01', '2020/12/31');
INSERT INTO employments (id, employee_id, percent, start_date, end_date)
VALUES (3, 3, 60, '2007/01/01', '2020/12/31');
INSERT INTO employments (id, employee_id, percent, start_date, end_date)
VALUES (4, 4, 40, '2008/01/01', '2020/12/31');

-- absences
INSERT INTO absences (name, payed)
VALUES ('Ferien', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Krankheit', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Militär', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Zivildienst', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Arztbesuch', FALSE);
INSERT INTO absences (name, payed)
VALUES ('Heirat', TRUE);
INSERT INTO absences (name, payed)
VALUES ('Todesfall', TRUE);

-- clients
INSERT INTO clients (id, name, shortname)
VALUES (1, 'Puzzle ITC', 'PITC');
INSERT INTO clients (id, name, shortname)
VALUES (2, 'Client AG', 'CLIE');

-- projects
INSERT INTO projects (id, client_id, name, shortname, path_ids)
VALUES (8, 1, 'Allgemein', 'ALG', ARRAY[8]);
INSERT INTO projects (id, client_id, name, shortname, path_ids)
VALUES (9, 1, 'Kundensupport', 'SUP', ARRAY[9]);
INSERT INTO projects (id, client_id, name, shortname, path_ids)
VALUES (10, 2, 'Produktives', 'PRO', ARRAY[10]);
INSERT INTO projects (id, client_id, name, shortname, path_ids)
VALUES (11, 2, 'Administratives', 'ADM', ARRAY[11]);

-- project memberships
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (8, 1);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (8, 2);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (9, 3);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (9, 4);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (10, 4);
INSERT INTO projectmemberships (project_id, employee_id)
VALUES (11, 3);