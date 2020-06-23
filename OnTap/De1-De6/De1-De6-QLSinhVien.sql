use master
go
if(exists(select * from sysdatabases where name='QLSinhVien'))
	drop database QLSinhVien
go

/* Cau 1 */
-- Create database
use master
go
create database QLSinhVien
go

use QLSinhVien
go
-- create table
create table Khoa(
	MaKhoa nvarchar(10) not null primary key,
	TenKhoa nvarchar(30) not null
)
create table Lop(
	MaLop nvarchar(10) not null primary key,
	TenLop nvarchar(30) not null,
	SiSo int default 0,
	MaKhoa nvarchar(10) not null,
	constraint Lop_Khoa foreign key(MaKhoa) references Khoa(MaKhoa)
)
create table SinhVien(
	MaSV nvarchar(10) not null primary key,
	HoTen nvarchar(30) not null,
	NgaySinh date default '1970-01-01',
	GioiTinh bit default 0,
	MaLop nvarchar(10),
	constraint SinhVien_Lop foreign key(MaLop) references Lop(MaLop)
)

go

-- insert data

insert into Khoa values('CNTT', N'Công Nghệ Thông Tin'), ('OTO', N'Ô Tô')
insert into Lop values('KTPM', N'Kỹ Thuật Phần Mềm', 4, 'CNTT'),
						('OTO1', N'Ô Tô 1', 3, 'OTO')
insert into SinhVien values('SV01', N'Phùng Thế An', '10-22-1996', 0, 'KTPM'),
							('SV02', N'Đào Bá Đạt', '02-02-1997', 0, 'KTPM'),
							('SV03', N'Nghiêm Xuân Nghĩa', '05-12-1996', 0, 'OTO1'),
							('SV04', N'Hoàng Công Lý', '12-30-1996', 0, 'OTO1'),
							('SV05', N'Thế Văn Tài', '01-14-1998', 0, 'KTPM'),
							('SV06', N'Lưu Thị Mỹ Hạnh', '11-01-1995', 1, 'OTO1'),
							('SV07', N'Nguyễn Minh Trang', '06-21-1996', 1, 'KTPM')
go
--test
select * from Khoa
select * from Lop
select * from SinhVien
go





/*                              *
 *============ DE 1 ============*
 *                              */





/* Cau 2: Create View */
create view CountClass as
select TenKhoa, COUNT(*) as N'Số Lớp'
from Khoa inner join Lop on Khoa.MaKhoa = Lop.MaKhoa
group by TenKhoa

go
-- test
select * from CountClass
go
/* Cau 3: Function */
create function fn_InfoSinhVien (@MaKhoa nvarchar(10))
returns @InfoSV table (MaSV nvarchar(10), HoTen nvarchar(30), NgaySinh date, GioiTinh nvarchar(3), TenLop nvarchar(30), TenKhoa nvarchar(30))
as
begin
	insert into @InfoSV 
		select MaSV, HoTen, NgaySinh, 
			case GioiTinh 
				when 0 then N'Nam' else N'Nữ' end
			, TenLop, TenKhoa
		from SinhVien inner join Lop on SinhVien.MaLop = Lop.MaLop
					  inner join Khoa on Lop.MaKhoa = Khoa.MaKhoa
		where Khoa.MaKhoa = @MaKhoa
	return
end
go

--test
select * from fn_InfoSinhVien('CNTT')
go

/* Cau4: Trigger */

create trigger trg_SinhVienInsert on SinhVien for insert as
begin
	declare @malop nvarchar(10)
	declare @SoLuongSV int

	select @SoLuongSV = SiSo, @malop = Lop.MaLop from Lop inner join inserted on Lop.MaLop = inserted.MaLop
	if(@SoLuongSV > 80)
		begin
			raiserror('Lop da day',16,1)
			rollback tran
			return
		end
	update Lop Set SiSo += 1
	from Lop 
	Where MaLop = @malop
end
go
-- test

insert into SinhVien values('SV08', N'Nguyễn Linh Chi', '10-22-1996', 1, 'OTO1')
go
select * from SinhVien
select * from lop




/*                              *
 *============ DE 6 ============*
 *                              */



/* Cau 2: Create View */
go
create view mintuoi_sv as
select SinhVien.MaSV, HoTen, YEAR(getdate())-YEAR(NgaySinh) as N'Tuổi' from SinhVien
where YEAR(getdate())-YEAR(NgaySinh) = (select MIN(YEAR(getdate())-YEAR(NgaySinh)) from SinhVien)

go

--test
select * from mintuoi_sv
go

/* Cau 3: Store procedure */
create proc TimKiemSV(@TuTuoi int, @DenTuoi int) as
begin
	select SinhVien.MaSV, HoTen, NgaySinh, TenLop, TenKhoa, YEAR(getdate())-YEAR(NgaySinh) as Tuoi
	from SinhVien inner join Lop on Lop.MaLop=SinhVien.MaLop
				  inner join Khoa on Khoa.MaKhoa=Lop.MaKhoa
	where YEAR(getdate())-YEAR(NgaySinh) between @TuTuoi and @DenTuoi
end
go

--test
exec TimKiemSV 20, 25
go


/* Câu 4: trigger for insert */
/* Câu 4 đề 6 giống câu 4 đề 1*/
/*
create trigger trg_SinhVienInsert on SinhVien for insert as
begin
	declare @malop nvarchar(10)
	declare @SoLuongSV int

	select @SoLuongSV = SiSo, @malop = Lop.MaLop from Lop inner join inserted on Lop.MaLop = inserted.MaLop
	if(@SoLuongSV > 80)
		begin
			raiserror('Lop da day',16,1)
			rollback tran
			return
		end
	update Lop Set SiSo += 1
	from Lop 
	Where MaLop = @malop
end
go
-- test

insert into SinhVien values('SV08', N'Nguyễn Linh Chi', '10-22-1996', 1, 'OTO1')
go
select * from SinhVien
select * from lop
*/