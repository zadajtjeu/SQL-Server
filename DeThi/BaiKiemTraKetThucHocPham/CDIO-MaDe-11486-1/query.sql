use master
go
if(exists(select * from sysdatabases where name='QLSinhVien'))
	drop database QLSinhVien
go

/* Cau 1 */
-- create database
use master
create database QLSinhVien
go
use QLSinhVien
go

--create table
create table Khoa(
	MaKhoa nvarchar(10) not null primary key,
	TenKhoa nvarchar(50),
	NgayThanhLap date
)
create table Lop(
	MaLop nvarchar(10) not null primary key,
	TenLop nvarchar(50),
	SiSo int default 0 check(SiSo >= 0),
	MaKhoa nvarchar(10) not null references Khoa(MaKhoa)
)
create table SinhVien(
	MaSV nvarchar(10) not null primary key,
	HoTen nvarchar(50),
	NgaySinh date,
	MaLop nvarchar(10) not null references Lop(MaLop)
)

go

-- insert data
insert into Khoa values('K1', N'Công Nghệ Thông Tin', '12/12/1999'),
						('K2', N'Kế toán', '12/12/1999'),
						('K3', N'Ngoại Ngữ', '12/12/1999')
insert into Lop values('KTPM', N'Kỹ Thuật Phần Mềm', 2, 'K1'),
					  ('KT1', N'Kế toán 1', 2, 'K2'),
					  ('N1', N'Tiếng Nhật cơ bản', 1, 'K3')
insert into SinhVien values('SV1', N'Lê Lý Thị Lan', '01/01/2000', 'KT1'),
							('SV2', N'Nguyễn Bá Nguyên', '10/02/2000', 'KTPM'),
							('SV3', N'Cao Đại La', '10/14/2000', 'KT1'),
							('SV4', N'Ngô Văn Sang', '08/09/2000', 'N1'),
							('SV5', N'Đào Thiên Ý', '07/16/2000', 'KTPM')
go
--test
select * from Khoa
select * from Lop
select * from SinhVien
go


/* Cau 2 */
create function fn_dssv(@tenkhoa nvarchar(50),@tenlop nvarchar(50))
returns @dssv table(MaSV nvarchar(10), HoTen nvarchar(50), Tuoi int)
as
begin
	insert into @dssv
		select MaSV, HoTen, YEAR(getdate())-YEAR(NgaySinh) as Tuoi from SinhVien
		where MaLop in (select MaLop from Lop where TenLop=@tenlop and
						MaKhoa in (select MaKhoa from Khoa where TenKhoa=@tenkhoa)
						)
	return
end

go

--test
select * from dbo.fn_dssv(N'Công Nghệ Thông Tin',N'Kỹ Thuật Phần Mềm')

go

/* Cau 3 */
create proc prod_dsLop(@tenkhoa nvarchar(50), @x int) as
begin
	if(not exists(select * from Lop where SiSo > @x AND MaKhoa in (select MaKhoa from Khoa where TenKhoa=@tenkhoa)))
	begin
		print N'Không tìm thấy lớp thỏa mãn yêu cầu'
	end
	else
		select MaLop, TenLop, SiSo from Lop where SiSo > @x AND MaKhoa in (select MaKhoa from Khoa where TenKhoa=@tenkhoa)
end
go

--test
exec prod_dsLop N'Công Nghệ Thông Tin', 1
--lỗi
exec prod_dsLop N'Kế toán', 2

go


/* Cau 4 */
create trigger trg_deleteSV on SinhVien for delete as
begin
	declare @masv nvarchar(10) = (select MaSV from deleted)
	declare @malop nvarchar(10) = (select MaLop from deleted)
	if(not exists(select * from deleted where MaSV=@masv))
	begin
		raiserror(N'Sinh viên không tồn tại!',16,1)
		rollback tran
	end
	else
		update Lop set SiSo-=1 from Lop where MaLop=@malop
end
go

--test
delete SinhVien where MaSV='SV1'
--loi
delete SinhVien where MaSV='SV11'
go