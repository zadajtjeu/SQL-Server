use master
go

if(exists(select * from sysdatabases where name='QLHANG'))
	drop database QLHANG
go

/* Cau 1 */
use master
go

-- create database
create database QLHANG
go

use QLHANG
go

--create table

create table VatTu(
	MaVT nvarchar(10) not null primary key,
	TenVT nvarchar(30) not null,
	DVTinh nvarchar(30),
	SLCon int default 0
)

create table HDBan(
	MaHD nvarchar(10) not null primary key,
	NgayXuat date default GETDATE(),
	HoTenKhach nvarchar(30)
)

create table HangXuat(
	MaHD nvarchar(10) not null,
	MaVT nvarchar(10) not null,
	DonGia money default 0,
	SLBan int default 0,
	constraint HangXuat_VatTu foreign key(MaVT) references VatTu(MaVT),
	constraint HangXuat_HDBan foreign key(MaHD) references HDBan(MaHD),
	constraint FK_HangXuat primary key(MaHD, MaVT)
)

go

--insert data
insert into VatTu values('VT001', N'Xi măng sông Vân', N'Bao', 1000),
						('VT002', N'Ống nhựa tiền phong', N'Mét', 1000)
insert into HDBan values('HD001', GETDATE(), N'Nguyễn Đức Phong'),
						('HD002', GETDATE(), N'Trần Thanh Phong')
insert into HangXuat values('HD001', 'VT001', 120000, 10),
							('HD001', 'VT002', 5200, 550),
							('HD002', 'VT001', 130000, 50),
							('HD002', 'VT002', 5500, 950)
go

-- test
select * from VatTu
select * from HDBan
select * from HangXuat
go




/* Cau 2 */
create view TongTienHoaDon as
select MaHD, SUM(DonGia*SLBan) as TongTien
from HangXuat group by MaHD

go

select MaHD, TongTien as N'Tổng Tiền' from TongTienHoaDon
where TongTien = (select MAX(TongTien) from TongTienHoaDon)

go

/* Cau 3 */
create function InfoHD(@MaHD nvarchar(10))
returns @Result table(MaHD nvarchar(10), NgayXuat date, MaVT nvarchar(10), DonGia money, SLBan int, NgayThu nvarchar(20))
begin
	insert into @Result
	select HDBan.MaHD, NgayXuat, MaVT, DonGia, SLBan, 
		case DATEPART(dw, NgayXuat) 
			when 1 then N'Chủ Nhật'
			when 2 then N'Thứ Hai'
			when 3 then N'Thứ Ba'
			when 4 then N'Thứ Tư'
			when 5 then N'Thứ Năm'
			when 6 then N'Thứ Sáu'
			when 7 then N'Thứ Bảy'
			else 'Null'
		end
	from HDBan inner join HangXuat on HDBan.MaHD = HangXuat.MaHD

	return
end

go
-- test
select * from InfoHD('HD001')
go

/* Cau 4 */
create proc TongTientheoDY(@Month int, @Year int, @TongTien money output) as
begin
	set @TongTien = (select SUM(DonGia*SLBan) from HangXuat
					where MaHD in (select MaHD from HDBan where MONTH(NgayXuat) = @Month and Year(NgayXuat) = @Year)
					)

	return @TongTien
end

go
--test
declare @TongTien money
exec TongTientheoDY 05, 2020, @TongTien output
select @TongTien
go
