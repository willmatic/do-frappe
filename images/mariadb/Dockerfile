FROM mariadb:10.6

# Set environment variables
# MARIADB IS FOR TESTING PURPOSES AND IT'S NOT RECCOMENDED TO BE DEPLOYED IN DO APP PLATFORM.
#   IT WILL LOSE THE DATA ON EVERY DEPLOYMENT.
# EITHER USE MANAGED DB OR SETUP YOUR OWN MARIADB SERVER.
ENV MYSQL_ROOT_PASSWORD=pEBMMlB1s2H6oBQE07Bw4phoQhnlqSGa

# Configure healthcheck
HEALTHCHECK --interval=1s --retries=15 CMD mysqladmin ping -h localhost --password=$MYSQL_ROOT_PASSWORD

# Set the command with all required options
CMD ["mariadbd", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci", "--skip-character-set-client-handshake", "--skip-innodb-read-only-compressed"]
