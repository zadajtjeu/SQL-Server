use master
go
if(exists(select * from sysdatabases where name='QLTV'))
	drop database QLTV
go

/* Cau 1 */
--create database
use master
go
create database QLTV
go

use QLTV
go

--create table
create table Sach(
	Masach nchar(10) not null primary key,
	Tensach nvarchar(50),
	sotrang int default 0 check(sotrang>0),
	SLTon int default 0 check(SLTon>0)
)

create table PM(
	MaPM nchar(10) not null primary key,
	NgayM date,
	HoTenDG nvarchar(50)
)

create table SachMuon(
	MaPM nchar(10) not null references PM(MaPM),
	Masach nchar(10) not null references Sach(Masach),
	songaymuon int default 0 check (songaymuon>0),
	constraint fk_SachMuon primary key(MaPM, Masach)
)
go

--insert data
insert into Sach values ('S1', N'Dế mèn phưu lưu ký', 64, 100),
						('S2', N'Cô gái đến từ hôm qua', 40, 50),
						('S3', N'Mắt biếc', 40, 50)
insert into PM values	('M1', '06/24/2020', N'Ngô Thanh Vân'),
						('M2', '06/15/2020', N'Ngô Kiến Huy')
insert into SachMuon values ('M1', 'S1', 7), ('M1', 'S2', 6),
							('M2', 'S1', 10), ('M2', 'S2', 5)
go

--test
select Tensach, HoTenDG, NgayM, songaymuon
from Sach inner join SachMuon on SachMuon.Masach=Sach.Masach
		  inner join PM on PM.MaPM=SachMuon.MaPM
go


/* Cau 2: view */
create view SachQuaHan as
select Tensach, HoTenDG, NgayM, songaymuon, DATEADD(day,songaymuon,NgayM) as NgayTra
from Sach inner join SachMuon on SachMuon.Masach=Sach.Masach
		  inner join PM on PM.MaPM=SachMuon.MaPM
where DATEADD(day,songaymuon,NgayM) < getdate() -- thêm vào số ngày mượn sẽ ra ngày trả
go

--test
select * from SachQuaHan
go





/*                              *
 *============ DE 12 ============*
 *                              */




/* Cau 3 */
create function SachMuonTren10Lan(@masach nchar(10))
returns @ds table(TenSach nvarchar(50))
as
begin
	insert into @ds
		select Tensach from Sach where MaSach in
			(select MaSach from SachMuon where MaSach=@masach 
			group by MaSach having COUNT(*)>10)
	return
end
go

--test
select * from dbo.SachMuonTren10Lan('S1')
go

/* Cau 4 */
create trigger trg_insertPM on PM for insert as
begin
	declare @date date = (select NgayM from inserted)
	if(DAY(@date) <> DAY(getdate())
		OR MONTH(@date) <> MONTH(getdate())
		OR YEAR(@date) <> YEAR(getdate()))
	begin
		raiserror(N'Ngày lập phiếu mượn phải là ngày hiện tại',16,1)
		rollback tran
		return
	end
end

go

--test
insert into PM values('M3', getdate(), N'Lâm Vỹ Dạ')
--lỗi
--insert into PM values('M4', '06/15/2020', N'Lâm Gia Khôi')

select * from PM

go




/*                              *
 *============ DE 13 ============*
 *                              */



/* Câu 3: Sách chưa được mượn */

create function SachMuonChuaDkMuon(@masach nchar(10))
returns nvarchar(50)
as
begin
	declare @tensach nvarchar(50)
	set @tensach = (select Tensach from Sach where MaSach=@masach AND
				Masach not in (select DISTINCT MaSach from SachMuon) )
	return @tensach
end
go

--test
select dbo.SachMuonChuaDkMuon('S3')
go


/* Câu 4 */

GO 
CREATE TRIGGER trg_insertSM
ON SachMuon
FOR INSERT 
AS
BEGIN 
	DECLARE @masach nchar(10) = (SELECT Masach FROM Inserted)
	DECLARE @mapm nchar(10) = (SELECT MaPM FROM Inserted)
	DECLARE @soluongt INT  = (SELECT SLTon FROM Sach WHERE Masach=@masach)
	IF(EXISTS(SELECT * FROM PM WHERE MaPM=@mapm))
	BEGIN
		IF (EXISTS(SELECT * FROM Sach WHERE Masach=@masach))
			UPDATE Sach
			SET SLTon=@soluongt-1
			WHERE Masach=@masach
		ELSE IF(NOT EXISTS(SELECT * FROM Sach WHERE Masach=@masach))
			BEGIN
				RAISERROR(N'Mã sách không tồn tại',16,1)
				ROLLBACK TRANSACTION
			END 
	END 
	ELSE IF(NOT EXISTS(SELECT * FROM PM WHERE MaPM=@mapm))
	BEGIN 
		PRINT N'mã không tồn tại'
		RAISERROR(N'mã phiếu mượn không tồn tại',16,1)
		ROLLBACK TRANSACTION
	END 
end
GO

--test
select * from Sach
select * from SachMuon
insert into SachMuon values ('M1','S3', 7)
select * from Sach
select * from SachMuon
go