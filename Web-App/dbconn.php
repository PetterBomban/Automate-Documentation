<?php
   class MyDB extends SQLite3
   {
      function __construct()
      {
         //TODO
         $this->open('./SERVERS.SQLite');
      }
   }
   $db = new MyDB();
   if(!$db){
      echo $db->lastErrorMsg();
   }
?>