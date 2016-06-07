<?php
   class MyDB extends SQLite3
   {
      function __construct()
      {
         $this->open('SERVERS.SQLite');
      }
   }
   $db = new MyDB();
   if(!$db){
      echo $db->lastErrorMsg();
   }
?>