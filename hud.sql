CREATE TABLE IF NOT EXISTS `nexus_mileage` (
    `plate` VARCHAR(20) NOT NULL,
    `mileage` DOUBLE DEFAULT 0.0,
    PRIMARY KEY (`plate`)
);