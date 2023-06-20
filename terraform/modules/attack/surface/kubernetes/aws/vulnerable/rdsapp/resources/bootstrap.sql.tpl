CREATE DATABASE IF NOT EXISTS ${ database_name };
USE ${ database_name };
CREATE TABLE IF NOT EXISTS cast (id MEDIUMINT NOT NULL AUTO_INCREMENT,firstName VARCHAR(120),lastName VARCHAR(120),characterName VARCHAR(120),PRIMARY KEY (id));
TRUNCATE TABLE cast;
INSERT INTO cast (firstName, lastName, characterName) VALUES
    ('William', 'Shatner', 'James T. Kirk'),
    ('Leonard', 'Nimoy', 'Spock'),
    ('DeForest', 'Kelley', 'Leonard McCoy'),
    ('James', 'Doohan', 'Montgomery Scott'),
    ('Walter', 'Koenig', 'Pavel Chekov'),
    ('Nichelle', 'Nichols', 'Nyota Uhura'),
    ('George', 'Takei', 'Hikaru Sulu'),
    ('Ricardo', 'Montalban', 'Khan Noonien Singh');
CREATE USER IF NOT EXISTS ${ iam_db_user }@'%' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT USAGE ON *.* TO '${ iam_db_user }'@'%' REQUIRE SSL;
GRANT ALL PRIVILEGES ON ${ database_name }.* TO '${ iam_db_user }'@'%' REQUIRE SSL;
ALTER USER '${ iam_db_user }'@'%' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
FLUSH PRIVILEGES;