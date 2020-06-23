use master
go
if(exists(select * from sysdatabases where name='QLBenhVien'))
	drop database QLBenhVien
go

/* Cau 1 */
-- create database
use master
go
create database QLBenhVien
go
use QLBenhVien
go

-- create table
create table BenhVien(
	MaBV nvarchar(10) not null primary key,
	TenBV nvarchar(50)
)
create table KhoaKham(
	MaKhoa nvarchar(10) not null primary key,
	TenKhoa nvarchar(50),
	SoBenhNhan int default 0,
	MaBV nvarchar(10) not null references BenhVien(MaBV)
)
create table BenhNhan(
	MaBN nvarchar(10) not null primary key,
	HoTen nvarchar(50),
	NgaySinh date,
	GioiTinh bit,
	SoNgayNV int default 0,
	MaKhoa nvarchar(10) not null references KhoaKham(MaKhoa)
)
go

--insert data
insert into BenhVien values('BV1',N'Bệnh viện Bạch Mai'),
							('BV2',N'Bệnh viện Nhiệt đới Trung Ương')
insert into KhoaKham values('K1', N'Khoa huyết học và truyền máu', 4, 'BV1'),
							('K2', N'Khoa bênh nhiệt đới', 3, 'BV2')
insert into BenhNhan values('BN1', N'Đàm Văn Sỏi', '12/01/1988', 0, 5, 'K1'),
							('BN2', N'Lê Thị Na', '11/22/1990', 1, 15, 'K2'),
							('BN3', N'Nguyễn Bá Quyền', '01/12/1995', 0, 6, 'K1'),
							('BN4', N'Hồ Trọng Thủy', '12/03/1997', 1, 10, 'K2'),
							('BN5', N'Ngô Thị Lạc', '11/03/1987', 1, 2, 'K1'),
							('BN6', N'Cù Trọng Xoay', '11/03/1992', 0, 20, 'K1'),
							('BN7', N'Trần Thị Hảo', '10/05/1999', 1, 12, 'K2')
go

--test
select * from BenhVien
select * from KhoaKham
select * from BenhNhan
go






/*                              *
 *============ DE 4 ============*
 *                              */


/* Cau 2 */
create view thongkeBN as
select KhoaKham.MaKhoa, TenKhoa, COUNT(*) as N'Số người' from KhoaKham
inner join BenhNhan on BenhNhan.MaKhoa=KhoaKham.MaKhoa
where GioiTinh=1
group by KhoaKham.MaKhoa, TenKhoa

go

--test
select * from thongkeBN
go

/* Cau 3 */
create proc proc_tongtienkhambenh(@makhoa nvarchar(10)) as
begin
	return (select sum(SoNgayNV*80000) from BenhNhan where MaKhoa=@makhoa)
end

go

--test
declare @tongtien money
declare @khoa nvarchar(10)
set @khoa = 'K1'
exec @tongtien = proc_tongtienkhambenh @makhoa=@khoa
print N'Tổng tiền chữa bệnh của khoa có mã '+@khoa+' là: '+convert(nvarchar(20), @tongtien)

go

/* Cau 4 */
create trigger trg_insertBN on BenhNhan for insert as
begin
	declare @makhoa nvarchar(10)
	declare @soBN int

	select @makhoa=MaKhoa from inserted
	select @soBN=SoBenhNhan from KhoaKham where MaKhoa=@makhoa

	if(@soBN > 100)
	begin
		raiserror(N'Một khoa không thể điều trị cho hơn 100 bệnh nhân',16,1)
		rollback tran
	end
	else
	begin
		update KhoaKham set SoBenhNhan+=1 from KhoaKham inner join inserted on inserted.MaKhoa=KhoaKham.MaKhoa where KhoaKham.MaKhoa=inserted.MaKhoa
	end
end

go

--test
select * from BenhNhan
select * from KhoaKham
insert into BenhNhan values('BN8', N'Cao Bá Kỳ', '01/12/1995', 1, 6, 'K1')
select * from BenhNhan
select * from KhoaKham
go






/*                              *
 *============ DE 9 ============*
 *                              */




/* Câu 2: */
create view maxtuoiBN as
select MaBN, HoTen, YEAR(getdate())-YEAR(NgaySinh) as N'Tuổi' from BenhNhan
where YEAR(getdate())-YEAR(NgaySinh) = (select MAX(YEAR(getdate())-YEAR(NgaySinh)) from BenhNhan)
go

--test
select * from maxtuoiBN
go


/* Câu 3: */

create function findbyMaBN(@mabn nvarchar(10))
returns @inforBN table(MaBN nvarchar(10), HoTen nvarchar(50), NgaySinh date,
					   GioiTinh nvarchar(5), TenKhoa nvarchar(50),TenBV nvarchar(50) )
as
begin
	insert into @inforBN
		select BenhNhan.MaBN, HoTen, NgaySinh,
			case GioiTinh when 0 then N'Nữ' when 1 then N'Nam' end as GioiTinh,
			TenKhoa, TenBV
		from BenhNhan inner join KhoaKham on KhoaKham.MaKhoa=BenhNhan.MaKhoa
					  inner join BenhVien on BenhVien.MaBV=KhoaKham.MaBV
		where MaBN=@mabn
	return
end
go

--test 
select * from findbyMaBN('BN1')
go


/* Câu 4 */
-- Câu này giống câu 4 đề 4
/*
create trigger trg_insertBN on BenhNhan for insert as
begin
	declare @makhoa nvarchar(10)
	declare @soBN int

	select @makhoa=MaKhoa from inserted
	select @soBN=SoBenhNhan from KhoaKham where MaKhoa=@makhoa

	if(@soBN > 100)
	begin
		raiserror(N'Một khoa không thể điều trị cho hơn 100 bệnh nhân',16,1)
		rollback tran
	end
	else
	begin
		update KhoaKham set SoBenhNhan+=1 from KhoaKham inner join inserted on inserted.MaKhoa=KhoaKham.MaKhoa where KhoaKham.MaKhoa=inserted.MaKhoa
	end
end

go

--test
select * from BenhNhan
select * from KhoaKham
insert into BenhNhan values('BN8', N'Cao Bá Kỳ', '01/12/1995', 1, 6, 'K1')
select * from BenhNhan
select * from KhoaKham
go
*/