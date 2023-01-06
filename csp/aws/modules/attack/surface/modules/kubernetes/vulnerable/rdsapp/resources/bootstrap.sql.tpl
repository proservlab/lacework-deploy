CREATE DATABASE IF NOT EXISTS dev;
CREATE TABLE IF NOT EXISTS dev.product (id MEDIUMINT NOT NULL AUTO_INCREMENT, prodId VARCHAR(120), prodName VARCHAR(120), PRIMARY KEY (id));
TRUNCATE TABLE dev.product;
INSERT INTO dev.product (prodId,prodName) VALUES ('998','Sweet Pea');
INSERT INTO dev.product (prodId,prodName) VALUES ('999','Honeysuckle');
CREATE USER IF NOT EXISTS ${ iam_db_user } IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT USAGE ON *.* TO '${ iam_db_user }'@'%'REQUIRE SSL;
GRANT ALL PRIVILEGES ON dev.* TO '${ iam_db_user }'@'%'REQUIRE SSL;
FLUSH PRIVILEGES;