CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(50),
    GPA FLOAT,
    Branch VARCHAR(10),
    Section CHAR(1)
);

INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');


CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(50),
    MaxSeats INT,
    RemainingSeats INT
);

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);


CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    PRIMARY KEY (StudentId, SubjectId)
);

INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5);


CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    PRIMARY KEY (SubjectId, StudentId)
);

CREATE TABLE UnallottedStudents (
    StudentId INT PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);


DELIMITER //
CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE currStudentId INT;
    DECLARE currGPA FLOAT;
    DECLARE currSubjectId VARCHAR(10);
    DECLARE currPreference INT;
    
    -- Cursor to fetch students sorted by GPA in descending order
    DECLARE student_cursor CURSOR FOR 
    SELECT StudentId, GPA FROM StudentDetails ORDER BY GPA DESC;
    
    -- Cursor to fetch student preferences
    DECLARE preference_cursor CURSOR FOR
    SELECT SubjectId, Preference FROM StudentPreference WHERE StudentId = currStudentId ORDER BY Preference ASC;
    
    -- Handlers for cursors
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- Open student cursor
    OPEN student_cursor;
    
    student_loop: LOOP
        FETCH student_cursor INTO currStudentId, currGPA;
        IF done THEN
            LEAVE student_loop;
        END IF;

        -- Reset the done flag for the inner loop
        SET done = 0;
        
        -- Open preference cursor for the current student
        OPEN preference_cursor;
        
        preference_loop: LOOP
            FETCH preference_cursor INTO currSubjectId, currPreference;
            IF done THEN
                LEAVE preference_loop;
            END IF;

            -- Check if there are remaining seats in the subject
            IF (SELECT RemainingSeats FROM SubjectDetails WHERE SubjectId = currSubjectId) > 0 THEN
                -- Allocate subject to student
                INSERT INTO Allotments (SubjectId, StudentId) VALUES (currSubjectId, currStudentId);
                
                -- Decrease the remaining seats count
                UPDATE SubjectDetails SET RemainingSeats = RemainingSeats - 1 WHERE SubjectId = currSubjectId;
                
                -- Leave the preference loop once a subject is allocated
                LEAVE preference_loop;
            END IF;
        END LOOP preference_loop;

        -- Close the preference cursor
        CLOSE preference_cursor;
        
        -- Check if the student was not allocated any subject
        IF done THEN
            INSERT INTO UnallottedStudents (StudentId) VALUES (currStudentId);
        END IF;
        
        -- Reset the done flag for the outer loop
        SET done = 0;
    END LOOP student_loop;

    -- Close the student cursor
    CLOSE student_cursor;
END //
DELIMITER ;

CALL AllocateSubjects();

DROP PROCEDURE IF EXISTS AllocateSubjects;

SELECT * FROM Allotments;
SELECT * FROM UnallottedStudents;

