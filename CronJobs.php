<?php
/*
  CronJobs.php
  Gestion-server

  Created by Kevin Bertrand on 21/09/2022.
*/

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$dbHost = $_ENV['DATABASE_HOST'];
$dbPort = $_ENV['DATABASE_PORT'];
$dbUser = $_ENV['DATABASE_USERNAME'];
$dbPassword = $_ENV['DATABASE_PASSWORD'];
$dbName = $_ENV['DATABASE_NAME'];

$dbconn = pg_connect("host=" . $dbHost . " port=" . $dbPort . " dbname=" . $dbName . " user=" . $dbUser . " password=" . $dbPassword)
    or die('Could not connect: ' . pg_last_error());

echo "ok";
?>
