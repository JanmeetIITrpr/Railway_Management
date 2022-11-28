-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 14, 2022 at 08:25 PM
-- Server version: 10.4.13-MariaDB
-- PHP Version: 7.4.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `railway_management`
--
CREATE DATABASE IF NOT EXISTS `railway_management` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `railway_management`;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `assign_berth` (IN `tnum` INT, IN `jdate` DATE, IN `ctype` VARCHAR(2), IN `pname` VARCHAR(100), IN `pnr` VARCHAR(12))  BEGIN
	declare b_ac int;
    declare b_sl int;
    declare berth_num int;
    declare coach_num int;
    declare berth_type varchar(2);
    declare seat varchar(7);

    
    select booked_ac, booked_sl
    from train where train_num = tnum and journey_date = jdate
    into b_ac, b_sl;
    
    if ctype like 'AC' THEN
    	update train
        set booked_ac = booked_ac + 1
        where train_num = tnum and journey_date = jdate;
   elseif ctype like 'SL' then 
   		update train
        set booked_sl = booked_sl + 1
        where train_num= tnum and journey_date = jdate;
   end if;
   
   if ctype like 'AC' THEN
    	set coach_num = floor(b_ac/18) +1;
        set berth_num = b_ac%18 +1;
        case berth_num %6
        	when 1 THEN
            	set berth_type ='LB';
            when 2 THEN
            	set berth_type ='LB';
            when 3 THEN
            	set berth_type ='UB';
            when 4 THEN
            	set berth_type ='UB';
            when 5 THEN
            	set berth_type ='SL';
            when 0 THEN
        	  	set berth_type ='SU';
        end case;
   	elseif ctype like 'SL' THEN
   		set coach_num = floor(b_sl/24) +1;
        set berth_num = b_sl%24 +1;
        case berth_num %8
        	when 1 THEN
            	set berth_type ='LB';
            when 2 THEN
            	set berth_type ='MB';
            when 3 THEN
            	set berth_type ='UB';
            when 4 THEN
            	set berth_type ='LB';
            when 5 THEN
            	set berth_type ='MB';
            when 6 THEN
        	  	set berth_type ='UB';
            when 7 THEN
        	  	set berth_type ='SL';
            when 0 THEN
        	  	set berth_type ='SU';
        end case;
    end if;

    set seat = CONCAT(ctype, coach_num , '-',berth_num);
    insert into passenger values(pnr,tnum,seat,berth_type,pname);
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_seat_availability` (IN `tnum` INT, IN `jdate` DATE, IN `num_p` INT, IN `ctype` VARCHAR(2))  begin 
	declare b_ac int;
    declare b_sl int;
    declare n_ac int;
    declare n_sl int;
    
    select num_ac, num_sl, booked_ac, booked_sl
    from train
    where train_num=tnum and journey_date = jdate
    into n_ac, n_sl, b_ac, b_sl;
    
    if ctype = 'AC' then 
    	if b_ac+num_p >n_ac * 18 then
        	signal SQLSTATE '45000'
        	set message_text = 'Insufficient number of seats. Cannot book ticket';
        end if;
    elseif ctype = 'SL' then 
    	if b_sl + num_p >n_sl*24 THEN
        SIGNAL SQLSTATE '45000'
        	set message_text ='Insufficient number of seats. Cannot book ticket';
        end if;
    end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_train` (IN `tnum` INT, IN `jdate` DATE)  BEGIN
	declare done int;
    declare flag enum('0','1') default '0';
	declare t int;
    declare d date;
    declare train_exist cursor for select train_num, journey_date from train where train_num = tnum;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    open train_exist;
    get_train: LOOP
    	fetch train_exist into t, d;
        if done = 1 THEN
        	SIGNAL SQLSTATE '45000'
        	set message_text = 'Train does not exist';
            leave get_train;
        else
        	if jdate < CURRENT_DATE() then
                SIGNAL SQLSTATE '45000'
            	set MESSAGE_TEXT = 'Invalid Date';
                leave get_train;
            else
            	if jdate = d then
                	set flag = '1';
                    leave get_train;
                end if;
            end if;
        end if;
    end loop;
    close train_exist;
    
	if flag = 0 then
    	SIGNAL SQLSTATE '45000'
    	set message_text = 'Train not scheduled on entered date';
    end if;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generate_pnr` ()  BEGIN
	declare p1 int;
    declare p2 int;
    declare p3 int;
    declare pnr varchar(12);
    set p1 = LPAD(cast(conv(substring(md5(CURRENT_TIMESTAMP()), 1, 16), 16, 10)%10000 as unsigned integer), 3, '0');
    set p2 = LPAD(FLOOR(RAND() * 999999.99),3,'0');
    SET p3 = LPAD(FLOOR(RAND() * 999999.99),4,'0');
    SET pnr = RPAD(CONCAT(p1, '-', p2, '-', p3), 12, '0');

    select pnr;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `passenger`
--

CREATE TABLE `passenger` (
  `pnr` char(12) DEFAULT NULL,
  `train_num` int(11) DEFAULT NULL,
  `seat_num` varchar(7) DEFAULT NULL,
  `berth_type` enum('LB','MB','UB','SL','SU') DEFAULT NULL,
  `name` varchar(256) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `pnr` char(12) NOT NULL,
  `booked_date` date DEFAULT NULL,
  `num_passenger` int(11) DEFAULT NULL,
  `journey_date` date DEFAULT NULL,
  `train_num` int(11) DEFAULT NULL,
  `coach_type` enum('SL','AC') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Triggers `tickets`
--
DELIMITER $$
CREATE TRIGGER `check_all` BEFORE INSERT ON `tickets` FOR EACH ROW BEGIN
	call check_train(new.train_num, new.journey_date);
    call check_seat_availability(new.train_num, new.journey_date, new.num_passenger, new.coach_type);
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `train`
--

CREATE TABLE `train` (
  `train_num` int(11) NOT NULL,
  `num_ac` int(11) DEFAULT NULL,
  `num_sl` int(11) DEFAULT NULL,
  `booked_ac` int(11) DEFAULT 0,
  `booked_sl` int(11) DEFAULT 0,
  `journey_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `passenger`
--
ALTER TABLE `passenger`
  ADD KEY `pnr` (`pnr`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`pnr`),
  ADD KEY `train_num` (`train_num`,`journey_date`);

--
-- Indexes for table `train`
--
ALTER TABLE `train`
  ADD PRIMARY KEY (`train_num`,`journey_date`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `passenger`
--
ALTER TABLE `passenger`
  ADD CONSTRAINT `passenger_ibfk_1` FOREIGN KEY (`pnr`) REFERENCES `tickets` (`pnr`);

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`train_num`,`journey_date`) REFERENCES `train` (`train_num`, `journey_date`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


-- -- phpMyAdmin SQL Dump
-- -- version 5.0.2
-- -- https://www.phpmyadmin.net/
-- --
-- -- Host: 127.0.0.1
-- -- Generation Time: Nov 15, 2022 at 09:58 PM
-- -- Server version: 10.4.13-MariaDB
-- -- PHP Version: 7.4.7

-- SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
-- START TRANSACTION;
-- SET time_zone = "+00:00";


-- /*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
-- /*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
-- /*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
-- /*!40101 SET NAMES utf8mb4 */;

-- --
-- -- Database: `railway_management`
-- --
-- CREATE DATABASE IF NOT EXISTS `railway_management` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
-- USE `railway_management`;

-- DELIMITER $$
-- --
-- -- Procedures
-- --
-- CREATE DEFINER=`root`@`localhost` PROCEDURE `assign_berth` (IN `tnum` INT, IN `jdate` DATE, IN `ctype` VARCHAR(2), IN `pname` VARCHAR(100), IN `pnr` VARCHAR(12), IN `counter` INT)  BEGIN
--     declare berth_num int;
--     declare coach_num int;
--     declare berth_type varchar(2);
--     declare seat varchar(7);
   
--    if ctype like 'AC' THEN
--     	set coach_num = floor(counter/18) +1;
--         set berth_num = counter%18 +1;
--         case berth_num %6
--         	when 1 THEN
--             	set berth_type ='LB';
--             when 2 THEN
--             	set berth_type ='LB';
--             when 3 THEN
--             	set berth_type ='UB';
--             when 4 THEN
--             	set berth_type ='UB';
--             when 5 THEN
--             	set berth_type ='SL';
--             when 0 THEN
--         	  	set berth_type ='SU';
--         end case;
--    	elseif ctype like 'SL' THEN
--    		set coach_num = floor(counter/24) +1;
--         set berth_num = counter%24 +1;
--         case berth_num %8
--         	when 1 THEN
--             	set berth_type ='LB';
--             when 2 THEN
--             	set berth_type ='MB';
--             when 3 THEN
--             	set berth_type ='UB';
--             when 4 THEN
--             	set berth_type ='LB';
--             when 5 THEN
--             	set berth_type ='MB';
--             when 6 THEN
--         	  	set berth_type ='UB';
--             when 7 THEN
--         	  	set berth_type ='SL';
--             when 0 THEN
--         	  	set berth_type ='SU';
--         end case;
--     end if;

--     set seat = CONCAT(ctype, coach_num , '-',berth_num);
--     insert into passenger values(pnr,tnum,seat,berth_type,pname);
-- end$$

-- CREATE DEFINER=`root`@`localhost` PROCEDURE `check_seat_availability` (IN `tnum` INT, IN `jdate` DATE, IN `num_p` INT, IN `ctype` VARCHAR(2))  begin 
-- 	declare b_ac int;
--     declare b_sl int;
--     declare n_ac int;
--     declare n_sl int;
    
--     select num_ac, num_sl, booked_ac, booked_sl
--     from train
--     where train_num=tnum and journey_date = jdate
--     into n_ac, n_sl, b_ac, b_sl;
    
--     if ctype = 'AC' then 
--     	if b_ac+num_p >n_ac * 18 then
--         	signal SQLSTATE '45000'
--         	set message_text = 'Insufficient number of seats. Cannot book ticket';
--         end if;
--     elseif ctype = 'SL' then 
--     	if b_sl + num_p >n_sl*24 THEN
--         SIGNAL SQLSTATE '45000'
--         	set message_text ='Insufficient number of seats. Cannot book ticket';
--         end if;
--     end if;
-- end$$

-- CREATE DEFINER=`root`@`localhost` PROCEDURE `check_train` (IN `tnum` INT, IN `jdate` DATE)  BEGIN
-- 	declare done int;
--     declare flag enum('0','1') default '0';
-- 	declare t int;
--     declare d date;
--     declare train_exist cursor for select train_num, journey_date from train where train_num = tnum;
--     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
--     open train_exist;
--     get_train: LOOP
--     	fetch train_exist into t, d;
--         if done = 1 THEN
--         	SIGNAL SQLSTATE '45000'
--         	set message_text = 'Train does not exist';
--             leave get_train;
--         else
--         	if jdate < CURRENT_DATE() then
--                 SIGNAL SQLSTATE '45000'
--             	set MESSAGE_TEXT = 'Invalid Date';
--                 leave get_train;
--             else
--             	if jdate = d then
--                 	set flag = '1';
--                     leave get_train;
--                 end if;
--             end if;
--         end if;
--     end loop;
--     close train_exist;
    
-- 	if flag = 0 then
--     	SIGNAL SQLSTATE '45000'
--     	set message_text = 'Train not scheduled on entered date';
--     end if;

-- end$$

-- CREATE DEFINER=`root`@`localhost` PROCEDURE `generate_pnr` ()  BEGIN
-- 	declare p1 int;
--     declare p2 int;
--     declare p3 int;
--     declare pnr varchar(12);
--     set p1 = LPAD(cast(conv(substring(md5(CURRENT_TIMESTAMP()), 1, 16), 16, 10)%10000 as unsigned integer), 3, '0');
--     set p2 = LPAD(FLOOR(RAND() * 999999.99),3,'0');
--     SET p3 = LPAD(FLOOR(RAND() * 999999.99),4,'0');
--     SET pnr = RPAD(CONCAT(p1, '-', p2, '-', p3), 12, '0');

--     select pnr;
-- END$$

-- DELIMITER ;

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `passenger`
-- --

-- CREATE TABLE `passenger` (
--   `pnr` char(12) DEFAULT NULL,
--   `train_num` int(11) NOT NULL,
--   `seat_num` varchar(7) DEFAULT NULL,
--   `berth_type` enum('LB','MB','UB','SL','SU') DEFAULT NULL,
--   `name` varchar(256) DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `tickets`
-- --

-- CREATE TABLE `tickets` (
--   `pnr` char(12) NOT NULL,
--   `booked_date` date DEFAULT NULL,
--   `num_passenger` int(11) DEFAULT NULL,
--   `journey_date` date DEFAULT NULL,
--   `train_num` int(11) DEFAULT NULL,
--   `coach_type` enum('SL','AC') DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --
-- -- Triggers `tickets`
-- --
-- DELIMITER $$
-- CREATE TRIGGER `check_all` BEFORE INSERT ON `tickets` FOR EACH ROW BEGIN
-- 	call check_train(new.train_num, new.journey_date);
--     call check_seat_availability(new.train_num, new.journey_date, new.num_passenger, new.coach_type);
-- end
-- $$
-- DELIMITER ;

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `train`
-- --

-- CREATE TABLE `train` (
--   `train_num` int(11) NOT NULL,
--   `num_ac` int(11) DEFAULT NULL,
--   `num_sl` int(11) DEFAULT NULL,
--   `booked_ac` int(11) DEFAULT 0,
--   `booked_sl` int(11) DEFAULT 0,
--   `journey_date` date NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --
-- -- Indexes for dumped tables
-- --

-- --
-- -- Indexes for table `passenger`
-- --
-- ALTER TABLE `passenger`
--   ADD KEY `pnr` (`pnr`);

-- --
-- -- Indexes for table `tickets`
-- --
-- ALTER TABLE `tickets`
--   ADD PRIMARY KEY (`pnr`),
--   ADD KEY `train_num` (`train_num`,`journey_date`);

-- --
-- -- Indexes for table `train`
-- --
-- ALTER TABLE `train`
--   ADD PRIMARY KEY (`train_num`,`journey_date`);

-- --
-- -- Constraints for dumped tables
-- --

-- --
-- -- Constraints for table `passenger`
-- --
-- ALTER TABLE `passenger`
--   ADD CONSTRAINT `passenger_ibfk_1` FOREIGN KEY (`pnr`) REFERENCES `tickets` (`pnr`);

-- --
-- -- Constraints for table `tickets`
-- --
-- ALTER TABLE `tickets`
--   ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`train_num`,`journey_date`) REFERENCES `train` (`train_num`, `journey_date`);
-- COMMIT;

-- /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
-- /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
-- /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
