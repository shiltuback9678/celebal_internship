CREATE TABLE SubjectAllotments (
    StudentId VARCHAR(50),
    SubjectId VARCHAR(50),
    Is_Valid BIT
);

INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
VALUES 
('159103036', 'PO1491', 1),
('159103036', 'PO1492', 0),
('159103036', 'PO1493', 0),
('159103036', 'PO1494', 0),
('159103036', 'PO1495', 0);


CREATE TABLE SubjectRequest (
    StudentId VARCHAR(50),
    SubjectId VARCHAR(50)
);

INSERT INTO SubjectRequest (StudentId, SubjectId)
VALUES 
('159103036', 'PO1496');




DELIMITER //

CREATE PROCEDURE UpdateSubjectAllotment()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE StudentId VARCHAR(50);
    DECLARE RequestedSubjectId VARCHAR(50);
    DECLARE CurrentSubjectId VARCHAR(50);

    DECLARE request_cursor CURSOR FOR
    SELECT StudentId, SubjectId FROM SubjectRequest;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN request_cursor;

    read_loop: LOOP
        FETCH request_cursor INTO StudentId, RequestedSubjectId;
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF EXISTS (SELECT 1 FROM SubjectAllotments WHERE StudentId = StudentId) THEN

            SELECT SubjectId INTO CurrentSubjectId
            FROM SubjectAllotments
            WHERE StudentId = StudentId AND Is_Valid = 1
            LIMIT 1;

            IF CurrentSubjectId != RequestedSubjectId THEN

                UPDATE SubjectAllotments
                SET Is_Valid = 0
                WHERE StudentId = StudentId AND Is_Valid = 1;

                INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
                VALUES (StudentId, RequestedSubjectId, 1);
            END IF;
        ELSE
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
            VALUES (StudentId, RequestedSubjectId, 1);
        END IF;
    END LOOP;

    CLOSE request_cursor;

    DELETE FROM SubjectRequest;
END //

DELIMITER ;

-- To disable safe mode in MySQL
SET SQL_SAFE_UPDATES = 0;



CALL UpdateSubjectAllotment();

SELECT * FROM SubjectAllotments;



