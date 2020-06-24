use master
go
if(exists(select * from sysdatabases where name='MarkManagement'))
	drop database MarkManagement
go

/* A. Create Database */

create database MarkManagement

go
use MarkManagement
go
/* B. Create Table */

create table Students(
	StudentID nvarchar(12) not null primary key,
	StudentName nvarchar(25) not null,
	DateofBirth datetime not null,
	Email nvarchar(40),
	Phone nvarchar(12),
	Class nvarchar(10)
)

create table Subjects(
	SubjectID nvarchar(10) not null primary key,
	SubjectName nvarchar(25) not null
)

create table Mark(
	ID int not null identity,
	StudentID nvarchar(12) not null,
	SubjectID nvarchar(10) not null,
	Theory tinyint,
	Practical tinyint,
	Date datetime,
	constraint Pri_Key primary key(ID, StudentID, SubjectID),
	constraint Mark_Stu foreign key(StudentID) references Students(StudentID),
	constraint Mark_Sub foreign key(SubjectID) references Subjects(SubjectID)
)

go


/* C. Insert Data */

insert into Students 
values('AV0807005',N'Mail Trung Hiếu','11/10/1989','trunghieu@yahoo.com','0904115116','AV1'),
		('AV0807006',N'Nguyễn Quý Hùng','2/12/1988','quyhung@yahoo.com','0955667787','AV2'),
		('AV0807007',N'Đỗ Đắc Huỳnh','2/1/1990','dachuynh@yahoo.com','0988574747','AV2'),
		('AV0807009',N'An Đăng Khê','6/3/1986','dangkhue@yahoo.com','0986757463','AV1'),
		('AV0807010',N'Nguyễn T. Tuyết Lan','12/7/1989','tuyetlan@gmail.com','0983310342','AV2'),
		('AV0807011',N'Đinh Phụng Long','2/12/1990','phunglong@yahoo.com','','AV1'),
		('AV0807012',N'Nguyễn Tuấn Nam','2/3/1990','tuannam@yahoo.com','','AV1')

insert into Subjects
values('S001','SQL'), ('S002','Java Simplefield'), ('S003', 'Active Server Page')

insert into Mark
values('AV0807005','S001',8,25,'6/5/2008'),
 ('AV0807006','S002',16,30,'6/5/2008'),
 ('AV0807007','S001',10,25,'6/5/2008'),
 ('AV0807009','S003',7,13,'6/5/2008'),
 ('AV0807010','S003',9,16,'6/5/2008'),
 ('AV0807011','S002',8,30,'6/5/2008'),
 ('AV0807012','S001',7,31,'6/5/2008'),
 ('AV0807005','S002',12,11,'6/6/2008'),
 ('AV0807009','S003',11,20,'6/6/2008'),
 ('AV0807010','S001',7,6,'6/6/2008')

 go

 -- test
 select * from Students
 select * from Subjects
 select * from Mark
 go
 /* D. Execute Query */



 -- 1. Show Student
 select * from Students
 go

 -- 2. Show student at AV1
 select * from Students where Class='AV1'
 go

 -- 3. Sử dụng lệnh UPDATE để chuyển sinh viên có mã AV0807012 sang lớp AV2
 update Students set Class='AV2' where StudentID='AV0807012'
 go
 --test
select * from Students
go

-- 4. Tính tổng số sinh viên của từng lớp
select Class, COUNT(*) as 'Total Student' from Students group by Class
go

-- 5. Hiển thị danh sách sinh viên lớp AV2 được sắp xếp tăng dần theo StudentName
select * from Students where Class='AV2' order by StudentName ASC
go

-- 6. Hiển thị danh sách sinh viên không đạt lý thuyết môn S001 (theory <10) thi ngày 6/5/2008
select * from Students where StudentID in (select StudentID from Mark where SubjectID='S001' and Theory<10 and Date='6/5/2008')

-- Cach 2
select Students.StudentID, Students.StudentName, Mark.SubjectID, Mark.Theory, Mark.Date
from Students inner join Mark on Students.StudentID = Mark.StudentID
where SubjectID='S001' and Theory<10 and Date='6/5/2008'

go

-- 7. Hiển thị tổng số sinh viên không đạt lý thuyết môn S001. (theory <10)
select COUNT(*) as 'Students faile S001' from Mark where SubjectID='S001' and Theory<10
go

-- 8. Hiển thị Danh sách sinh viên học lớp AV1 và sinh sau ngày 1/1/1980
select * from Students where Class='AV1' and DateofBirth>'1/1/1980'
go

-- 9. Xoá sinh viên có mã AV0807011
delete from Mark where StudentID='AV0807011'
delete from Students where StudentID='AV0807011'
go
--test
select * from Students
select * from Mark
go

-- 10. Hiển thị danh sách sinh viên dự thi môn có mã S001 ngày 6/5/2008
--bao gồm các trường sau: StudentID, StudentName, SubjectName, Theory, Practical, Date
select Students.StudentID, StudentName, SubjectName, Theory, Practical, Date
from Students inner join Mark on Students.StudentID = Mark.StudentID
			  inner join Subjects on Mark.SubjectID = Subjects.SubjectID
where Mark.SubjectID = 'S001' and Mark.Date = '6/5/2008'
go

