CREATE DATABASE IF NOT EXISTS ${ db_name };
USE ${ db_name };
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
GRANT USAGE ON *.* TO '${ db_user }'@'%' REQUIRE SSL;
GRANT ALL PRIVILEGES ON ${ db_name }.* TO '${ db_user }'@'%' REQUIRE SSL;
GRANT USAGE ON *.* TO '${ db_iam_user }'@'%' REQUIRE SSL;
GRANT ALL PRIVILEGES ON ${ db_name }.* TO '${ db_iam_user }'@'%' REQUIRE SSL;
FLUSH PRIVILEGES;