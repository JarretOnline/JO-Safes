CREATE TABLE `safes` (
  `safeid` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `owner` varchar(50) NOT NULL,
  `coords` longtext NOT NULL,
  `object` varchar(50) NOT NULL,
  `cids` longtext NOT NULL DEFAULT '[]',
  `item` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
